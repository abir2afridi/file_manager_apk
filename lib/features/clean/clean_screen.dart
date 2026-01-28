import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';

class CleanScreen extends ConsumerWidget {
  const CleanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clean')),
      body: storageAsync.when(
        data: (storage) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Storage Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: storage.percentUsed,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          storage.percentUsed > 0.8 ? Colors.red : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(storage.percentUsed * 100).toStringAsFixed(1)}% used',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('Clear Cache'),
                      subtitle: const Text('Remove temporary files'),
                      onTap: () {
                        // TODO: Implement cache clearing
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.android),
                      title: const Text('Remove APKs'),
                      subtitle: const Text('Delete old installation files'),
                      onTap: () {
                        // TODO: Implement APK removal
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.folder_delete),
                      title: const Text('Empty Folders'),
                      subtitle: const Text('Remove empty directories'),
                      onTap: () {
                        // TODO: Implement empty folder removal
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
