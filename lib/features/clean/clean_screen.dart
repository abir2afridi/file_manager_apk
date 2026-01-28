import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_explorer_apk/features/file_explorer/screens/file_list_screen.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';
import 'package:file_explorer_apk/services/file_service.dart';
import 'package:file_explorer_apk/services/storage_service.dart';
import 'package:file_explorer_apk/widgets/storage_breakdown_sheet.dart';

class CleanScreen extends ConsumerWidget {
  final VoidCallback? onOpenDrawer;

  const CleanScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final statsAsync = ref.watch(storageStatsProvider);
    final analysisAsync = ref.watch(storageAnalysisProvider);

    Future<void> refresh() async {
      ref.invalidate(storageStatsProvider);
      ref.invalidate(storageAnalysisProvider);
      await Future.wait([
        ref.read(storageStatsProvider.future),
        ref.read(storageAnalysisProvider.future),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        leading: onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onOpenDrawer,
              )
            : null,
        title: const Text('Clean'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: statsAsync.when(
          data: (stats) => analysisAsync.when(
            data: (analysis) =>
                _buildContent(context, accentColor, stats, analysis),
            loading: () => _buildLoadingView(context),
            error: (err, _) => _buildErrorView(context, err),
          ),
          loading: () => _buildLoadingView(context),
          error: (err, _) => _buildErrorView(context, err),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color accentColor,
    StorageStats stats,
    StorageAnalysis analysis,
  ) {
    final theme = Theme.of(context);

    final insights = [
      _InsightData(
        icon: Icons.delete_sweep_rounded,
        label: 'Cache folders',
        value: '${analysis.cacheFolders.length}',
        color: Colors.orange,
      ),
      _InsightData(
        icon: Icons.copy_all_rounded,
        label: 'Duplicates',
        value: '${analysis.duplicateFiles.length}',
        color: Colors.purple,
      ),
      _InsightData(
        icon: Icons.sd_storage_rounded,
        label: 'Large files',
        value: '${analysis.largeFiles.length}',
        color: Colors.teal,
      ),
      _InsightData(
        icon: Icons.android_rounded,
        label: 'Old APKs',
        value: '${analysis.oldApks.length}',
        color: Colors.green,
      ),
    ];

    final actions = [
      _CleanActionEntry(
        icon: Icons.delete_outline_rounded,
        color: Colors.orange,
        title: 'Junk files',
        subtitle: '${analysis.cacheFolders.length} cache folders detected',
        detail: analysis.totalJunkSize > 0
            ? _formatBytes(analysis.totalJunkSize)
            : null,
        actionLabel: 'Clean',
        onPressed: () => _showComingSoon(context, 'Cache cleaning'),
      ),
      _CleanActionEntry(
        icon: Icons.copy_rounded,
        color: Colors.purple,
        title: 'Duplicate files',
        subtitle: '${analysis.duplicateFiles.length} duplicate copies found',
        detail: analysis.duplicateFiles.isEmpty
            ? 'Looks good'
            : '${analysis.duplicateFiles.length} items',
        actionLabel: 'Review',
        onPressed: () => _showComingSoon(context, 'Duplicate cleaner'),
      ),
      _CleanActionEntry(
        icon: Icons.sd_storage_rounded,
        color: Colors.teal,
        title: 'Large files',
        subtitle: '${analysis.largeFiles.length} files taking space',
        detail: analysis.largeFiles.isEmpty
            ? 'All clear'
            : '${analysis.largeFiles.length} items',
        actionLabel: 'Organize',
        onPressed: () => _showComingSoon(context, 'Large file cleanup'),
      ),
      _CleanActionEntry(
        icon: Icons.android_rounded,
        color: Colors.green,
        title: 'Old APKs',
        subtitle: '${analysis.oldApks.length} installers detected',
        detail: analysis.oldApks.isEmpty
            ? 'No unused APKs'
            : '${analysis.oldApks.length} files',
        actionLabel: 'Delete',
        onPressed: () => _showComingSoon(context, 'APK cleanup'),
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        _CleanHeader(
          accentColor: accentColor,
          stats: stats,
          onViewDetails: () => showStorageBreakdownSheet(
            context,
            accentColor: accentColor,
            stats: stats,
            focus: StorageMetricFocus.used,
          ),
          onOpenStorage: () {
            _openRootStorage(context);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Insights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: insights
              .map(
                (item) => _InsightChip(
                  icon: item.icon,
                  label: item.label,
                  value: item.value,
                  color: item.color,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 32),
        Text(
          'Recommended actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...actions
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CleanActionCard(entry: entry),
              ),
            )
            .toList(),
        const SizedBox(height: 12),
        _TipsCard(accentColor: accentColor),
      ],
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 120),
      children: const [
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(child: Text('Analyzing storage...')),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Unable to analyze storage:\n$err',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  Future<void> _openRootStorage(BuildContext context) async {
    try {
      final rootPath = await FileService.getPrimaryStoragePath();
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FileListScreen(title: 'Internal storage', path: rootPath),
        ),
      );
    } catch (err) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open storage: $err')));
    }
  }
}

class _CleanHeader extends StatelessWidget {
  final Color accentColor;
  final StorageStats stats;
  final VoidCallback onViewDetails;
  final VoidCallback onOpenStorage;

  const _CleanHeader({
    required this.accentColor,
    required this.stats,
    required this.onViewDetails,
    required this.onOpenStorage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            offset: const Offset(0, 18),
            blurRadius: 38,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage health',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep things tidy with quick cleanup suggestions tailored for your device.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onAccent.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: onAccent.withValues(alpha: 0.18),
                  foregroundColor: onAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onPressed: onViewDetails,
                icon: const Icon(Icons.pie_chart_rounded, size: 18),
                label: const Text('View chart'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: stats.percentUsed.clamp(0, 1)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, value, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(value * 100).clamp(0, 100).toStringAsFixed(0)}% used',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(14),
                  backgroundColor: onAccent.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation(onAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeaderMetric(
                label: 'Used',
                value: stats.usedText,
                foreground: onAccent,
              ),
              const SizedBox(width: 14),
              _HeaderMetric(
                label: 'Free',
                value: stats.freeText,
                foreground: onAccent,
              ),
              const SizedBox(width: 14),
              _HeaderMetric(
                label: 'Total',
                value: stats.totalText,
                foreground: onAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: onAccent,
              side: BorderSide(color: onAccent.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: onOpenStorage,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Browse storage'),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color foreground;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanActionEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? detail;
  final String actionLabel;
  final VoidCallback onPressed;

  const _CleanActionEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
    this.detail,
  });
}

class _CleanActionCard extends StatelessWidget {
  final _CleanActionEntry entry;

  const _CleanActionCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: entry.onPressed,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(entry.icon, color: entry.color, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    if (entry.detail != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        entry.detail!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: entry.onPressed,
                child: Text(entry.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final Color accentColor;

  const _TipsCard({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;
    final tips = const [
      'Clear cache folders from social apps regularly to reclaim space.',
      'Archive large videos you no longer need on-device.',
      'Keep only the latest APK backups to avoid hidden clutter.',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pro tips',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: onAccent.withValues(alpha: 0.85),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onAccent.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final decimals = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}
