import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/features/apps/screens/app_list_screen.dart';
import 'package:file_explorer_apk/features/browse/screens/category_file_list_screen.dart';
import 'package:file_explorer_apk/features/file_explorer/screens/file_list_screen.dart';
import 'package:file_explorer_apk/features/zip/screens/zip_tool_screen.dart';
import 'package:file_explorer_apk/features/search/screens/search_screen.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';
import 'package:file_explorer_apk/services/file_service.dart';
import 'package:file_explorer_apk/widgets/storage_breakdown_sheet.dart';

class BrowseScreen extends ConsumerWidget {
  final VoidCallback? onOpenDrawer;

  const BrowseScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final statsAsync = ref.watch(storageStatsProvider);

    Future<void> openStorageRoot() async {
      try {
        final rootPath = await FileService.getPrimaryStoragePath();
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FileListScreen(title: 'Internal storage', path: rootPath),
          ),
        );
      } catch (err) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open storage: $err')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onOpenDrawer,
              )
            : null,
        title: const Text('Browse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(context: context, delegate: FileSearchDelegate());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(storageStatsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _BrowseHeader(
              accentColor: accentColor,
              statsAsync: statsAsync,
              onOpenStorage: openStorageRoot,
            ),
            const SizedBox(height: 24),
            const _BrowseSection(
              title: 'Categories',
              subtitle: 'Hop into media types and dedicated spaces.',
              child: _CategoryGrid(),
            ),
            const SizedBox(height: 24),
            const _BrowseSection(
              title: 'Quick access',
              subtitle: 'Favorites we keep within arm’s reach.',
              child: _QuickAccessList(),
            ),
            const SizedBox(height: 24),
            const _BrowseSection(
              title: 'Tools & insights',
              subtitle: 'Launch shortcuts that help you stay organized.',
              child: _ToolGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  final Color accentColor;
  final AsyncValue<StorageStats> statsAsync;
  final Future<void> Function() onOpenStorage;

  const _BrowseHeader({
    required this.accentColor,
    required this.statsAsync,
    required this.onOpenStorage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => onOpenStorage(),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onAccent.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -36,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: onAccent.withValues(alpha: 0.08),
                      width: 2,
                    ),
                  ),
                ),
              ),
              statsAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your storage at a glance',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: onAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Quick overview of used, free, and total capacity in your device.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onAccent.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.storage_rounded,
                              color: onAccent,
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: onAccent.withValues(
                                  alpha: 0.16,
                                ),
                                foregroundColor: onAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: onOpenStorage,
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                size: 18,
                              ),
                              label: const Text('Open storage'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: stats.percentUsed.clamp(0, 1),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(16),
                      backgroundColor: onAccent.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(onAccent),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StorageMetric(
                          label: 'Used',
                          value: stats.usedText,
                          icon: Icons.arrow_upward_rounded,
                          foreground: onAccent,
                          onTap: () => showStorageBreakdownSheet(
                            context,
                            accentColor: accentColor,
                            stats: stats,
                            focus: StorageMetricFocus.used,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _StorageMetric(
                          label: 'Free',
                          value: stats.freeText,
                          icon: Icons.arrow_downward_rounded,
                          foreground: onAccent,
                          onTap: () => showStorageBreakdownSheet(
                            context,
                            accentColor: accentColor,
                            stats: stats,
                            focus: StorageMetricFocus.free,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _StorageMetric(
                          label: 'Total',
                          value: stats.totalText,
                          icon: Icons.data_usage_rounded,
                          foreground: onAccent,
                          onTap: () => showStorageBreakdownSheet(
                            context,
                            accentColor: accentColor,
                            stats: stats,
                            focus: StorageMetricFocus.total,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to explore your storage folders and manage files faster.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                loading: () => SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(color: onAccent),
                  ),
                ),
                error: (err, _) => SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Unable to load storage info\n$err',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color foreground;
  final VoidCallback onTap;

  const _StorageMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 18),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _BrowseSection({
    required this.title,
    required this.subtitle,
    required this.child,
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
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(categoryDesignProvider);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.85,
      ),
      itemCount: _categoryItems.length,
      itemBuilder: (context, index) {
        return _CategoryTile(data: _categoryItems[index], design: design);
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryItemData data;
  final CategoryDesign design;

  const _CategoryTile({required this.data, required this.design});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color backgroundColor;
    final Border border;

    switch (design) {
      case CategoryDesign.colorful: // Vibrant
        backgroundColor = data.color.withValues(alpha: 0.1);
        border = Border.all(color: theme.colorScheme.outlineVariant);
        break;
      case CategoryDesign.minimalist: // Clean
        backgroundColor = Colors.transparent;
        border = Border.all(color: theme.colorScheme.outlineVariant);
        break;
      case CategoryDesign.glass:
        backgroundColor = data.color.withValues(alpha: 0.06);
        border = Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        );
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => data.onTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: border,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      data.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessList extends StatelessWidget {
  const _QuickAccessList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _quickLinks.length; i++) ...[
          _QuickAccessTile(data: _quickLinks[i]),
          if (i != _quickLinks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final _QuickLinkData data;

  const _QuickAccessTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final path = await data.resolvePath();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FileListScreen(title: data.title, path: path),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => tool.onTap(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tool.icon, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tool.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickLinkData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<String> Function() _resolver;

  const _QuickLinkData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required Future<String> Function() resolver,
  }) : _resolver = resolver;

  Future<String> resolvePath() => _resolver();
}

class _ToolData {
  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext context) onTap;

  const _ToolData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

final List<_QuickLinkData> _quickLinks = [
  _QuickLinkData(
    icon: Icons.download_done_rounded,
    title: 'Downloads',
    subtitle: 'Recently saved items',
    resolver: () => Future.value('/storage/emulated/0/Download'),
  ),
  _QuickLinkData(
    icon: Icons.image_outlined,
    title: 'DCIM',
    subtitle: 'Camera photos and screenshots',
    resolver: () => Future.value('/storage/emulated/0/DCIM'),
  ),
  _QuickLinkData(
    icon: Icons.movie_creation_outlined,
    title: 'Movies',
    subtitle: 'Offline videos and films',
    resolver: () => Future.value('/storage/emulated/0/Movies'),
  ),
  _QuickLinkData(
    icon: Icons.folder_shared_outlined,
    title: 'ShareIt',
    subtitle: 'Files received from others',
    resolver: () => Future.value('/storage/emulated/0/ShareIt'),
  ),
];

final List<_ToolData> _tools = [
  _ToolData(
    icon: Icons.apps_rounded,
    title: 'Installed apps',
    subtitle: 'View APKs and manage packages',
    onTap: (context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppListScreen()),
      );
    },
  ),
  _ToolData(
    icon: Icons.storage_rounded,
    title: 'Storage cleaner',
    subtitle: 'Identify large or duplicate files',
    onTap: (context) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage cleaner is coming soon.')),
      );
    },
  ),
  _ToolData(
    icon: Icons.folder_zip_rounded,
    title: 'ZIP toolkit',
    subtitle: 'Compress or extract archives',
    onTap: (context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ZipToolScreen()),
      );
    },
  ),
];

