import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance Section
          _buildSection(
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Theme'),
                subtitle: Text(_getThemeLabel(themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).state = value;
                    }
                  },
                ),
              ),
            ],
          ),

          // Storage Section
          _buildSection(
            title: 'Storage',
            children: [
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Storage Location'),
                subtitle: const Text('/storage/emulated/0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to storage settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_special),
                title: const Text('Default Folder'),
                subtitle: const Text('Downloads'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to folder selection
                },
              ),
            ],
          ),

          // File Operations Section
          _buildSection(
            title: 'File Operations',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text('Show Hidden Files'),
                subtitle: const Text(
                  'Display files and folders starting with .',
                ),
                value: false, // TODO: Add to settings
                onChanged: (value) {
                  // TODO: Implement hidden files toggle
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.sort),
                title: const Text('Sort Folders First'),
                subtitle: const Text('Show folders before files'),
                value: true, // TODO: Add to settings
                onChanged: (value) {
                  // TODO: Implement sort preference
                },
              ),
            ],
          ),

          // Developer Information Section
          _buildSection(
            title: 'Developer Information',
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Developer'),
                subtitle: const Text('Abir Afridi'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                subtitle: const Text('Bangladesh'),
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('University'),
                subtitle: const Text(
                  'Independent University, Bangladesh (IUB)',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Tech Stack'),
                subtitle: const Text('Flutter, Dart, React, Firebase'),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Languages'),
                subtitle: const Text('Bangla (Primary), English'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Blood Group'),
                subtitle: const Text('B+'),
              ),
              ListTile(
                leading: const Icon(Icons.web),
                title: const Text('Website'),
                subtitle: const Text('abir2afridi.vercel.app'),
                trailing: const Icon(Icons.launch),
                onTap: () async {
                  final url = Uri.parse('https://abir2afridi.vercel.app/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Status'),
                subtitle: const Text('Always learning. Always improving.'),
              ),
            ],
          ),

          // About Section
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source Code'),
                subtitle: const Text('View on GitHub'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Open GitHub link
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getThemeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
