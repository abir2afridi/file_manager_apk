import 'package:flutter/material.dart';

import 'package:file_explorer_apk/features/onboarding/permission_setup_screen.dart';

/// Walkthrough screen shown on first launch.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroPageData> _pages = const [
    _IntroPageData(
      asset: Icons.folder_open_rounded,
      title: 'Browse & Manage Files',
      description:
          'Quickly navigate your phone storage with smart categories and a clean layout.',
    ),
    _IntroPageData(
      asset: Icons.cleaning_services_rounded,
      title: 'Clean Storage & Junk Files',
      description:
          'Reclaim space with smart suggestions for deleting cache, duplicates, and large files.',
    ),
    _IntroPageData(
      asset: Icons.near_me_rounded,
      title: 'Share Files Offline',
      description:
          'Send photos, videos, and documents to nearby devices – no internet required.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == _pages.length - 1) {
      _goToSetup();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PermissionSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _goToSetup,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IntroIllustration(icon: page.asset),
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _DotsIndicator(currentIndex: _currentPage, length: _pages.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _onNext,
                    child: Text(_currentPage == _pages.length - 1 ? 'Done' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPageData {
  final IconData asset;
  final String title;
  final String description;

  const _IntroPageData({
    required this.asset,
    required this.title,
    required this.description,
  });
}

class _IntroIllustration extends StatelessWidget {
  final IconData icon;

  const _IntroIllustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.secondary.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, size: 120, color: theme.colorScheme.primary),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int currentIndex;
  final int length;

  const _DotsIndicator({
    required this.currentIndex,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 22 : 10,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