final List<_CategoryItemData> _categoryItems = [
  _CategoryItemData(
    label: 'Downloads',
    icon: Icons.download_rounded,
    color: Colors.blue,
    description: 'Recently saved items and offline files.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'Downloads', type: 'downloads'),
  ),
  _CategoryItemData(
    label: 'Images',
    icon: Icons.image_rounded,
    color: Colors.purple,
    description: 'Memories, screenshots, and edits.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'Images', type: 'images'),
  ),
  _CategoryItemData(
    label: 'Videos',
    icon: Icons.videocam_rounded,
    color: Colors.orange,
    description: 'Movies, reels, and screen recordings.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'Videos', type: 'videos'),
  ),
  _CategoryItemData(
    label: 'Audio',
    icon: Icons.audiotrack_rounded,
    color: Colors.teal,
    description: 'Voice notes, music, and podcasts.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'Audio', type: 'audio'),
  ),
  _CategoryItemData(
    label: 'Documents',
    icon: Icons.description_rounded,
    color: Colors.indigo,
    description: 'PDFs, sheets, and office files.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'Documents', type: 'documents'),
  ),
  _CategoryItemData(
    label: 'APKs',
    icon: Icons.android_rounded,
    color: Colors.green,
    description: 'Installation packages and backups.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'APKs', type: 'apks'),
  ),
  _CategoryItemData(
    label: 'Archives',
    icon: Icons.folder_zip_rounded,
    color: Colors.deepOrange,
    description: 'Zip, Rar, and compressed folders.',
    routeBuilder: () =>
        const CategoryFileListScreen(title: 'Archives', type: 'archives'),
  ),
  _CategoryItemData(
    label: 'Apps',
    icon: Icons.apps_rounded,
    color: Colors.pink,
    description: 'Manage installed packages quickly.',
    routeBuilder: () => const AppListScreen(),
  ),
];

class _CategoryItemData {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final Widget Function() routeBuilder;

  const _CategoryItemData({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.routeBuilder,
  });

  void onTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => routeBuilder()));
  }
}
