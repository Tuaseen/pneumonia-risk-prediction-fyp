"""Authenticated Firebase backend for the Astra research prototype."""
from firebase_admin import initialize_app, auth, firestore
from firebase_functions import https_fn, options
from prediction import demo_assessment

initialize_app()
options.set_global_options(region='us-central1', max_instances=5)


def caller(request):
    if request.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, 'Sign in first.')
    return request.auth.uid


@https_fn.on_call()
def assess_demo(request: https_fn.CallableRequest):
    uid = caller(request)
    db = firestore.client()
    user = db.collection('users').document(uid)
    profile = user.get().to_dict() or {}
    if not profile.get('name') or profile.get('age') is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.FAILED_PRECONDITION, 'Complete your profile first.')
    readings = [r.to_dict() for r in user.collection('readings').order_by('at', direction=firestore.Query.DESCENDING).limit(500).stream()]
    ref = user.collection('assessments').document()
    try:
        result = demo_assessment(request.data, readings, assessment_id=ref.id)
    except ValueError as error:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, str(error)) from error
    # Identity always comes from the validated token, never a client-supplied user ID.
    result['profileSnapshot'] = profile
    ref.set(result)
    return result


@https_fn.on_call()
def set_doctor_access(request: https_fn.CallableRequest):
    uid = caller(request)
    data = request.data
    if not isinstance(data, dict):
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'Expected an object.')
    doctor_uid = data.get('doctorUid')
    grant = data.get('grant')
    if not isinstance(doctor_uid, str) or not doctor_uid or '/' in doctor_uid or len(doctor_uid) > 128 or type(grant) is not bool or doctor_uid == uid:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'Supply a valid doctor account ID and grant flag.')
    if grant:
        try:
            doctor = auth.get_user(doctor_uid)
        except auth.UserNotFoundError as error:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.NOT_FOUND, 'Doctor account not found.') from error
        if doctor.disabled or (doctor.custom_claims or {}).get('role') != 'doctor':
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.PERMISSION_DENIED, 'This is not an enabled doctor account.')
    db = firestore.client()
    patient = db.collection('users').document(uid)
    grant_ref = patient.collection('careTeam').document(doctor_uid)
    index_ref = db.collection('doctorAccess').document(doctor_uid).collection('patients').document(uid)
    batch = db.batch()
    if grant:
        profile = patient.get().to_dict() or {}
        batch.set(grant_ref, {'grantedAt': firestore.SERVER_TIMESTAMP})
        batch.set(index_ref, {'name': profile.get('name', 'Patient'), 'grantedAt': firestore.SERVER_TIMESTAMP})
    else:
        batch.delete(grant_ref)
        batch.delete(index_ref)
    batch.commit()
    return {'granted': grant}
