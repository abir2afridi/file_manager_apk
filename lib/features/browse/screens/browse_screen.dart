import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/features/file_explorer/screens/file_list_screen.dart';
import 'package:file_explorer_apk/features/apps/screens/app_list_screen.dart';
import 'package:file_explorer_apk/features/browse/screens/category_file_list_screen.dart';
import 'package:file_explorer_apk/features/search/screens/search_screen.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: FileSearchDelegate());
            },
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(storageStatsProvider.future),
        child: ListView(
          children: [
            _buildCategories(context),
            const Divider(height: 1),
            _buildStorageDevices(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4, // More compact like Google Files
          mainAxisSpacing: 8,
          children: [
            const _CategoryItem(
              icon: Icons.download,
              color: Colors.blue,
              label: 'Downloads',
              type: 'downloads',
            ),
            const _CategoryItem(
              icon: Icons.image,
              color: Colors.purple,
              label: 'Images',
              type: 'images',
            ),
            const _CategoryItem(
              icon: Icons.videocam,
              color: Colors.orange,
              label: 'Videos',
              type: 'videos',
            ),
            const _CategoryItem(
              icon: Icons.audiotrack,
              color: Colors.teal,
              label: 'Audio',
              type: 'audio',
            ),
            const _CategoryItem(
              icon: Icons.description,
              color: Colors.indigo,
              label: 'Docs',
              type: 'documents',
            ),
            const _CategoryItem(
              icon: Icons.android,
              color: Colors.green,
              label: 'APKs',
              type: 'apks',
            ),
            _CategoryItem(
              icon: Icons.apps,
              color: Colors.pink,
              label: 'Apps',
              type: 'apps',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppListScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStorageDevices(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(storageStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Storage devices',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        statsAsync.when(
          data: (stats) {
            final usedGB = (stats.used / 1024).toStringAsFixed(1);
            final totalGB = (stats.total / 1024).toStringAsFixed(1);
            return ListTile(
              leading: const Icon(
                Icons.smartphone,
                color: Colors.blue,
                size: 28,
              ),
              title: const Text(
                'Internal storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$usedGB GB used of $totalGB GB'),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: stats.percentUsed,
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FileListScreen(
                      title: 'Internal storage',
                      path: '/storage/emulated/0',
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading storage info...'),
          ),
          error: (err, stack) =>
              ListTile(title: Text('Error loading storage: $err')),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String type;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CategoryFileListScreen(title: label, type: type),
              ),
            );
          },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25), // replaces withOpacity(0.1)
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
