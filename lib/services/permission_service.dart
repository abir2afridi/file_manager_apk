import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _requestStoragePermissions();
    }
  }

  static Future<bool> _requestStoragePermissions() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ (API 30+) requires MANAGE_EXTERNAL_STORAGE
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      } else {
        // Android 10 and below
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  static Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        return await Permission.manageExternalStorage.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  static Future<bool> requestStoragePermission() async {
    return await _requestStoragePermissions();
  }
}
