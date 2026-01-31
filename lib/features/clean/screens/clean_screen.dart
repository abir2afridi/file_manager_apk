import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';
import 'package:file_explorer_apk/services/storage_service.dart';

class CleanScreen extends ConsumerWidget {
  const CleanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(storageStatsProvider);
    final analysisAsync = ref.watch(storageAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean'),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded), onPressed: () {}),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => analysisAsync.when(
          data: (analysis) => _buildCleanContent(context, stats, analysis),
          loading: () => _buildLoadingState(context),
          error: (err, stack) => _buildErrorState(context, err),
        ),
        loading: () => _buildLoadingState(context),
        error: (err, stack) => _buildErrorState(context, err),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyzing your storage...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanContent(
    BuildContext context,
    StorageStats stats,
    StorageAnalysis analysis,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _buildHeroStorageCard(context, stats),
        const SizedBox(height: 32),
        _buildCategoryHeader(context, 'Suggestions'),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Junk Files',
          description:
              '${analysis.cacheFolders.length} cache folders can be removed',
          icon: Icons.delete_sweep_rounded,
          color: Colors.amber,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Duplicate Files',
          description: '${analysis.duplicateFiles.length} clones found around',
          icon: Icons.copy_rounded,
          color: Colors.blue,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Large Files',
          description: '${analysis.largeFiles.length} heavy items detected',
          icon: Icons.high_quality_rounded,
          color: Colors.purple,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Redundant APKs',
          description: '${analysis.oldApks.length} installers no longer needed',
          icon: Icons.android_rounded,
          color: Colors.green,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildHeroStorageCard(BuildContext context, StorageStats stats) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Up Space',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to optimize your device',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_rounded, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _StorageGaugePainter(
                  percent: stats.percentUsed,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.1),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(stats.percentUsed * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'USED',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetric(context, 'Used', stats.usedText),
              Container(
                width: 1,
                height: 24,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildMetric(context, 'Free', stats.freeText),
              Container(
                width: 1,
                height: 24,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildMetric(context, 'Total', stats.totalText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCleanSection(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color backgroundColor;

  _StorageGaugePainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 14.0;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.8 * 3.14159, // Start angle
      1.4 * 3.14159, // Sweep angle (total path)
      false,
      bgPaint,
    );

    // Active progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Outer glow for progress
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweepAngle = (percent.clamp(0.0, 1.0)) * 1.4 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.8 * 3.14159,
      sweepAngle,
      false,
      glowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.8 * 3.14159,
      sweepAngle,
      false,
      progressPaint,
    );

    // Small dots along the track for a technical look
    final dotPaint = Paint()..color = color.withValues(alpha: 0.3);
    for (var i = 0; i <= 8; i++) {
      final angle = (0.8 + (i / 8) * 1.4) * math.pi;
      final offset = Offset(
        center.dx + (radius - strokeWidth - 12) * math.cos(angle),
        center.dy + (radius - strokeWidth - 12) * math.sin(angle),
      );
      canvas.drawCircle(offset, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StorageGaugePainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}
