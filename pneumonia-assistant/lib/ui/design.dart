import 'package:flutter/material.dart';

import '../domain/models.dart';

// --- Color Palette matching Web Frontend ---
const Color slateBackground = Color(0xFFF8FAFC);
const Color surfaceWhite = Color(0xFFFFFFFF);
const Color borderSlate = Color(0xFFE2E8F0);
const Color borderFocus = Color(0xFF93C5FD);
const Color textPrimary = Color(0xFF0F172A);
const Color textSecondary = Color(0xFF475569);
const Color textMuted = Color(0xFF64748B);
const Color primaryBlue = Color(0xFF1D4ED8);
const Color primaryBlueLight = Color(0xFFEFF6FF);
const Color destructiveRed = Color(0xFFDC2626);
const Color alertRedBg = Color(0xFFFEF2F2);
const Color alertRedBorder = Color(0xFFFECACA);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryBlue,
    primary: primaryBlue,
    surface: surfaceWhite,
    error: destructiveRed,
  ),
  scaffoldBackgroundColor: slateBackground,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: textPrimary),
    bodyMedium: TextStyle(fontSize: 13.5, height: 1.5, color: textSecondary),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: surfaceWhite,
    foregroundColor: textPrimary,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    shape: Border(bottom: BorderSide(color: borderSlate, width: 1)),
  ),
  cardTheme: CardTheme(
    color: surfaceWhite,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: borderSlate, width: 1),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderSlate),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderSlate),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primaryBlue, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: borderSlate),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: surfaceWhite,
    indicatorColor: primaryBlueLight,
    surfaceTintColor: Colors.transparent,
    elevation: 2,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.w500,
        color: states.contains(WidgetState.selected)
            ? primaryBlue
            : textMuted,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? primaryBlue
            : textMuted,
        size: 22,
      ),
    ),
  ),
);

// --- Brand Mark Widget ---
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.health_and_safety_outlined,
          color: Colors.white,
          size: size * 0.62,
        ),
      ),
    );
  }
}

// --- Card Panel ---
class CardPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  const CardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor = surfaceWhite,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: borderSlate, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: body,
      );
    }
    return body;
  }
}

// --- Sparkline Graph Widget ---
class SparklineWidget extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const SparklineWidget({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final span = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / span;
      // Invert Y since 0 is top
      final y = size.height - (normalized * (size.height - 6)) - 3;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.20), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}

// --- Range Status Badge ---
class RangeStatusBadge extends StatelessWidget {
  final VitalRangeStatus status;

  const RangeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isNormal = status == VitalRangeStatus.normal;
    final text = isNormal
        ? 'Normal'
        : (status == VitalRangeStatus.below ? 'Below range' : 'Above range');

    final bg = isNormal ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final fg = isNormal ? const Color(0xFF15803D) : const Color(0xFFA16207);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- Vital Widget Tile matching Web ---
class VitalTile extends StatelessWidget {
  final String vitalKey;
  final double? value;
  final DateTime? at;
  final List<double> trend;
  final VoidCallback? onTap;

