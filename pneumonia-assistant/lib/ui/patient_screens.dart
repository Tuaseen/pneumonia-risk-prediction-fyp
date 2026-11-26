import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import 'design.dart';

// ============================================================================
// 1. DASHBOARD SCREEN
// ============================================================================
class DashboardScreen extends StatelessWidget {
  final AppStore store;
  final VoidCallback onAskAssistant;
  final VoidCallback onShowHistory;

  const DashboardScreen({
    super.key,
    required this.store,
    required this.onAskAssistant,
    required this.onShowHistory,
  });

  String _formatToday() {
    final now = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = store.profile.name.trim().isEmpty
        ? 'Patient'
        : store.profile.name.trim().split(' ').first;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1050;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header
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
                  _formatToday(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, $name',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete your daily check-in to assess respiratory health and view your plain-language report.',
                  style: TextStyle(fontSize: 13.5, color: textMuted),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: onAskAssistant,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: const Text('Ask the assistant'),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Responsive Layout
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Column: Status Card + Recent Reports
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (store.criticalAlerts.isNotEmpty) ...[
                      CriticalAlertsWidget(alerts: store.criticalAlerts),
                      const SizedBox(height: 16),
                    ],
                    StatusCardWidget(
                      assessment: store.latestAssessment,
                      profile: store.profile,
                      alertActive: store.criticalAlerts.isNotEmpty,
                    ),
                    const SizedBox(height: 28),
                    _RecentAssessmentsSection(
                      store: store,
                      onShowHistory: onShowHistory,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),

              // Sidebar Column: Daily Health Check Form
              Expanded(
                flex: 5,
                child: _DailyCheckCard(store: store),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.criticalAlerts.isNotEmpty) ...[
                CriticalAlertsWidget(alerts: store.criticalAlerts),
                const SizedBox(height: 16),
              ],
              StatusCardWidget(
                assessment: store.latestAssessment,
                profile: store.profile,
                alertActive: store.criticalAlerts.isNotEmpty,
              ),
              const SizedBox(height: 28),
              _DailyCheckCard(store: store),
              const SizedBox(height: 28),
              _RecentAssessmentsSection(
                store: store,
                onShowHistory: onShowHistory,
              ),
            ],
          ),
      ],
    );
  }
}

// ============================================================================
// DAILY CHECK-IN CARD (Symptoms + Optional Self-Reported Vitals & Labs)
// ============================================================================
class _DailyCheckCard extends StatefulWidget {
  final AppStore store;
  const _DailyCheckCard({required this.store});

  @override
  State<_DailyCheckCard> createState() => _DailyCheckCardState();
}

class _DailyCheckCardState extends State<_DailyCheckCard> {
  int? _respiratoryDistress = 0;
  int? _cough = 0;
  int? _fever = 0;
  int? _weakness = 0;
  bool _running = false;
  bool _showVitalsInputs = false;
  bool _showLabsInputs = false;

  // Optional vitals controllers
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _sbpCtrl = TextEditingController();

  // Optional labs controllers
  final _wbcCtrl = TextEditingController();
  final _neutCtrl = TextEditingController();
  final _lymphCtrl = TextEditingController();
  final _crpCtrl = TextEditingController();

  @override
  void dispose() {
    _spo2Ctrl.dispose();
    _tempCtrl.dispose();
    _rrCtrl.dispose();
    _hrCtrl.dispose();
    _sbpCtrl.dispose();
    _wbcCtrl.dispose();
    _neutCtrl.dispose();
    _lymphCtrl.dispose();
    _crpCtrl.dispose();
    super.dispose();
  }

  bool get _ready =>
      _respiratoryDistress != null &&
      _cough != null &&
      _fever != null &&
      _weakness != null;

