import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Ensures baseline storage/media permissions during app bootstrap.
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    await requestStoragePermission();
  }

  /// Requests the broadest storage access allowed for the current API level.
  ///
  /// * API 33+: falls back to media specific permissions.
  /// * API 30-32: requests MANAGE_EXTERNAL_STORAGE.
  /// * API <= 29: requests READ/WRITE external storage.
  static Future<bool> requestStoragePermission() async {
    final version = await _androidSdkInt();
    if (version == null) {
      return true;
    }

    try {
      if (version >= 33) {
        // Scoped storage only; reuse media granularity helpers.
        return await requestMediaLibraryPermissions();
      }

      if (version >= 30) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      }

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    } catch (e) {
      // ignore: avoid_print
      print('Storage permission error: $e');
      return false;
    }
  }

  /// Checks if the app currently holds storage access matching the API level.
  static Future<bool> hasStoragePermission() async {
    final version = await _androidSdkInt();
    if (version == null) {
      return true;
    }

    if (version >= 33) {
      return await hasMediaLibraryPermissions();
    }

    if (version >= 30) {
      return Permission.manageExternalStorage.isGranted;
    }

    return Permission.storage.isGranted;
  }

  /// Requests granular image/video/audio read permissions required on
  /// Android 13+ while keeping backwards compatibility for older versions.
  static Future<bool> requestMediaLibraryPermissions() async {
    final version = await _androidSdkInt();
    if (version == null) {
      return true;
    }

    try {
      if (version >= 33) {
        final statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        return statuses.values.every((status) => status.isGranted);
      }

      // Prior to API 33, storage permission grants access to all media.
      return await requestStoragePermission();
    } catch (e) {
      // ignore: avoid_print
      print('Media permission error: $e');
      return false;
    }
  }

  /// Returns whether the granular media permissions are already granted.
  static Future<bool> hasMediaLibraryPermissions() async {
    final version = await _androidSdkInt();
    if (version == null) {
      return true;
    }

    if (version >= 33) {
      final photosGranted = await Permission.photos.isGranted;
      final videosGranted = await Permission.videos.isGranted;
      final audioGranted = await Permission.audio.isGranted;
      return photosGranted && videosGranted && audioGranted;
    }

    return await hasStoragePermission();
  }

  /// Convenience helper wrapping [requestMediaLibraryPermissions] that ensures
  /// the permissions are granted before proceeding.
  static Future<bool> ensureMediaLibraryPermissions() async {
    if (await hasMediaLibraryPermissions()) {
      return true;
    }
    return await requestMediaLibraryPermissions();
  }

  static Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final androidInfo = await _deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
}