  const VitalTile({
    super.key,
    required this.vitalKey,
    required this.value,
    this.at,
    this.trend = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = vitalNames[vitalKey] ?? vitalKey;
    final unit = vitalUnits[vitalKey] ?? '';
    final digits = vitalDigits[vitalKey] ?? 0;
    final range = vitalRanges[vitalKey] ?? [0.0, 100.0];
    final color = vitalColors[vitalKey] ?? primaryBlue;

    final rangeStatus = value != null
        ? evaluateVital(vitalKey, value!)
        : VitalRangeStatus.normal;

    final iconData = switch (vitalKey) {
      'heart_rate' => Icons.favorite_outline,
      'respiratory_rate' => Icons.air,
      'sbp' => Icons.speed,
      'spo2' => Icons.water_drop_outlined,
      'temperature' => Icons.thermostat_outlined,
      _ => Icons.monitor_heart_outlined,
    };

    final valueString = value != null ? value!.toStringAsFixed(digits) : '—';
    final timeStr = at != null ? formatTime(at!) : '';
    final footer = 'Typical ${range[0].toInt()}–${range[1].toInt()}${timeStr.isNotEmpty ? ' · $timeStr' : ''}';

    return CardPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData, size: 17, color: color),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null) RangeStatusBadge(status: rangeStatus),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    valueString,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              if (trend.length >= 2)
                SizedBox(
                  width: 90,
                  child: SparklineWidget(values: trend, color: color, height: 32),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footer,
                style: const TextStyle(fontSize: 11.5, color: textMuted),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, size: 16, color: textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Labs Widget Tile matching Web ---
class LabsTile extends StatelessWidget {
  final LabResults? labs;
  final VoidCallback? onTap;

  const LabsTile({super.key, this.labs, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, size: 17, color: labThemeColor),
                  SizedBox(width: 7),
                  Text(
                    'Lab results',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              if (labs != null)
                Text(
                  formatTime(labs!.takenAt),
                  style: const TextStyle(fontSize: 11.5, color: textMuted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (labs != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LabItem(label: 'WBC', value: labs!.wbc?.toStringAsFixed(1) ?? '—'),
                _LabItem(label: 'Neut.', value: labs!.neutrophils != null ? '${labs!.neutrophils!.toInt()}%' : '—'),
                _LabItem(label: 'Lymph.', value: labs!.lymphocytes != null ? '${labs!.lymphocytes!.toInt()}%' : '—'),
                _LabItem(label: 'CRP', value: labs!.crp?.toStringAsFixed(1) ?? '—'),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No recent lab results recorded',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabItem extends StatelessWidget {
  final String label;
  final String value;

  const _LabItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

// --- Critical Alerts Banner matching Web ---
class CriticalAlertsWidget extends StatelessWidget {
  final List<Alert> alerts;
  final String? notice;

  const CriticalAlertsWidget({
    super.key,
    required this.alerts,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty && (notice == null || notice!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertRedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertRedBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: destructiveRed,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Action required',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
                if (notice != null && notice!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notice!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...alerts.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: destructiveRed, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              a.message,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Pneumonia Risk Status Card matching Web ---
class StatusCardWidget extends StatelessWidget {
  final Assessment? assessment;
  final RiskBand? band;
  final DateTime? assessedAt;
  final bool alertActive;
  final Profile? profile;

  const StatusCardWidget({
    super.key,
    this.assessment,
    this.band,
    this.assessedAt,
    this.alertActive = false,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final activeBand = assessment?.band ?? band;
    final atTime = assessedAt ?? assessment?.at;

    if (activeBand == null) {
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
              Container(width: 4, color: primaryBlue),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: primaryBlue, size: 22),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No result yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Run a daily check or ask the assistant to see your pneumonia risk status.',
                              style: TextStyle(fontSize: 13.5, color: textMuted),
                            ),
                          ],
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

    final isLowWithAlert = activeBand == RiskBand.low && alertActive;
    final title = isLowWithAlert ? 'Low pneumonia risk' : activeBand.label;
    final summary = isLowWithAlert
        ? 'No signs of pneumonia, but a reading above needs attention.'
        : activeBand.summary;

    final timeString = atTime != null ? formatDateTime(atTime) : '';

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
            Container(width: 4, color: activeBand.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(activeBand.icon, color: activeBand.color, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (timeString.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  timeString,
                                  style: const TextStyle(fontSize: 12, color: textMuted),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary,
                            style: const TextStyle(fontSize: 13.5, color: textSecondary),
                          ),
                          if (assessment?.displayScore != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: activeBand.backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Model risk score: ${(assessment!.displayScore! * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: activeBand.textColor,
                                ),
                              ),
                            ),
                          ],
                          if (assessment?.recommendation != null &&
                              assessment!.recommendation!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              assessment!.recommendation!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                          if (assessment != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.assignment_outlined, size: 16),
                              label: const Text('View Plain-Language Health Report'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PatientReportDialog(
                                    assessment: assessment!,
                                    profile: profile,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
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

// --- Detailed Plain-Language Patient Report Dialog ---
class PatientReportDialog extends StatelessWidget {
  final Assessment assessment;
  final Profile? profile;

  const PatientReportDialog({
    super.key,
    required this.assessment,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final band = assessment.band;
    final patientName = (profile?.name.trim().isNotEmpty == true)
        ? profile!.name.trim()
        : 'Patient';
    final ageText = profile?.age != null ? '${profile!.age} years old' : 'Age not specified';
    final sexText = profile?.sex == 'female' ? 'Female' : 'Male';

    final activeConditions = (profile?.conditions ?? {})
        .entries
        .where((e) => e.value == 1)
        .map((e) => conditionLabels[e.key] ?? e.key)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: band.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(band.icon, color: band.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pneumonia Health Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Evaluated for $patientName • ${formatDateTime(assessment.at)}',
                          style: const TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderSlate),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: band.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: band.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(band.icon, color: band.color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  assessment.riskTierTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: band.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assessment.plainLanguageSummary,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: band.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Symptoms Reviewed
                    const Text(
                      'What You Reported Today',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: slateBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSlate),
                      ),
                      child: Column(
                        children: [
                          _ReportItemRow(
                            label: 'Difficulty Breathing / Shortness of Breath',
                            value: assessment.symptoms['respiratory_distress'] == 1
                                ? 'Yes, reported'
                                : 'None reported',
                            isAlert: assessment.symptoms['respiratory_distress'] == 1,
                          ),
                          const Divider(height: 16, color: borderSlate),
                          _ReportItemRow(
                            label: 'Cough',
                            value: assessment.symptoms['cough'] == 1
                                ? 'Yes, active'
                                : 'No cough',
                            isAlert: assessment.symptoms['cough'] == 1,
                          ),
                          const Divider(height: 16, color: borderSlate),
                          _ReportItemRow(
                            label: 'Fever or Chills',
                            value: assessment.symptoms['fever'] == 1
                                ? 'Yes, feverish'
                                : 'No fever',
                            isAlert: assessment.symptoms['fever'] == 1,
                          ),
                          const Divider(height: 16, color: borderSlate),
                          _ReportItemRow(
                            label: 'Fatigue or Weakness',
                            value: assessment.symptoms['weakness'] == 1
                                ? 'Yes, unusually tired'
                                : 'Normal energy',
                            isAlert: assessment.symptoms['weakness'] == 1,
                          ),
                          if (assessment.vitals.isNotEmpty) ...[
                            if (assessment.vitals['spo2'] != null) ...[
                              const Divider(height: 16, color: borderSlate),
                              _ReportItemRow(
                                label: 'Blood Oxygen (SpO2)',
                                value: '${assessment.vitals['spo2']!.toStringAsFixed(0)}% (${assessment.vitals['spo2']! >= 95 ? 'Healthy level' : 'Below standard'})',
                                isAlert: assessment.vitals['spo2']! < 92,
                              ),
                            ],
                            if (assessment.vitals['temperature'] != null) ...[
                              const Divider(height: 16, color: borderSlate),
                              _ReportItemRow(
                                label: 'Body Temperature',
                                value: '${assessment.vitals['temperature']!.toStringAsFixed(1)} °F (${assessment.vitals['temperature']! <= 99.5 ? 'Normal' : 'Elevated'})',
                                isAlert: assessment.vitals['temperature']! >= 100.4,
                              ),
                            ],
                            if (assessment.vitals['sbp'] != null) ...[
                              const Divider(height: 16, color: borderSlate),
                              _ReportItemRow(
                                label: 'Systolic Blood Pressure (SBP)',
                                value: '${assessment.vitals['sbp']!.toStringAsFixed(0)} mmHg (${assessment.vitals['sbp']! < 90 ? 'Critically Low (Hypotension)' : (assessment.vitals['sbp']! > 140 ? 'Elevated' : 'Normal')})',
                                isAlert: assessment.vitals['sbp']! < 90,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Personal Health Context
                    const Text(
                      'Personal Health Context Checked',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Patient demographics: $ageText, $sexText.\n${activeConditions.isNotEmpty ? 'Pre-existing conditions evaluated: ${activeConditions.join(', ')}.' : 'No pre-existing respiratory or metabolic risk factors noted in your profile.'}',
                      style: const TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Recommended Action Plan
                    const Text(
                      'What You Should Do Next',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: assessment.simpleActionSteps
                          .map((step) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 3, right: 10),
                                      child: Icon(Icons.check_circle_outline,
                                          size: 16, color: primaryBlue),
                                    ),
                                    Expanded(
                                      child: Text(
                                        step,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.45,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Emergency Red Flags
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: alertRedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: alertRedBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: destructiveRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Emergency Warning Signs (Seek Immediate Care)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: destructiveRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: assessment.emergencyWarningSigns
                                .map((warning) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2, right: 8),
                                            child: Icon(Icons.arrow_right_rounded,
                                                size: 18, color: destructiveRed),
                                          ),
                                          Expanded(
                                            child: Text(
                                              warning,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF7F1D1D),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 5: Clinical Model Verification (Stage 1 & Stage 2)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: slateBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSlate),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_outlined, size: 16, color: primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                'Clinical ML Pipeline Execution (Stage 1 + Stage 2)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stage 1 Triage Screening: ${assessment.riskScoreStage1 != null ? "${(assessment.riskScoreStage1! * 100).toStringAsFixed(1)}%" : "Not run"}\n'
                            'Stage 2 Confirmatory Model: ${assessment.riskScoreStage2 != null ? "${(assessment.riskScoreStage2! * 100).toStringAsFixed(1)}%" : "Not run"}\n'
                            '${assessment.stage == 2 ? "Stage 1 flagged this check, so Stage 2 ran on the full record." : "Stage 2 runs only when Stage 1 flags a check."}',
                            style: const TextStyle(fontSize: 12, color: textMuted, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            const Divider(height: 1, color: borderSlate),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close Report'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportItemRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _ReportItemRow({
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: textSecondary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isAlert ? alertRedBg : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isAlert ? alertRedBorder : borderSlate),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAlert ? destructiveRed : textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Yes / No Toggle Button ---
class YesNoControl extends StatelessWidget {
  final String label;
  final String hint;
  final int? value; // 0, 1, or null
  final ValueChanged<int> onChanged;

  const YesNoControl({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(fontSize: 12.5, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: slateBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSlate),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleButton(
                  title: 'No',
                  selected: value == 0,
                  onTap: () => onChanged(0),
                ),
                _ToggleButton(
                  title: 'Yes',
                  selected: value == 1,
                  onTap: () => onChanged(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }
}

// --- Date & Time Formatter Helpers ---
String formatTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '$hour:$min $period';
}

String formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

String formatDateTime(DateTime dt) {
  return '${formatDate(dt)}, ${formatTime(dt)}';
}

void showErrorSnackBar(BuildContext context, Object error) {
  final msg = error is Exception
      ? error.toString().replaceFirst('Exception: ', '')
      : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
