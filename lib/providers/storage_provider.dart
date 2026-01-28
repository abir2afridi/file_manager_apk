import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:file_explorer_apk/services/storage_service.dart';

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

final storageAnalysisProvider = FutureProvider<StorageAnalysis>((ref) async {
  return StorageService.analyzeStorage();
});

const MethodChannel _storageChannel = MethodChannel(
  'com.abir.file_manager/storage',
);

final storageStatsProvider = FutureProvider<StorageStats>((ref) async {
  try {
    final stats = await _storageChannel.invokeMapMethod<String, dynamic>(
      'getStorageInfo',
    );
    if (stats != null && stats.isNotEmpty) {
      final totalBytes = (stats['total'] as num?)?.toDouble() ?? 0.0;
      final freeBytes = (stats['free'] as num?)?.toDouble() ?? 0.0;
      final usedBytes =
          (stats['used'] as num?)?.toDouble() ?? (totalBytes - freeBytes);

      return _buildStatsFromBytes(totalBytes, usedBytes, freeBytes);
    }
    // Fallback to plugin values if platform channel returned nothing
    return await _fetchStatsFromDiskSpace();
  } catch (e) {
    // Fallback to plugin values if either channel call failed or threw
    try {
      return await _fetchStatsFromDiskSpace();
    } catch (_) {
      // Final fallback to default mock data
      const totalGB = 32.0;
      const usedGB = 16.0;
      const freeGB = 16.0;

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
  }
});

Future<StorageStats> _fetchStatsFromDiskSpace() async {
  final totalSpaceMb = await DiskSpace.getTotalDiskSpace ?? 0.0;
  final freeSpaceMb = await DiskSpace.getFreeDiskSpace ?? 0.0;
  final usedSpaceMb = totalSpaceMb - freeSpaceMb;

  final totalSpace = totalSpaceMb <= 0 ? 0.0 : totalSpaceMb;
  final freeSpace = freeSpaceMb <= 0 ? 0.0 : freeSpaceMb.clamp(0, totalSpace);
  final usedSpace = usedSpaceMb < 0 ? 0.0 : usedSpaceMb;

  // disk_space_2 returns values in MB, convert to bytes first
  const bytesPerMb = 1024.0 * 1024.0;
  final totalBytes = totalSpace * bytesPerMb;
  final usedBytes = usedSpace * bytesPerMb;
  final freeBytes = freeSpace * bytesPerMb;

  return _buildStatsFromBytes(totalBytes, usedBytes, freeBytes);
}

StorageStats _buildStatsFromBytes(
  double totalBytes,
  double usedBytes,
  double freeBytes,
) {
  final sanitizedTotal = totalBytes <= 0 ? 0.0 : totalBytes;
  final sanitizedFree = freeBytes.clamp(0, sanitizedTotal);
  final sanitizedUsed = usedBytes < 0
      ? sanitizedTotal - sanitizedFree
      : usedBytes;

  const bytesPerGb = 1024.0 * 1024.0 * 1024.0;
  final totalGB = sanitizedTotal / bytesPerGb;
  final usedGB = sanitizedUsed / bytesPerGb;
  final freeGB = sanitizedFree / bytesPerGb;
  final percentUsed = sanitizedTotal > 0 ? sanitizedUsed / sanitizedTotal : 0.0;

  return StorageStats(
    totalGB: totalGB,
    usedGB: usedGB,
    freeGB: freeGB,
    percentUsed: percentUsed,
    totalText: '${totalGB.toStringAsFixed(1)} GB',
    usedText: '${usedGB.toStringAsFixed(1)} GB',
    freeText: '${freeGB.toStringAsFixed(1)} GB',
  );
}
