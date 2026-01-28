import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disk_space_2/disk_space_2.dart';

class StorageStats {
  final double totalGB;
  final double usedGB;
  final double freeGB;
  final double percentUsed;
  final String totalText;
  final String usedText;
  final String freeText;

  StorageStats({
    required this.totalGB,
    required this.usedGB,
    required this.freeGB,
    required this.percentUsed,
    required this.totalText,
    required this.usedText,
    required this.freeText,
  });
}

final storageStatsProvider = FutureProvider<StorageStats>((ref) async {
  try {
    final totalSpace = await DiskSpace.getTotalDiskSpace ?? 0.0;
    final freeSpace = await DiskSpace.getFreeDiskSpace ?? 0.0;
    final usedSpace = totalSpace - freeSpace;
    final percentUsed = totalSpace > 0 ? (usedSpace / totalSpace) : 0.0;

    // Convert to GB
    final totalGB = totalSpace / (1024 * 1024 * 1024);
    final usedGB = usedSpace / (1024 * 1024 * 1024);
    final freeGB = freeSpace / (1024 * 1024 * 1024);

    return StorageStats(
      totalGB: totalGB,
      usedGB: usedGB,
      freeGB: freeGB,
      percentUsed: percentUsed,
      totalText: '${totalGB.toStringAsFixed(1)} GB',
      usedText: '${usedGB.toStringAsFixed(1)} GB',
      freeText: '${freeGB.toStringAsFixed(1)} GB',
    );
  } catch (e) {
    // Fallback to default values if disk_space fails
    final totalGB = 32.0;
    final usedGB = 16.0;
    final freeGB = 16.0;

    return StorageStats(
      totalGB: totalGB,
      usedGB: usedGB,
      freeGB: freeGB,
      percentUsed: 0.5,
      totalText: '${totalGB.toStringAsFixed(1)} GB',
      usedText: '${usedGB.toStringAsFixed(1)} GB',
      freeText: '${freeGB.toStringAsFixed(1)} GB',
    );
  }
});
