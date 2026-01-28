import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/features/file_explorer/file_list_screen.dart';
import 'package:file_explorer_apk/features/settings/settings_screen.dart';
import 'package:file_explorer_apk/providers/storage_provider.dart';
import 'package:file_explorer_apk/widgets/category_grid.dart';
import 'package:file_explorer_apk/widgets/storage_card.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // ignore: unused_result
          await ref.refresh(storageStatsProvider.future);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Storage Card
              const StorageCard(),
              const SizedBox(height: 24),

              // Categories
              Text(
                'Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const CategoryGrid(),
              const SizedBox(height: 24),

              // Quick Access
              Text(
                'Quick access',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildQuickAccess(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Downloads'),
            subtitle: const Text('Downloaded files'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FileListScreen(
                    title: 'Downloads',
                    path: '/storage/emulated/0/Download',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Pictures'),
            subtitle: const Text('Camera photos and screenshots'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FileListScreen(
                    title: 'Pictures',
                    path: '/storage/emulated/0/Pictures',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Movies'),
            subtitle: const Text('Videos and movies'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FileListScreen(
                    title: 'Movies',
                    path: '/storage/emulated/0/Movies',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
