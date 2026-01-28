import 'package:flutter/material.dart';
import 'package:file_explorer_apk/features/browse/screens/category_file_list_screen.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _CategoryItem(
          icon: Icons.image,
          color: Colors.blue,
          label: 'Images',
          type: 'images',
        ),
        _CategoryItem(
          icon: Icons.videocam,
          color: Colors.red,
          label: 'Videos',
          type: 'videos',
        ),
        _CategoryItem(
          icon: Icons.audiotrack,
          color: Colors.green,
          label: 'Audio',
          type: 'audio',
        ),
        _CategoryItem(
          icon: Icons.description,
          color: Colors.orange,
          label: 'Documents',
          type: 'documents',
        ),
        _CategoryItem(
          icon: Icons.android,
          color: Colors.purple,
          label: 'APKs',
          type: 'apks',
        ),
        _CategoryItem(
          icon: Icons.download,
          color: Colors.teal,
          label: 'Downloads',
          type: 'downloads',
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

  const _CategoryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CategoryFileListScreen(title: label, type: type),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
