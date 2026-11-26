import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import 'design.dart';

class DoctorScreen extends StatelessWidget {
  final AppStore store;
  const DoctorScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.selectedPatient != null) {
      return _PatientDetailView(store: store);
    }

    final patients = store.patients;
    final criticalCount = patients.where((p) => p['hasAlert'] == true).length;
    final highRiskCount = patients.where((p) => p['band'] == RiskBand.high).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.doctorName} · ${store.doctorSpecialty}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clinical Workspace',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Monitor patient rosters, review clinical telemetry, and track pneumonia risk alerts.',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: destructiveRed,
                side: const BorderSide(color: alertRedBorder),
              ),
              onPressed: () => store.signOut(),
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text('Sign Out'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Summary Statistics Banner
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(
                children: [
                  _MetricCard(
                    title: 'Total Patients',
                    value: patients.length.toString(),
                    color: primaryBlue,
                    icon: Icons.people_outline,
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'Critical Alerts',
                    value: criticalCount.toString(),
                    color: destructiveRed,
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'High Risk Flagged',
                    value: highRiskCount.toString(),
                    color: const Color(0xFFDC2626),
                    icon: Icons.medical_services_outlined,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Patients',
                    value: patients.length.toString(),
                    color: primaryBlue,
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    title: 'Critical Alerts',
                    value: criticalCount.toString(),
                    color: destructiveRed,
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    title: 'High Risk Flagged',
                    value: highRiskCount.toString(),
                    color: const Color(0xFFDC2626),
                    icon: Icons.medical_services_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        const Text(
          'Monitored Patient Roster',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        if (patients.isEmpty)
          CardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.link_off_rounded, color: primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No Patients Linked Yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'To protect patient privacy, your clinical workspace only displays patients who have explicitly linked your account.\n\n'
                  'Your Doctor Email: ${store.doctorEmail.isNotEmpty ? store.doctorEmail : (store.uid)}\n\n'
                  'Provide this email to your patients so they can link you under "Profile -> Linked Physicians & Care Team".',
                  style: const TextStyle(fontSize: 13, height: 1.5, color: textMuted),
                ),
              ],
            ),
          )
        else
          ...patients.map((p) {
            final band = p['band'] as RiskBand? ?? RiskBand.low;
            final hasAlert = p['hasAlert'] == true;
            final lastChecked = p['lastChecked'] as DateTime? ?? DateTime.now();
            final patientName = (p['name'] as String).trim();
            final initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardPanel(
                onTap: () => store.openPatient(p['id']),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryBlueLight,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                p['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${p['age']}y · ${p['sex']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: band.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      band.label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: band.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Checked ${formatDate(lastChecked)}',
                                style: const TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasAlert)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: alertRedBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: alertRedBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 14, color: destructiveRed),
                            SizedBox(width: 4),
                            Text(
                              'Critical',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: destructiveRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Icon(Icons.chevron_right, color: textMuted),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Patient Detail Drilldown View ---
class _PatientDetailView extends StatelessWidget {
  final AppStore store;
  const _PatientDetailView({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.patientProfile == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: store.closePatientDetail,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to patient list'),
          ),
          const SizedBox(height: 60),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(height: 16),
                Text(
                  'Loading patient clinical record and assessments...',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final profile = store.patientProfile!;
    final assessment = store.patientAssessments.isNotEmpty
        ? store.patientAssessments.first
        : store.latestAssessment;
    final r = store.patientReadings.isNotEmpty ? store.patientReadings.first : null;
    final labs = store.patientLabs ?? store.labs;

    final displayName = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : 'Patient #${profile.patientId.isNotEmpty ? (profile.patientId.length > 6 ? profile.patientId.substring(0, 6) : profile.patientId) : 'Record'}';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: store.closePatientDetail,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to patient list'),
            ),
            if (assessment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: assessment.band.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(assessment.band.icon, size: 16, color: assessment.band.color),
                    const SizedBox(width: 6),
                    Text(
                      assessment.band.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: assessment.band.textColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // 1. Patient Identification Header
        CardPanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primaryBlueLight,
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.age != null ? '${profile.age} years old' : 'Age not recorded'} · ${profile.sex} · Patient ID: ${profile.patientId}',
                      style: const TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Physician Diagnostic Severity Assessment Card (Replaces generic consumer card)
        _DoctorDiagnosticSummaryCard(
          assessment: assessment,
          profile: profile,
          onOpenReport: () {
            if (assessment != null) {
              showDialog(
                context: context,
                builder: (_) => PatientReportDialog(
                  assessment: assessment,
                  profile: profile,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 20),

        // 3. Immediate Physician Action Checklist (Option 1: Interactive Tappable Checklist)
        _PhysicianActionChecklist(
          currentSpo2: r?.spo2,
          hasCopd: profile.conditions['copd'] == 1,
          checkedOrders: store.getDoctorChecklist(profile.patientId),
          onToggle: (index) => store.toggleDoctorChecklist(profile.patientId, index),
        ),
        const SizedBox(height: 20),

        // 4. Patient-Reported Subjective Symptoms Card
        _PatientReportedSymptomsCard(
          symptomsMap: assessment?.symptoms,
        ),
        const SizedBox(height: 20),

        // 5. Hemodynamic & Physiological Severity Indices (Shock Index, NEWS2 points)
        _AdvancedHemodynamicIndicesCard(
          reading: r,
        ),
        const SizedBox(height: 24),

        // 6. Latest Physiological Vitals & Labs
        const Text(
          'Latest Physiological Vitals',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: VitalTile(
                vitalKey: 'heart_rate',
                value: r?.heartRate,
                at: r?.at,
              ),
            ),
            SizedBox(
              width: 260,
              child: VitalTile(
                vitalKey: 'respiratory_rate',
                value: r?.respiratoryRate,
                at: r?.at,
              ),
            ),
            SizedBox(
              width: 260,
              child: VitalTile(
                vitalKey: 'sbp',
                value: r?.sbp,
                at: r?.at,
              ),
            ),
            SizedBox(
              width: 260,
              child: VitalTile(
                vitalKey: 'spo2',
                value: r?.spo2,
                at: r?.at,
              ),
            ),
            SizedBox(
              width: 260,
              child: VitalTile(
                vitalKey: 'temperature',
                value: r?.temperature,
                at: r?.at,
              ),
            ),
            SizedBox(
              width: 260,
              child: LabsTile(labs: labs),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 7. Multi-Day Longitudinal Telemetry History Table
        _LongitudinalTrajectoryTable(
          readings: store.patientReadings,
          assessments: store.patientAssessments,
        ),
        const SizedBox(height: 24),

        // 8. Two-Stage AI Diagnostic Explainability Card
        _ModelExplainabilityCard(
          assessment: assessment,
          reading: r,
          readings: store.patientReadings,
        ),
        const SizedBox(height: 24),

        // 9. Documented Clinical Comorbidities Card
        CardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Documented Clinical Comorbidities',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conditionKeys.map((c) {
                  final active = profile.conditions[c] == 1;
                  return Chip(
                    label: Text(conditionLabels[c] ?? c),
                    backgroundColor: active ? primaryBlueLight : slateBackground,
                    side: BorderSide(color: active ? primaryBlue : borderSlate),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? primaryBlue : textSecondary,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================================
// CLINICAL SUB-COMPONENTS FOR DOCTOR WORKSPACE
// ============================================================================

/// 1. Physician Diagnostic Severity Card
class _DoctorDiagnosticSummaryCard extends StatelessWidget {
  final Assessment? assessment;
  final Profile profile;
  final VoidCallback onOpenReport;

  const _DoctorDiagnosticSummaryCard({
    required this.assessment,
    required this.profile,
    required this.onOpenReport,
  });

  @override
  Widget build(BuildContext context) {
    final band = assessment?.band ?? RiskBand.low;
    final scoreVal = assessment?.riskScoreStage2 ?? assessment?.riskScoreStage1 ?? 0.0;
    final scorePercent = (scoreVal * 100).toStringAsFixed(1);
    final alerts = assessment?.alerts ?? [];

    Color accentColor;
    String headline;
    String clinicalSummary;

    switch (band) {
      case RiskBand.high:
        accentColor = const Color(0xFFDC2626);
        headline = 'Acute Pneumonia Risk Flagged (Urgent Clinical Review)';
        clinicalSummary =
            'Patient presentation exhibits acute respiratory distress and/or physiological desaturation. High likelihood of community-acquired pneumonia requiring urgent clinical assessment, chest radiography, and targeted treatment.';
        break;
      case RiskBand.moderate:
        accentColor = const Color(0xFFD97706);
        headline = 'Early Respiratory Infection / Moderate Pneumonia Risk';
        clinicalSummary =
            'Intermediate inflammatory indicators detected. Ambulatory monitoring, temperature tracking, and clinical follow-up recommended to prevent secondary pulmonary decline.';
        break;
      case RiskBand.low:
        accentColor = const Color(0xFF16A34A);
        headline = 'Physiologically Stable / Low Risk of Active Pneumonia';
        clinicalSummary =
            'Vital signs, respiratory rates, and clinical markers remain within safe physiological baseline ranges. Standard preventative care indicated.';
        break;
      case RiskBand.pending:
        accentColor = primaryBlue;
        headline = 'Assessment Pending Additional Telemetry';
        clinicalSummary =
            'Initial screening flagged mild indicators. Additional physiological vitals or laboratory results are required to compute Stage 2 risk score.';
        break;
      case RiskBand.watch:
        accentColor = const Color(0xFFD97706);
        headline = 'Active Clinical Watch / Reassessment Scheduled';
        clinicalSummary =
            'Initial positive Stage 2 risk score. Repeat assessment within 4 to 36 hours recommended to confirm clinical trajectory.';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(band.icon, color: accentColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            headline,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (assessment?.at != null)
                          Text(
                            formatDateTime(assessment!.at),
                            style: const TextStyle(fontSize: 12, color: textMuted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            'AI Risk Probability: $scorePercent%',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: accentColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBlueLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryBlue.withOpacity(0.2)),
                          ),
                          child: Text(
                            'Stage ${assessment?.stage ?? 2} Multi-Modal Model',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clinicalSummary,
                      style: const TextStyle(fontSize: 13.5, height: 1.5, color: textSecondary),
                    ),
                    if (alerts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: alertRedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: alertRedBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: destructiveRed),
                                SizedBox(width: 6),
                                Text(
                                  'Active Critical Safety Flags:',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: destructiveRed),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...alerts.map((a) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('• ${a.message}',
                                      style: const TextStyle(fontSize: 12.5, color: destructiveRed)),
                                )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        onPressed: onOpenReport,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('Open Formal Clinical Report'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Interactive Physician Action Checklist (Option 1)
class _PhysicianActionChecklist extends StatelessWidget {
  final double? currentSpo2;
  final bool hasCopd;
  final Set<int> checkedOrders;
  final ValueChanged<int> onToggle;

  const _PhysicianActionChecklist({
    this.currentSpo2,
    this.hasCopd = false,
    required this.checkedOrders,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final spo2Text = currentSpo2 != null ? '${currentSpo2!.toInt()}%' : 'desaturated';
    final copdNote = hasCopd
        ? 'Target SpO₂: 88–92% (patient has documented COPD to avoid hypercapnic respiratory depression).'
        : 'Target SpO₂: 92–96% (titrate nasal cannula/mask to avoid hyperoxia).';

    final List<Map<String, String>> actions = [
      {
        'title': 'Initiate Supplemental O₂ Therapy Immediately',
        'details': 'Patient SpO₂ is at $spo2Text. $copdNote',
        'tag': 'Urgent Oxygenation',
        'tagColor': 'red',
      },
      {
        'title': 'Order Urgent Diagnostic Imaging (PA & Lateral CXR or CT)',
        'details':
            'Evaluate for lobar consolidation, air bronchograms, interstitial infiltrates, and parapneumonic pleural effusion.',
        'tag': 'Diagnostic Imaging',
        'tagColor': 'blue',
      },
      {
        'title': 'Emergency Laboratory Workup & Microbial Cultures',
        'details':
            'Order CBC with differential (WBC, NLR), Serum CRP, Venous/Arterial Blood Gas (ABG), and Blood/Sputum cultures prior to antibiotics.',
        'tag': 'Laboratory',
        'tagColor': 'purple',
      },
      {
        'title': 'Clinical Stratification & Triage (CURB-65 / PSI Criteria)',
        'details':
            'Assess confusion, urea, respiratory rate, blood pressure, and age to determine outpatient vs. ward vs. ICU level monitoring.',
        'tag': 'Clinical Triage',
        'tagColor': 'amber',
      },
    ];

    final progressCount = checkedOrders.length;
    final totalCount = actions.length;

    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: primaryBlue, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Immediate Physician Action Checklist (Clinical Protocol)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressCount == totalCount ? const Color(0xFFDCFCE7) : primaryBlueLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: progressCount == totalCount ? const Color(0xFF16A34A) : primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$progressCount of $totalCount Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: progressCount == totalCount ? const Color(0xFF15803D) : primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Interactive order checklist. Tap checkboxes as diagnostic investigations, oxygenation, and triage steps are initiated.',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),
          ...List.generate(actions.length, (index) {
            final item = actions[index];
            final isDone = checkedOrders.contains(index);

            Color tagColor;
            switch (item['tagColor']) {
              case 'red':
                tagColor = const Color(0xFFDC2626);
                break;
              case 'blue':
                tagColor = primaryBlue;
                break;
              case 'purple':
                tagColor = const Color(0xFF7C3AED);
                break;
              default:
                tagColor = const Color(0xFFD97706);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onToggle(index),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFF8FAFC) : surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? const Color(0xFFCBD5E1) : borderSlate,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isDone,
                        activeColor: const Color(0xFF16A34A),
                        onChanged: (_) => onToggle(index),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                      color: isDone ? textMuted : textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tagColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['tag']!,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tagColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['details']!,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: isDone ? textMuted : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 3. Patient Reported Symptoms Card
class _PatientReportedSymptomsCard extends StatelessWidget {
  final Map<String, dynamic>? symptomsMap;
  const _PatientReportedSymptomsCard({this.symptomsMap});

  @override
  Widget build(BuildContext context) {
    final symptoms = symptomsMap ?? {};
    final isDyspnea = symptoms['respiratory_distress'] == 1 || symptoms['dyspnea'] == 1;
    final isCough = symptoms['cough'] == 1;
    final isFever = symptoms['fever'] == 1;
    final isWeakness = symptoms['weakness'] == 1;

    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Patient-Reported Subjective Symptoms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Clinical symptoms reported directly by the patient during their latest evaluation check-in.',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _SymptomBadge(
                label: 'Shortness of Breath at Rest',
                present: isDyspnea,
                isDanger: true,
              ),
              _SymptomBadge(
                label: 'Productive / Persistent Cough',
                present: isCough,
              ),
              _SymptomBadge(
                label: 'Feverishness / Chills',
                present: isFever,
              ),
              _SymptomBadge(
                label: 'Generalized Weakness / Fatigue',
                present: isWeakness,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SymptomBadge extends StatelessWidget {
  final String label;
  final bool present;
  final bool isDanger;

  const _SymptomBadge({
    required this.label,
    required this.present,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    IconData icon;
    String statusText;

    if (present) {
      if (isDanger) {
        color = const Color(0xFFDC2626);
        bg = alertRedBg;
        icon = Icons.warning_amber_rounded;
        statusText = 'REPORTED (Critical)';
      } else {
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        icon = Icons.check_circle_outline;
        statusText = 'REPORTED';
      }
    } else {
      color = const Color(0xFF16A34A);
      bg = const Color(0xFFF0FDF4);
      icon = Icons.remove_circle_outline;
      statusText = 'Not Reported';
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: present ? textPrimary : textMuted,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Hemodynamic & Severity Indices
class _AdvancedHemodynamicIndicesCard extends StatelessWidget {
  final Reading? reading;
  const _AdvancedHemodynamicIndicesCard({this.reading});

  @override
  Widget build(BuildContext context) {
    final hr = reading?.heartRate;
    final sbp = reading?.sbp;
    final rr = reading?.respiratoryRate;
    final spo2 = reading?.spo2;
    final tempF = reading?.temperature;

    double? shockIndex;
    if (hr != null && sbp != null && sbp > 0) {
      shockIndex = hr / sbp;
    }

    String shockIndexStatus = 'Normal (< 0.7)';
    Color shockIndexColor = const Color(0xFF16A34A);
    if (shockIndex != null) {
      if (shockIndex >= 1.0) {
        shockIndexStatus = 'Critical (≥ 1.0) — Hemodynamic Instability';
        shockIndexColor = const Color(0xFFDC2626);
      } else if (shockIndex >= 0.7) {
        shockIndexStatus = 'Elevated (0.7–0.99) — Compensated Sepsis Stress';
        shockIndexColor = const Color(0xFFD97706);
      }
    }

    final tempC = tempF != null ? ((tempF - 32) * 5 / 9).toStringAsFixed(1) : null;

    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Advanced Hemodynamic & Physiological Indices',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Derived clinical risk metrics calculated from vital sign interactions.',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _IndexTile(
                label: 'Clinical Shock Index (HR / SBP)',
                value: shockIndex != null ? shockIndex.toStringAsFixed(2) : '--',
                status: shockIndexStatus,
                statusColor: shockIndexColor,
                reference: 'Typical: 0.50 – 0.70',
              ),
              _IndexTile(
                label: 'Core Temperature',
                value: tempF != null ? '$tempF°F ($tempC°C)' : '--',
                status: (tempF != null && tempF >= 100.4) ? 'Pyrexia / Fever' : 'Euthermic',
                statusColor: (tempF != null && tempF >= 100.4) ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                reference: 'Normal: 97.0°F – 99.0°F',
              ),
              _IndexTile(
                label: 'Respiratory Frequency Status',
                value: rr != null ? '${rr.toInt()} /min' : '--',
                status: (rr != null && rr >= 24)
                    ? 'Severe Tachypnea (NEWS2: 3 pts)'
                    : (rr != null && rr >= 20 ? 'Mild Tachypnea' : 'Normal Rate'),
                statusColor: (rr != null && rr >= 24) ? const Color(0xFFDC2626) : primaryBlue,
                reference: 'Normal: 12 – 20 /min',
              ),
              _IndexTile(
                label: 'Pulse Oximetry Oxygenation',
                value: spo2 != null ? '${spo2.toInt()}%' : '--',
                status: (spo2 != null && spo2 < 90)
                    ? 'Critical Hypoxemia (NEWS2: 3 pts)'
                    : (spo2 != null && spo2 < 94 ? 'Moderate Hypoxemia' : 'Normal Saturation'),
                statusColor: (spo2 != null && spo2 < 90) ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                reference: 'Normal: 95% – 100%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndexTile extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color statusColor;
  final String reference;

  const _IndexTile({
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor),
          ),
          const SizedBox(height: 4),
          Text(reference, style: const TextStyle(fontSize: 11, color: textMuted)),
        ],
      ),
    );
  }
}

/// 5. Longitudinal Telemetry Table (History Timeline)
class _LongitudinalTrajectoryTable extends StatelessWidget {
  final List<Reading> readings;
  final List<Assessment> assessments;

  const _LongitudinalTrajectoryTable({
    required this.readings,
    required this.assessments,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty && assessments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build unique chronological check-in entries
    final List<Map<String, dynamic>> rowsData = [];

    if (assessments.isNotEmpty) {
      // Each assessment represents a distinct clinical evaluation check-in
      for (final a in assessments.take(15)) {
        // Find matching reading for precise vitals if not in assessment.vitals
        final r = readings.firstWhere(
          (reading) => reading.at.difference(a.at).abs().inSeconds < 45,
          orElse: () => Reading(id: '', at: a.at, values: a.vitals, source: 'assessment'),
        );

        final spo2 = a.vitals['spo2'] ?? r.spo2;
        final rr = a.vitals['respiratory_rate'] ?? r.respiratoryRate;
        final hr = a.vitals['heart_rate'] ?? r.heartRate;
        final temp = a.vitals['temperature'] ?? r.temperature;
        final sbp = a.vitals['sbp'] ?? r.sbp;

        double? si;
        if (hr != null && sbp != null && sbp > 0) {
          si = hr / sbp;
        }

        final scoreVal = a.riskScoreStage2 ?? a.riskScoreStage1;
        final scoreStr = scoreVal != null ? '${(scoreVal * 100).toStringAsFixed(1)}%' : '--';

        final bandText = switch (a.band) {
          RiskBand.high => 'High Risk',
          RiskBand.moderate => 'Moderate Risk',
          RiskBand.low => 'Low Risk',
          RiskBand.watch => 'Clinical Watch',
          RiskBand.pending => 'Pending',
        };

        rowsData.add({
          'at': a.at,
          'spo2': spo2,
          'rr': rr,
          'hr': hr,
          'temp': temp,
          'sbp': sbp,
          'si': si,
          'score': scoreStr,
          'band': a.band,
          'bandText': bandText,
        });
      }
    } else {
      // Fallback: Deduplicate readings so identical readings from the same minute appear once
      final seenTimes = <String>{};
      for (final r in readings.take(15)) {
        final timeKey = '${r.at.year}-${r.at.month}-${r.at.day}-${r.at.hour}-${r.at.minute}';
        if (seenTimes.contains(timeKey)) continue;
        seenTimes.add(timeKey);

        final spo2 = r.spo2;
        final rr = r.respiratoryRate;
        final hr = r.heartRate;
        final temp = r.temperature;
        final sbp = r.sbp;

        double? si;
        if (hr != null && sbp != null && sbp > 0) {
          si = hr / sbp;
        }

        final isHigh = (spo2 != null && spo2 < 90) || (rr != null && rr >= 24);

        rowsData.add({
          'at': r.at,
          'spo2': spo2,
          'rr': rr,
          'hr': hr,
          'temp': temp,
          'sbp': sbp,
          'si': si,
          'score': '--',
          'band': isHigh ? RiskBand.high : RiskBand.low,
          'bandText': isHigh ? 'High Risk' : 'Low Risk',
        });
      }
    }

    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Longitudinal Multi-Day Telemetry History (Last 7 Days)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Sequential telemetry logs demonstrating vital trajectory and temporal decline/recovery.',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(slateBackground),
              columns: const [
                DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('SpO₂', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Breathing', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Heart Rate', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Temp (°F)', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('SBP', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Shock Index', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('AI Score', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Risk Band', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: rowsData.map((data) {
                final DateTime at = data['at'];
                final double? spo2 = data['spo2'];
                final double? rr = data['rr'];
                final double? hr = data['hr'];
                final double? temp = data['temp'];
                final double? sbp = data['sbp'];
                final double? si = data['si'];
                final String scoreStr = data['score'];
                final RiskBand band = data['band'];
                final String bandText = data['bandText'];

                final isSpo2Low = spo2 != null && spo2 < 90;
                final isRrHigh = rr != null && rr >= 24;
                final isSiHigh = si != null && si >= 1.0;

                return DataRow(
                  cells: [
                    DataCell(Text(formatDateTime(at), style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Text(
                        spo2 != null ? '${spo2.toInt()}%' : '--',
                        style: TextStyle(
                          fontWeight: isSpo2Low ? FontWeight.w700 : FontWeight.w500,
                          color: isSpo2Low ? const Color(0xFFDC2626) : textPrimary,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        rr != null ? '${rr.toInt()} /min' : '--',
                        style: TextStyle(
                          fontWeight: isRrHigh ? FontWeight.w700 : FontWeight.w500,
                          color: isRrHigh ? const Color(0xFFDC2626) : textPrimary,
                        ),
                      ),
                    ),
                    DataCell(Text(hr != null ? '${hr.toInt()} bpm' : '--')),
                    DataCell(Text(temp != null ? '${temp.toStringAsFixed(1)}°F' : '--')),
                    DataCell(Text(sbp != null ? '${sbp.toInt()} mmHg' : '--')),
                    DataCell(
                      Text(
                        si != null ? si.toStringAsFixed(2) : '--',
                        style: TextStyle(
                          fontWeight: isSiHigh ? FontWeight.w700 : FontWeight.w500,
                          color: isSiHigh ? const Color(0xFFDC2626) : textPrimary,
                        ),
                      ),
                    ),
                    DataCell(Text(scoreStr, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: band.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bandText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: band.textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 6. AI Model Diagnostic Explainability
class _ModelExplainabilityCard extends StatelessWidget {
  final Assessment? assessment;
  final Reading? reading;
  final List<Reading> readings;

  const _ModelExplainabilityCard({
    this.assessment,
    this.reading,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> drivers = [];

    final spo2 = reading?.spo2;
    if (spo2 != null && spo2 < 90) {
      drivers.add('Critical Hypoxemia Alert: Blood oxygen is below 90% (triggers automatic emergency safety gate).');
    } else if (spo2 != null && spo2 < 94) {
      drivers.add('Moderate Desaturation: SpO₂ below 94% added +0.60 to log-odds.');
    }

    final rr = reading?.respiratoryRate;
    if (rr != null && rr >= 24) {
      drivers.add('Severe Tachypnea: Respiratory rate of ${rr.toInt()}/min (≥ 24) added +1.10 log-odds.');
    } else if (rr != null && rr >= 20) {
      drivers.add('Elevated Respiratory Rate: Breathing rate of ${rr.toInt()}/min added +0.40 log-odds.');
    }

    final temp = reading?.temperature;
    if (temp != null && temp >= 100.4) {
      drivers.add('Acute Pyrexia: Temperature of ${temp.toStringAsFixed(1)}°F (≥ 100.4°F) added +0.80 log-odds.');
    }

    final hr = reading?.heartRate;
    if (hr != null && hr >= 100) {
      drivers.add('Compensatory Tachycardia: Heart rate of ${hr.toInt()} bpm (≥ 100) added +0.35 log-odds.');
    }

    // Trajectory features across window
    if (readings.length >= 2) {
      final spo2List = readings.map((r) => r.spo2).whereType<double>().toList();
      if (spo2List.length >= 2) {
        final maxO2 = spo2List.reduce((a, b) => a > b ? a : b);
        final minO2 = spo2List.reduce((a, b) => a < b ? a : b);
        final drop = maxO2 - minO2;
        if (drop >= 4.0) {
          drivers.add('Longitudinal SpO₂ Plunge: Oxygen dropped by ${drop.toStringAsFixed(1)}% across consecutive checks (+0.70 log-odds).');
        }
      }

      final rrList = readings.map((r) => r.respiratoryRate).whereType<double>().toList();
      if (rrList.length >= 2) {
        final maxRr = rrList.reduce((a, b) => a > b ? a : b);
        final minRr = rrList.reduce((a, b) => a < b ? a : b);
        if ((maxRr - minRr) >= 5.0) {
          drivers.add('Respiratory Escalation: Breathing rate increased by ${(maxRr - minRr).toInt()} breaths/min (+0.45 log-odds).');
        }
      }
    }

    if (drivers.isEmpty) {
      drivers.add('Patient presentation aligns with normal physiological baseline bounds with no acute penalties.');
    }

    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, color: primaryBlue, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Two-Stage AI Diagnostic Explainability (Feature Contribution)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Auditable clinical breakdown of physiological signals and trajectory shifts that influenced the AI model output.',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),
          ...drivers.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right_rounded, color: primaryBlue, size: 20),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 13, height: 1.45, color: textPrimary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

