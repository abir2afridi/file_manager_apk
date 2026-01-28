import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/app_provider.dart';
import 'package:installed_apps/installed_apps.dart';

class AppListScreen extends ConsumerWidget {
  const AppListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(appListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apps')),
      body: appsAsync.when(
        data: (apps) => ListView.builder(
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return ListTile(
              leading: app.icon != null
                  ? Image.memory(app.icon!, width: 40, height: 40)
                  : const Icon(Icons.android, size: 40),
              title: Text(app.name),
              subtitle: Text(app.packageName),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  InstalledApps.uninstallApp(app.packageName);
                },
              ),
              onTap: () {
                InstalledApps.startApp(app.packageName);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
