import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';
import 'package:file_explorer_apk/services/storage_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CleanScreen extends ConsumerWidget {
  const CleanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(storageStatsProvider);
    final analysisAsync = ref.watch(storageAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          statsAsync.when(
            data: (stats) => analysisAsync.when(
              data: (analysis) => _buildCleanContent(context, stats, analysis),
              loading: () => _buildLoadingState(),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            loading: () => _buildLoadingState(),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing storage...'),
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
    return Column(
      children: [
        _buildStorageCard(context, stats),
        const SizedBox(height: 24),
        _buildCleanSection(
          context,
          title: 'Junk files',
          subtitle: '${analysis.cacheFolders.length} cache folders detected',
          icon: Icons.delete_outline,
          actionLabel: 'Clean',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache cleaning coming soon.')),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Duplicate files',
          subtitle: '${analysis.duplicateFiles.length} duplicates found',
          icon: Icons.copy,
          actionLabel: 'View',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Duplicate viewer coming soon.')),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Large files',
          subtitle: '${analysis.largeFiles.length} files taking up space',
          icon: Icons.insert_drive_file_outlined,
          actionLabel: 'Select and free up',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Large file cleanup coming soon.')),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildCleanSection(
          context,
          title: 'Old APKs',
          subtitle: '${analysis.oldApks.length} APK files',
          icon: Icons.android,
          actionLabel: 'Delete',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('APK cleanup coming soon.')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStorageCard(BuildContext context, StorageStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (stats.percentUsed * 100).toStringAsFixed(0);

    return OpenContainer(
      closedElevation: 0,
      openElevation: 4,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      closedBuilder: (context, action) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Storage',
                      style: GoogleFonts.getFont(
                        'Lato',
                        textStyle: theme.textTheme.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$percent% used',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(
                    begin: 0,
                    end: stats.percentUsed,
                  ),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${stats.usedText} used'),
                    Text('${stats.totalText} total'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      openBuilder: (context, action) {
        return const Scaffold(
          body: Center(
            child: Text('Storage details coming soon'),
          ),
        );
      },
    );
  }

  Widget _buildCleanSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
      ),
    );
  }
}
