import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/core/theme/app_theme.dart';
import 'package:file_explorer_apk/features/onboarding/splash_screen.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FileManagerApp(),
    ),
  );
}

class FileManagerApp extends ConsumerWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp(
      title: 'File Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accentColor),
      darkTheme: AppTheme.dark(accentColor),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
