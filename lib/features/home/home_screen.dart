import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:file_explorer_apk/features/browse/browse_screen.dart';
import 'package:file_explorer_apk/features/clean/clean_screen.dart';
import 'package:file_explorer_apk/features/share/share_screen.dart';
import 'package:file_explorer_apk/widgets/app_navigation_drawer.dart';

// Navigation provider
final navigationIndexProvider = StateProvider<int>((ref) => 1);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final screens = [
      CleanScreen(onOpenDrawer: _openDrawer),
      BrowseScreen(onOpenDrawer: _openDrawer),
      ShareScreen(onOpenDrawer: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppNavigationDrawer(
        onSectionSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: screens[selectedIndex],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cleaning_services_outlined),
            selectedIcon: Icon(Icons.cleaning_services),
            label: 'Clean',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: 'Share',
          ),
        ],
      ),
    );
  }
}
