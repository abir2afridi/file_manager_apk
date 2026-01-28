import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';

class CleanScreen extends ConsumerWidget {
  const CleanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(storageStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clean')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          statsAsync.when(
            data: (stats) => Column(
              children: [
                _buildStorageCard(context, stats),
                const SizedBox(height: 16),
                _buildCleanSection(
                  context,
                  title: 'Junk files',
                  subtitle:
                      '${stats.analysis.cacheFolders.length} cache folders detected',
                  icon: Icons.delete_outline,
                  actionLabel: 'Clean',
                  onTap: () {
                    // Logic to delete cache folders
                  },
                ),
                const SizedBox(height: 16),
                _buildCleanSection(
                  context,
                  title: 'Duplicate files',
                  subtitle:
                      '${stats.analysis.duplicateFiles.length} duplicates found',
                  icon: Icons.copy,
                  actionLabel: 'View',
                  onTap: () {
                    // Navigate to duplicates view
                  },
                ),
                const SizedBox(height: 16),
                _buildCleanSection(
                  context,
                  title: 'Large files',
                  subtitle:
                      '${stats.analysis.largeFiles.length} files taking up space',
                  icon: Icons.insert_drive_file_outlined,
                  actionLabel: 'Select and free up',
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildCleanSection(
                  context,
                  title: 'Old APKs',
                  subtitle: '${stats.analysis.oldApks.length} APK files',
                  icon: Icons.android,
                  actionLabel: 'Delete',
                  onTap: () {},
                ),
              ],
            ),
            loading: () => const Center(
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
            ),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, StorageStats stats) {
    final usedGB = (stats.used / 1024).toStringAsFixed(1);
    final totalGB = (stats.total / 1024).toStringAsFixed(1);
    final percent = (stats.percentUsed * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Storage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$percent% used',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.percentUsed,
              backgroundColor: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('$usedGB GB used'), Text('$totalGB GB total')],
            ),
          ],
        ),
      ),
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withAlpha(25),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
      ),
    );
  }
}
