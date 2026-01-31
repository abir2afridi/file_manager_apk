import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperProfileScreen extends StatelessWidget {
  const DeveloperProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Summary'),
                  _buildProfileSummary(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Education'),
                  _buildEducationList(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Skills & Expertise'),
                  _buildSkillsSection(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Personal Traits'),
                  _buildTraitsSection(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Notable Practices'),
                  _buildPracticesSection(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Connect'),
                  _buildContactSection(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                    theme.colorScheme.secondary.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Profile Info
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Abir Hasan Siam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Software Developer • Flutter Specialist',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    final info = [
      {'label': 'Born', 'value': '17 Nov 2002'},
      {'label': 'Age', 'value': '22'},
      {'label': 'Location', 'value': 'Gazipur, BD'},
      {'label': 'Origin', 'value': 'Tangail'},
      {'label': 'Blood', 'value': 'B+'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: info
          .map(
            (item) => _InfoCard(label: item['label']!, value: item['value']!),
          )
          .toList(),
    );
  }

  Widget _buildEducationList(BuildContext context) {
    return Column(
      children: [
        _EducationTile(
          institution: 'Independent University of Bangladesh',
          degree: 'BSc in Computer Science',
          period: '2021 - Present',
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: 12),
        _EducationTile(
          institution: 'Misir Ali Khan Memorial School & College',
          degree: 'Higher Secondary Certificate (HSC)',
          period: '2019 - 2020',
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 12),
        _EducationTile(
          institution: 'Professor MEH Arif Secondary School',
          degree: 'Secondary School Certificate (SSC)',
          period: '2017 - 2018',
          icon: Icons.castle_rounded,
        ),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final skills = [
      {'category': 'Languages', 'list': 'Dart, React, Python'},
      {'category': 'Mobile', 'list': 'Android APK, Flutter'},
      {'category': 'Web', 'list': 'React.js, HTML, CSS, JS'},
      {'category': 'Tools', 'list': 'Windows, Linux, Git, CMake'},
    ];

    return Column(
      children: skills
          .map((s) => _SkillTile(category: s['category']!, items: s['list']!))
          .toList(),
    );
  }

  Widget _buildTraitsSection(BuildContext context) {
    return const Column(
      children: [
        _BulletedText(text: 'Detail-oriented and curious'),
        _BulletedText(
          text: 'Enjoys experimenting with cross-platform solutions',
        ),
        _BulletedText(
          text: 'Likes to keep projects clean, optimized, and professional',
        ),
      ],
    );
  }

  Widget _buildPracticesSection(BuildContext context) {
    return const Column(
      children: [
        _BulletedText(text: 'Maintains clean Flutter project structure'),
        _BulletedText(text: 'Prefers step-by-step technical clarity'),
        _BulletedText(text: 'Strong focus on first-time app launch experience'),
        _BulletedText(text: 'Considers multi-OS compatibility in development'),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            _ContactTile(
              icon: Icons.link_rounded,
              label: 'GitHub',
              value: 'github.com/abir2afridi',
              url: 'https://github.com/abir2afridi',
            ),
            Divider(height: 24),
            _ContactTile(
              icon: Icons.web_rounded,
              label: 'Portfolio',
              value: 'abir2afridi.vercel.app',
              url: 'https://abir2afridi.vercel.app/',
            ),
            Divider(height: 24),
            _ContactTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'abir2afridi@gmail.com',
              url: 'mailto:abir2afridi@gmail.com',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationTile extends StatelessWidget {
  final String institution;
  final String degree;
  final String period;
  final IconData icon;

  const _EducationTile({
    required this.institution,
    required this.degree,
    required this.period,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(degree, style: theme.textTheme.bodySmall),
                Text(
                  period,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

class _SkillTile extends StatelessWidget {
  final String category;
  final String items;
  const _SkillTile({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              category,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(child: Text(items, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _BulletedText extends StatelessWidget {
  final String text;
  const _BulletedText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String url;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