  Future<void> _runCheck() async {
    if (!_ready || _running) return;
    setState(() => _running = true);

    try {
      final symptoms = SymptomCheck(
        respiratoryDistress: _respiratoryDistress,
        cough: _cough,
        fever: _fever,
        weakness: _weakness,
      );

      // Collect self-reported vitals if entered
      final Map<String, double> vitals = {};
      final spo2Val = double.tryParse(_spo2Ctrl.text.trim());
      final tempVal = double.tryParse(_tempCtrl.text.trim());
      final rrVal = double.tryParse(_rrCtrl.text.trim());
      final hrVal = double.tryParse(_hrCtrl.text.trim());
      final sbpVal = double.tryParse(_sbpCtrl.text.trim());
      if (spo2Val != null) vitals['spo2'] = spo2Val;
      if (tempVal != null) vitals['temperature'] = tempVal;
      if (rrVal != null) vitals['respiratory_rate'] = rrVal;
      if (hrVal != null) vitals['heart_rate'] = hrVal;
      if (sbpVal != null) vitals['sbp'] = sbpVal;

      // Collect self-reported labs if entered
      LabResults? labs;
      final wbcVal = double.tryParse(_wbcCtrl.text.trim());
      final neutVal = double.tryParse(_neutCtrl.text.trim());
      final lymphVal = double.tryParse(_lymphCtrl.text.trim());
      final crpVal = double.tryParse(_crpCtrl.text.trim());
      if (wbcVal != null || neutVal != null || lymphVal != null || crpVal != null) {
        labs = LabResults(
          wbc: wbcVal,
          neutrophils: neutVal,
          lymphocytes: lymphVal,
          crp: crpVal,
          takenAt: DateTime.now(),
        );
      }

      final assessment = await widget.store.assessDailyCheck(
        symptoms,
        selfVitals: vitals.isNotEmpty ? vitals : null,
        selfLabs: labs,
      );

      if (mounted) {
        showSuccessSnackBar(
          context,
          'Assessment complete: ${assessment.riskTierTitle}.',
        );

        // Immediately open the plain-language report dialog for the user
        showDialog(
          context: context,
          builder: (_) => PatientReportDialog(
            assessment: assessment,
            profile: widget.store.profile,
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 20,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run a Daily Check',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Answer 4 questions to evaluate your symptoms',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: borderSlate),
          const SizedBox(height: 8),

          // Symptoms 1 to 4
          YesNoControl(
            label: 'Short of breath?',
            hint: 'Are you short of breath, even when resting?',
            value: _respiratoryDistress,
            onChanged: (v) => setState(() => _respiratoryDistress = v),
          ),
          const Divider(height: 1, color: borderSlate),
          YesNoControl(
            label: 'Coughing?',
            hint: 'Do you have a new or worsening cough?',
            value: _cough,
            onChanged: (v) => setState(() => _cough = v),
          ),
          const Divider(height: 1, color: borderSlate),
          YesNoControl(
            label: 'Feverish?',
            hint: 'Do you feel feverish, hot, or have chills?',
            value: _fever,
            onChanged: (v) => setState(() => _fever = v),
          ),
          const Divider(height: 1, color: borderSlate),
          YesNoControl(
            label: 'Tired or weak?',
            hint: 'Do you feel unusually fatigued or exhausted?',
            value: _weakness,
            onChanged: (v) => setState(() => _weakness = v),
          ),

          // Optional Vitals Accordion
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _showVitalsInputs = !_showVitalsInputs),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _showVitalsInputs ? primaryBlueLight : slateBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 16, color: primaryBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Optional: Measured Vitals (BP Monitor / Pulse Oximeter / Thermometer)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showVitalsInputs ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_showVitalsInputs) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _spo2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Oxygen SpO2',
                      hintText: 'e.g. 98',
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tempCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      hintText: 'e.g. 98.6',
                      suffixText: '°F',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rrCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Breathing Rate',
                      hintText: 'e.g. 18',
                      suffixText: '/min',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _hrCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Heart Rate',
                      hintText: 'e.g. 76',
                      suffixText: 'bpm',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sbpCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Systolic Blood Pressure (SBP)',
                hintText: 'e.g. 120',
                suffixText: 'mmHg',
              ),
            ),
          ],

          // Optional Labs Accordion
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _showLabsInputs = !_showLabsInputs),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _showLabsInputs ? const Color(0xFFF3E8FF) : slateBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, size: 16, color: labThemeColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Optional: Lab Test Results (Blood Work)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showLabsInputs ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_showLabsInputs) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wbcCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'WBC Count',
                      hintText: 'e.g. 7.5',
                      suffixText: '×10⁹',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _crpCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'CRP Level',
                      hintText: 'e.g. 4.2',
                      suffixText: 'mg/L',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _neutCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Neutrophils',
                      hintText: 'e.g. 62.0',
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lymphCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Lymphocytes',
                      hintText: 'e.g. 28.5',
                      suffixText: '%',
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _ready && !_running ? _runCheck : null,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(_running ? 'Evaluating Health…' : 'Calculate Risk & View Report'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT ASSESSMENTS SECTION
// ============================================================================
class _RecentAssessmentsSection extends StatelessWidget {
  final AppStore store;
  final VoidCallback onShowHistory;

  const _RecentAssessmentsSection({
    required this.store,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final list = store.assessments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Health Reports',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            if (store.assessments.length > 3)
              TextButton(
                onPressed: onShowHistory,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const CardPanel(
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, size: 28, color: textMuted),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No health checks recorded yet',
                        style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Answer the 4 questions above to generate your first plain-language assessment.',
                        style: TextStyle(fontSize: 12.5, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...list.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardPanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: a.band.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.band.icon, color: a.band.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.riskTierTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDateTime(a.at),
                                style: const TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.plainLanguageSummary,
                            style: const TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PatientReportDialog(
                                    assessment: a,
                                    profile: store.profile,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.description_outlined, size: 15),
                              label: const Text('Open Full Report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ============================================================================
// 2. ASSISTANT / CHAT SCREEN
// ============================================================================
class AssistantScreen extends StatefulWidget {
  final AppStore store;
  const AssistantScreen({super.key, required this.store});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'How am I doing today?',
    'What does my last report mean?',
    'What warning signs should I watch out for?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await widget.store.sendChatMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1050;

    final chatBox = Container(
      height: 600,
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderSlate)),
            ),
            child: Row(
              children: [
                const BrandMark(size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pneumonia Assistant',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            store.busy ? 'Assistant is typing…' : 'Online',
                            style: const TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: store.chatMessages.length,
              itemBuilder: (context, i) {
                final m = store.chatMessages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment:
                        m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!m.isUser) ...[
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: primaryBlueLight,
                          child: Icon(Icons.auto_awesome, size: 14, color: primaryBlue),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: m.isUser ? primaryBlue : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(m.isUser ? 14 : 4),
                              bottomRight: Radius.circular(m.isUser ? 4 : 14),
                            ),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: m.isUser ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Suggestion Chips
          if (store.chatMessages.length <= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestions.map((s) {
                  return ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    backgroundColor: slateBackground,
                    side: const BorderSide(color: borderSlate),
                    onPressed: () => _send(s),
                  );
                }).toList(),
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderSlate)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your symptoms or report…',
                      hintStyle: TextStyle(fontSize: 13.5, color: textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _send(_textController.text),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assistant',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Chat with your automated clinical companion for guidance on symptoms, warning signs, and next steps.',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: chatBox),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    StatusCardWidget(
                      assessment: store.latestAssessment,
                      profile: store.profile,
                    ),
                    const SizedBox(height: 16),
                    if (store.criticalAlerts.isNotEmpty)
                      CriticalAlertsWidget(alerts: store.criticalAlerts),
                  ],
                ),
              ),
            ],
          )
        else
          chatBox,
      ],
    );
  }
}

