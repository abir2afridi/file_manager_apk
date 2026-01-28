import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';

enum StorageMetricFocus { used, free, total }

Future<void> showStorageBreakdownSheet(
  BuildContext context, {
  required Color accentColor,
  required StorageStats stats,
  required StorageMetricFocus focus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _StorageBreakdownSheet(
      accentColor: accentColor,
      stats: stats,
      focus: focus,
    ),
  );
}

class _StorageBreakdownSheet extends StatelessWidget {
  final Color accentColor;
  final StorageStats stats;
  final StorageMetricFocus focus;

  const _StorageBreakdownSheet({
    required this.accentColor,
    required this.stats,
    required this.focus,
  });

  String get _headline {
    switch (focus) {
      case StorageMetricFocus.used:
        return 'Used storage';
      case StorageMetricFocus.free:
        return 'Free space';
      case StorageMetricFocus.total:
        return 'Total capacity';
    }
  }

  String get _summaryValue {
    switch (focus) {
      case StorageMetricFocus.used:
        return stats.usedText;
      case StorageMetricFocus.free:
        return stats.freeText;
      case StorageMetricFocus.total:
        return stats.totalText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.pie_chart_rounded, color: accentColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summaryValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StorageDonutPainter(
                        accentColor: accentColor,
                        usedFraction: stats.percentUsed.clamp(0, 1),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(stats.percentUsed * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Used', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _MetricLegendTile(
            color: accentColor,
            label: 'Used',
            value: stats.usedText,
            ratio: stats.percentUsed,
          ),
          const SizedBox(height: 12),
          _MetricLegendTile(
            color: theme.colorScheme.secondary,
            label: 'Free',
            value: stats.freeText,
            ratio: stats.totalGB == 0 ? 0 : stats.freeGB / stats.totalGB,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.storage_rounded, color: onAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total capacity ${stats.totalText}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onAccent,
                      fontWeight: FontWeight.w600,
                    ),
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

class _MetricLegendTile extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double ratio;

  const _MetricLegendTile({
    required this.color,
    required this.label,
    required this.value,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayRatio = (ratio.clamp(0, 1) * 100).toStringAsFixed(1);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.circle, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$displayRatio%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StorageDonutPainter extends CustomPainter {
  final Color accentColor;
  final double usedFraction;

  _StorageDonutPainter({
    required this.accentColor,
    required this.usedFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    final backgroundPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final usedPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor,
          accentColor.withValues(alpha: 0.65),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * usedFraction.clamp(0, 1);
    final startAngle = -math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      usedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StorageDonutPainter oldDelegate) {
    return oldDelegate.usedFraction != usedFraction ||
        oldDelegate.accentColor != accentColor;
  }
}
