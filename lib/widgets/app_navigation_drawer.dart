import 'package:flutter/material.dart';
import 'package:file_explorer_apk/features/settings/settings_screen.dart';

class AppNavigationDrawer extends StatelessWidget {
  final ValueChanged<int> onSectionSelected;

  const AppNavigationDrawer({super.key, required this.onSectionSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.folder_copy_rounded,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'File Manager Pro',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Navigate quickly between experiences and settings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerTile(
                    icon: Icons.cleaning_services_rounded,
                    label: 'Clean',
                    subtitle: 'Free up space with one tap',
                    onTap: () => _selectSection(context, 0),
                  ),
                  _DrawerTile(
                    icon: Icons.folder_open_rounded,
                    label: 'Browse',
                    subtitle: 'Explore your storage',
                    onTap: () => _selectSection(context, 1),
                  ),
                  _DrawerTile(
                    icon: Icons.send_rounded,
                    label: 'Share',
                    subtitle: 'Send files instantly',
                    onTap: () => _selectSection(context, 2),
                  ),
                  const Divider(indent: 24, endIndent: 24, height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Preferences',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          'Settings',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Themes, storage preferences, shortcuts',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSection(BuildContext context, int index) {
    Navigator.of(context).pop();
    onSectionSelected(index);
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