// ============================================================================
// 3. HISTORY SCREEN (Assessment History & Plain-Language Reports)
// ============================================================================
class HistoryScreen extends StatelessWidget {
  final AppStore store;
  const HistoryScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final assessments = store.assessments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History & Reports',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Review past clinical check-ins, reported symptoms, and personalized plain-language health reports.',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),

        // Quick Stats Row
        CardPanel(
          child: Row(
            children: [
              _HistoryStatBox(
                label: 'Check-ins Completed',
                value: '${assessments.length}',
              ),
              _HistoryStatBox(
                label: 'Latest Status',
                value: assessments.isNotEmpty
                    ? switch (assessments.first.band) {
                        RiskBand.low => 'Low Risk',
                        RiskBand.moderate => 'Moderate Risk',
                        RiskBand.watch => 'Borderline Risk',
                        RiskBand.high => 'High Risk',
                        RiskBand.pending => 'Pending',
                      }
                    : 'None yet',
                color: assessments.isNotEmpty
                    ? assessments.first.band.color
                    : textMuted,
              ),
              _HistoryStatBox(
                label: 'Health Profile',
                value: store.profile.name.isNotEmpty
                    ? store.profile.name.split(' ').first
                    : 'Active',
              ),
            ],
          ),
        ),

        // 7-Day Multi-Day Rolling Window Summary
        if (assessments.length > 1) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, size: 20, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '7-Day Rolling Window Analysis (Multi-Day Trajectory)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${assessments.length} checks active',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'The Stage 2 model evaluates multi-day vital variability, SpO2 drop, and temperature range across your rolling 7-day health record.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF166534), height: 1.4),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),

        // Assessments Timeline
        const Text(
          'Clinical Check-in Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        if (assessments.isEmpty)
          const CardPanel(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 40, color: textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No previous assessments recorded yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Run your first daily check on the Dashboard to start building your health record.',
                      style: TextStyle(fontSize: 13, color: textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...assessments.map((a) {
            final symptoms = a.symptoms;
            final vitals = a.vitals;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CardPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: a.band.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.band.icon, color: a.band.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.riskTierTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatDateTime(a.at),
                                    style: const TextStyle(fontSize: 12, color: textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: a.band.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a.band.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: a.band.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Plain-language summary
                    Text(
                      a.plainLanguageSummary,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Symptoms tags
                    if (symptoms.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (symptoms['respiratory_distress'] == 1)
                            const _ReportPill(text: 'Shortness of breath', color: destructiveRed),
                          if (symptoms['cough'] == 1)
                            const _ReportPill(text: 'Coughing', color: Color(0xFFD97706)),
                          if (symptoms['fever'] == 1)
                            const _ReportPill(text: 'Feverish', color: destructiveRed),
                          if (symptoms['weakness'] == 1)
                            const _ReportPill(text: 'Fatigue / Weakness', color: textMuted),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Vitals snippet (if entered)
                    if (vitals.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (vitals.containsKey('spo2'))
                            _VitalChip(label: 'Oxygen SpO2', value: '${vitals['spo2']!.toInt()}%'),
                          if (vitals.containsKey('temperature'))
                            _VitalChip(label: 'Temp', value: '${vitals['temperature']!.toStringAsFixed(1)}°F'),
                          if (vitals.containsKey('respiratory_rate'))
                            _VitalChip(label: 'Breathing', value: '${vitals['respiratory_rate']!.toInt()}/min'),
                          if (vitals.containsKey('heart_rate'))
                            _VitalChip(label: 'Heart Rate', value: '${vitals['heart_rate']!.toInt()} bpm'),
                          if (vitals.containsKey('sbp'))
                            _VitalChip(label: 'Systolic BP', value: '${vitals['sbp']!.toInt()} mmHg'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Divider(height: 1, color: borderSlate),
                    const SizedBox(height: 12),

                    // Open Full Report Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => PatientReportDialog(
                              assessment: a,
                              profile: store.profile,
                            ),
                          );
                        },
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('View Plain-Language Health Report'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _HistoryStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _HistoryStatBox({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color ?? textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPill extends StatelessWidget {
  final String text;
  final Color color;

  const _ReportPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;

  const _VitalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: slateBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderSlate),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: textPrimary),
      ),
    );
  }
}

// ============================================================================
// 4. PROFILE SCREEN (Demographics & Medical History Flags)
// ============================================================================
class ProfileScreen extends StatefulWidget {
  final AppStore store;
  const ProfileScreen({super.key, required this.store});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _apiUrlController;
  final TextEditingController _doctorEmailController = TextEditingController();
  late Map<String, int> _conditions;
  String _sex = 'male';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.store.profile;
    _nameController = TextEditingController(text: p.name);
    _ageController = TextEditingController(
      text: p.age != null ? p.age.toString() : '',
    );
    _apiUrlController = TextEditingController(text: widget.store.apiUrl);
    _conditions = Map.of(p.conditions);
    _sex = p.sex.isNotEmpty ? p.sex : 'male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _apiUrlController.dispose();
    _doctorEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final ageVal = int.tryParse(_ageController.text.trim());
      final updated = widget.store.profile.copyWith(
        name: _nameController.text.trim(),
        age: ageVal,
        sex: _sex,
        conditions: _conditions,
      );
      await widget.store.saveProfile(updated);
      widget.store.setApiUrl(_apiUrlController.text);
      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.store.isCloudConnected
              ? 'Profile updated and saved to Cloud Firestore.'
              : 'Profile updated locally.',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final profile = store.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile & Settings',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your personal demographics, health history, and account settings.',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 28),

        // Demographics Card
        CardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryBlueLight,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 22,
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
                        Text(
                          profile.name.isNotEmpty ? profile.name : 'Patient Account',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.isCloudConnected
                              ? 'Cloud Account (${store.uid})'
                              : (store.demo ? 'Demo Mode' : 'Local Account'),
                          style: const TextStyle(fontSize: 12.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: borderSlate),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. John Doe',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        hintText: 'e.g. 45',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sex,
                      decoration: const InputDecoration(labelText: 'Biological Sex'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _sex = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pre-existing Conditions / Medical History
        CardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pre-Existing Health Conditions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'These medical history indicators allow the clinical model to calibrate your baseline pneumonia vulnerability.',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 16),
              ...conditionKeys.map((c) {
                final label = conditionLabels[c] ?? c;
                final active = _conditions[c] == 1;
                return SwitchListTile.adaptive(
                  title: Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: active,
                  activeColor: primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setState(() {
                      _conditions[c] = v ? 1 : 0;
                    });
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Linked Physicians / Doctor Connection
        CardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.medical_services_outlined, color: primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linked Physicians & Care Team',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Add your doctor’s email address so they can review your assessments and monitor your health from their Doctor Workspace.',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 16),

              if (profile.doctorIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.doctorIds.map((docId) {
                    return Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 16, color: primaryBlue),
                      label: Text(
                        docId,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => store.unlinkDoctor(docId),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: slateBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderSlate),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: textMuted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No doctors linked. Your health data remains completely private to you.',
                          style: TextStyle(fontSize: 12.5, color: textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _doctorEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Email Address',
                        hintText: 'e.g. dr.muneeb@gmail.com',
                        prefixIcon: Icon(Icons.alternate_email, size: 18),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      final email = _doctorEmailController.text.trim();
                      if (email.isNotEmpty && email.contains('@')) {
                        store.linkDoctor(email);
                        _doctorEmailController.clear();
                        showSuccessSnackBar(context, 'Doctor linked successfully!');
                      } else {
                        showErrorSnackBar(context, 'Please enter a valid email address.');
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Link Doctor'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save Profile Changes'),
          ),
        ),
        const SizedBox(height: 14),

        // Sign Out Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: destructiveRed,
              side: const BorderSide(color: alertRedBorder),
            ),
            onPressed: () => store.signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(store.demo ? 'Exit Demo to Sign In' : 'Sign Out'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
