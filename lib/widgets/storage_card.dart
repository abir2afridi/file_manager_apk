import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';
import 'package:file_explorer_apk/features/file_explorer/file_list_screen.dart';
import 'package:file_explorer_apk/services/file_service.dart';

class StorageCard extends ConsumerWidget {
  const StorageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageStatsProvider);

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final contextMounted = context.mounted;
          try {
            final rootPath = await FileService.getPrimaryStoragePath();
            if (!contextMounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    FileListScreen(title: 'Internal Storage', path: rootPath),
              ),
            );
          } catch (e) {
            if (contextMounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to open storage: $e')),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storage,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Internal Storage',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        storageAsync.when(
                          data: (storage) => Text(
                            '${storage.usedText} used of ${storage.totalText}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          loading: () => Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          error: (_, __) => Text(
                            'Error loading storage info',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  storageAsync.when(
                    data: (storage) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStorageColor(storage.percentUsed),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(storage.percentUsed * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 50,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              storageAsync.when(
                data: (storage) => Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: storage.percentUsed,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStorageColor(storage.percentUsed),
                                  _getStorageColor(
                                    storage.percentUsed,
                                  ).withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStorageInfo(
                          'Used',
                          storage.usedText,
                          Icons.arrow_upward,
                          Colors.orange,
                        ),
                        _buildStorageInfo(
                          'Free',
                          storage.freeText,
                          Icons.arrow_downward,
                          Colors.green,
                        ),
                        _buildStorageInfo(
                          'Total',
                          storage.totalText,
                          Icons.storage,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Unable to load storage information',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStorageColor(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.7) return Colors.orange;
    if (percentage >= 0.5) return Colors.amber;
    return Colors.green;
  }
}
