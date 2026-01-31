import 'package:file_explorer_apk/widgets/folder_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:file_explorer_apk/providers/theme_provider.dart';
import 'package:file_explorer_apk/features/settings/developer_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _buildHeader(context, themeMode, accentColor),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Personalization',
            subtitle: 'Tune File Manager to match your taste.',
            children: [
              _SettingsCard(
                icon: Icons.brightness_6_rounded,
                title: 'Theme mode',
                subtitle: _getThemeLabel(themeMode),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
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
                        ref.read(themeProvider.notifier).update(value);
                      }
                    },
                  ),
                ),
              ),
              _SettingsCard(
                icon: Icons.folder_shared_rounded,
                title: 'Folder design',
                subtitle: 'Choose your preferred iconic style',
                child: _FolderStylePicker(
                  selectedStyle: ref.watch(folderStyleProvider),
                  onStyleSelected: (style) {
                    ref.read(folderStyleProvider.notifier).update(style);
                  },
                ),
              ),
              _AccentPickerCard(
                selectedColor: accentColor,
                onColorSelected: (color) {
                  ref.read(accentColorProvider.notifier).update(color);
                },
              ),
              _SettingsCard(
                icon: Icons.dashboard_customize_rounded,
                title: 'Category design',
                subtitle: 'Customize the look of media categories',
                child: _CategoryDesignPicker(
                  selectedDesign: ref.watch(categoryDesignProvider),
                  onDesignSelected: (design) {
                    ref.read(categoryDesignProvider.notifier).update(design);
                  },
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Storage',
            subtitle: 'Control where downloads land and which folders matter.',
            children: [
              _SettingsCard(
                icon: Icons.storage_rounded,
                title: 'Storage location',
                subtitle: '/storage/emulated/0',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outline,
                ),
                onTap: () => _showComingSoon(context, 'Storage settings'),
              ),
              _SettingsCard(
                icon: Icons.folder_special_rounded,
                title: 'Default folder',
                subtitle: 'Downloads',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outline,
                ),
                onTap: () => _showComingSoon(context, 'Folder picker'),
              ),
            ],
          ),
          const _SettingsSection(
            title: 'File operations',
            subtitle: 'Adjust how browsing and sorting behaves.',
            children: [
              _SettingsCard(
                icon: Icons.visibility_rounded,
                title: 'Show hidden files',
                subtitle: 'Display items starting with a dot',
                trailing: Switch.adaptive(value: false, onChanged: null),
              ),
              _SettingsCard(
                icon: Icons.sort_rounded,
                title: 'Sort folders first',
                subtitle: 'Keep folders above documents in lists',
                trailing: Switch.adaptive(value: true, onChanged: null),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Developer',
            subtitle: 'Get to know the person behind File Manager Pro.',
            children: [
              _SettingsCard(
                icon: Icons.badge_rounded,
                title: 'Developer profile',
                subtitle: 'Abir Hasan Siam • BSc in Computer Science',
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeveloperProfileScreen(),
                    ),
                  );
                },
              ),
              _SettingsCard(
                icon: Icons.web_rounded,
                title: 'Portfolio',
                subtitle: 'abir2afridi.vercel.app',
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () async {
                  final url = Uri.parse('https://abir2afridi.vercel.app/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            subtitle: 'Versioning and policies for transparency.',
            children: [
              const _SettingsCard(
                icon: Icons.info_outline,
                title: 'App version',
                subtitle: '1.0.0',
              ),
              _SettingsCard(
                icon: Icons.code_rounded,
                title: 'Source code',
                subtitle: 'Peek under the hood on GitHub',
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _showComingSoon(context, 'GitHub repository'),
              ),
              _SettingsCard(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                subtitle: 'Understand how your data is handled',
                trailing: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _showComingSoon(context, 'Privacy policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeMode themeMode,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: onAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.folder_copy_rounded,
                  color: onAccent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Manager Pro',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customize your workspace, manage storage, and stay in control.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onAccent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeaderChip(
                icon: Icons.palette_rounded,
                label: 'Theme: ${_getThemeLabel(themeMode)}',
                foreground: onAccent,
                background: onAccent.withValues(alpha: 0.14),
              ),
              _HeaderChip(
                icon: Icons.color_lens_outlined,
                label: 'Accent ready',
                foreground: onAccent,
                background: onAccent.withValues(alpha: 0.14),
              ),
              _HeaderChip(
                icon: Icons.shield_outlined,
                label: 'Privacy conscious',
                foreground: onAccent,
                background: onAccent.withValues(alpha: 0.14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  static String _getThemeLabel(ThemeMode themeMode) {
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      decoration: _settingsCardDecoration(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ],
          ),
          if (child != null) ...[const SizedBox(height: 16), child!],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

class _AccentPickerCard extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _AccentPickerCard({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.palette_rounded,
      title: 'Navigation accent',
      subtitle: 'Applies to the top app bar and highlights',
      child: _NavigationAccentPicker(
        selectedColor: selectedColor,
        onColorSelected: onColorSelected,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: theme.colorScheme.primary),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: foreground),
          ),
        ],
      ),
    );
  }
}

class _ColorPreset {
  final String label;
  final Color color;

  const _ColorPreset(this.label, this.color);

  Color get onColor =>
      color.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}

const List<_ColorPreset> _colorPresets = [
  _ColorPreset('Electric Blue', Color(0xFF1E88E5)),
  _ColorPreset('Royal Indigo', Color(0xFF3949AB)),
  _ColorPreset('Sunset Coral', Color(0xFFF4516C)),
  _ColorPreset('Amber Glow', Color(0xFFFFA000)),
  _ColorPreset('Emerald Tide', Color(0xFF00897B)),
  _ColorPreset('Teal Horizon', Color(0xFF26A69A)),
  _ColorPreset('Plum Wine', Color(0xFF8E24AA)),
  _ColorPreset('Slate Grey', Color(0xFF546E7A)),
];

class _NavigationAccentPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _NavigationAccentPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  Future<void> _pickCustomColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => const _CustomColorPickerDialog(),
    );
    if (color != null) {
      onColorSelected(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPreset = _colorPresets.any((p) => p.color == selectedColor);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: _colorPresets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Custom color picker option
          final isSelected = !isPreset;
          final color = isSelected ? selectedColor : theme.colorScheme.primary;
          final tileBackground = isSelected
              ? color.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHighest;

          return _AccentTile(
            label: 'Custom',
            color: color,
            isSelected: isSelected,
            tileBackground: tileBackground,
            onTap: () => _pickCustomColor(context),
            isCustom: true,
          );
        }

        final preset = _colorPresets[index - 1];
        final isSelected = preset.color == selectedColor;
        final tileBackground = isSelected
            ? preset.color.withValues(alpha: 0.18)
            : theme.colorScheme.surfaceContainerHighest;

        return _AccentTile(
          label: preset.label,
          color: preset.color,
          isSelected: isSelected,
          tileBackground: tileBackground,
          onTap: () => onColorSelected(preset.color),
        );
      },
    );
  }
}

