import { readFileSync } from 'node:fs';
import { test, before, beforeEach, after } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, deleteDoc, collection, getDocs } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-astra',firestore:{host:'127.0.0.1',port:8080,rules:readFileSync(new URL('../firestore.rules', import.meta.url),'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db,'users/patient'),{name:'Test',age:28,sex:'Unspecified',conditions:[]});
    await setDoc(doc(db,'users/patient/readings/one'),{id:'one',at:'2026-09-26T00:00:00.000Z',values:{spo2:98},source:'manual',deviceId:null,schemaVersion:1});
    await setDoc(doc(db,'users/patient/careTeam/doctor'),{grantedAt:'test'});
    await setDoc(doc(db,'doctorAccess/doctor/patients/patient'),{name:'Test'});
  });
});
after(async () => {await env?.cleanup();});

test('owner can read; strangers and unauthenticated clients cannot', async()=>{
  await assertSucceeds(getDoc(doc(env.authenticatedContext('patient').firestore(),'users/patient')));
  await assertFails(getDoc(doc(env.authenticatedContext('stranger').firestore(),'users/patient')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'users/patient')));
});
test('doctor requires BOTH role and grant, and loses access on revocation', async()=>{
  const doctor = env.authenticatedContext('doctor',{role:'doctor'}).firestore();
  await assertSucceeds(getDoc(doc(doctor,'users/patient/readings/one')));
  await assertSucceeds(getDocs(collection(doctor,'doctorAccess/doctor/patients')));
  await assertFails(getDoc(doc(env.authenticatedContext('doctor').firestore(),'users/patient')));
  await assertFails(getDoc(doc(env.authenticatedContext('other-doctor',{role:'doctor'}).firestore(),'users/patient')));
  await env.withSecurityRulesDisabled(c=>deleteDoc(doc(c.firestore(),'users/patient/careTeam/doctor')));
  await assertFails(getDoc(doc(doctor,'users/patient/readings/one')));
});
test('clients cannot assign roles, forge assessments, or grant themselves access',async()=>{
  const db=env.authenticatedContext('patient').firestore();
  await assertFails(setDoc(doc(db,'users/patient'),{name:'Test',age:28,sex:'Male',conditions:[],role:'doctor'}));
  await assertFails(setDoc(doc(db,'users/patient/assessments/forged'),{isDemo:false}));
  await assertFails(setDoc(doc(db,'users/patient/careTeam/stranger'),{granted:true}));
  await assertFails(setDoc(doc(db,'doctorAccess/patient/patients/stranger'),{name:'Stolen'}));
});
test('only valid owner measurements may be created; records are immutable',async()=>{
  const db=env.authenticatedContext('patient').firestore();
  const valid={id:'two',at:'2026-09-26T00:00:00.000Z',values:{spo2:98},source:'manual',deviceId:null,schemaVersion:1};
  await assertSucceeds(setDoc(doc(db,'users/patient/readings/two'),valid));
  await assertFails(setDoc(doc(db,'users/patient/readings/two'),{...valid,values:{spo2:99}}));
  await assertFails(setDoc(doc(db,'users/patient/readings/bad'),{...valid,id:'bad',values:{spo2:105}}));
  await assertFails(setDoc(doc(db,'users/patient/readings/empty'),{...valid,id:'empty',values:{}}));
  await assertFails(setDoc(doc(env.authenticatedContext('doctor',{role:'doctor'}).firestore(),'users/patient/readings/three'),{...valid,id:'three'}));
});
