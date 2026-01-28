import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/core/theme/app_theme.dart';
import 'package:file_explorer_apk/features/home/home_screen.dart';
import 'package:file_explorer_apk/services/permission_service.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize permissions
  await PermissionService.initialize();

  runApp(const ProviderScope(child: FileManagerApp()));
}

class FileManagerApp extends ConsumerWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'File Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