class _AccentTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final Color tileBackground;
  final VoidCallback onTap;
  final bool isCustom;

  const _AccentTile({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.tileBackground,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = color.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: tileBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                gradient: isCustom && !isSelected
                    ? const SweepGradient(
                        colors: [
                          Colors.red,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.red,
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 18, color: onColor)
                  : (isCustom
                        ? const Icon(
                            Icons.colorize,
                            size: 18,
                            color: Colors.white,
                          )
                        : null),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomColorPickerDialog extends StatefulWidget {
  const _CustomColorPickerDialog();

  @override
  State<_CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  double _hue = 200.0;
  double _saturation = 0.8;
  double _lightness = 0.5;

  @override
  Widget build(BuildContext context) {
    final selectedColor = HSLColor.fromAHSL(
      1.0,
      _hue,
      _saturation,
      _lightness,
    ).toColor();

    return AlertDialog(
      title: const Text('Pick custom color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 100,
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: selectedColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Preview',
                style: TextStyle(
                  color: selectedColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Hue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Slider(
            value: _hue,
            min: 0,
            max: 360,
            activeColor: Colors.grey,
            onChanged: (v) => setState(() => _hue = v),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Saturation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Slider(
            value: _saturation,
            onChanged: (v) => setState(() => _saturation = v),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lightness',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Slider(
            value: _lightness,
            onChanged: (v) => setState(() => _lightness = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class _CategoryDesignPicker extends StatelessWidget {
  final CategoryDesign selectedDesign;
  final ValueChanged<CategoryDesign> onDesignSelected;

  const _CategoryDesignPicker({
    required this.selectedDesign,
    required this.onDesignSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: CategoryDesign.values.map((design) {
        final isSelected = design == selectedDesign;
        final String name;
        final IconData icon;

        switch (design) {
          case CategoryDesign.colorful:
            name = 'Vibrant';
            icon = Icons.palette_rounded;
            break;
          case CategoryDesign.minimalist:
            name = 'Clean';
            icon = Icons.layers_rounded;
            break;
          case CategoryDesign.glass:
            name = 'Glass';
            icon = Icons.auto_awesome_motion_rounded;
            break;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDesignSelected(design),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FolderStylePicker extends StatelessWidget {
  final FolderStyle selectedStyle;
  final ValueChanged<FolderStyle> onStyleSelected;

  const _FolderStylePicker({
    required this.selectedStyle,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: FolderStyle.values.map((style) {
        final isSelected = style == selectedStyle;
        final styleName = style.name[0].toUpperCase() + style.name.substring(1);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onStyleSelected(style),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutQuart,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.06)
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: FolderIcon(
                        baseColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        glyph: Icons.folder_rounded,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    styleName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

BoxDecoration _settingsCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    color: theme.colorScheme.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: theme.colorScheme.outlineVariant),
  );
}
