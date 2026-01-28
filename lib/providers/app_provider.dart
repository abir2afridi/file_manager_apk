import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

final appListProvider = FutureProvider<List<AppInfo>>((ref) async {
  try {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );
    // Sort apps by name
    apps.sort(
      (a, b) => (a.name).toLowerCase().compareTo((b.name).toLowerCase()),
    );
    return apps;
  } catch (e) {
    return [];
  }
});
