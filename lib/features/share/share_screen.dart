import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import 'package:file_explorer_apk/providers/theme_provider.dart';

class ShareScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ShareScreen({super.key, this.onOpenDrawer});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  static const XTypeGroup _allFilesTypeGroup = XTypeGroup(
    label: 'All files',
    extensions: <String>[],
  );
  bool _isBusy = false;
  final List<_ShareHistoryEntry> _history = [];

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);
    final theme = Theme.of(context);

    final quickActions = [
      _QuickActionData(
        icon: Icons.upload_file_rounded,
        title: 'Send files',
        subtitle: 'Pick documents, images, and more',
        color: accentColor,
        onTap: () =>
            _runAction(() => _handleSendFiles(target: 'System share sheet')),
      ),
      _QuickActionData(
        icon: Icons.link_rounded,
        title: 'Create link',
        subtitle: 'Generate sharable download links',
        color: Colors.deepPurple,
        onTap: () => _runAction(() => _handleCreateLink(showQr: false)),
      ),
      _QuickActionData(
        icon: Icons.qr_code_rounded,
        title: 'QR transfer',
        subtitle: 'Scan to receive on another device',
        color: Colors.teal,
        onTap: () => _runAction(() => _handleCreateLink(showQr: true)),
      ),
    ];

    final channels = [
      _ShareChannel(
        title: 'Nearby devices',
        description: 'Auto-detect phones and laptops using Wi-Fi Direct.',
        icon: Icons.devices_other_rounded,
        color: Colors.orange,
        onTap: () =>
            _runAction(() => _handleSendFiles(target: 'Nearby devices')),
      ),
      _ShareChannel(
        title: 'Cloud drives',
        description: 'Send items to Google Drive, Dropbox, or OneDrive.',
        icon: Icons.cloud_outlined,
        color: Colors.indigo,
        onTap: () => _runAction(() => _handleSendFiles(target: 'Cloud drive')),
      ),
      _ShareChannel(
        title: 'Messaging apps',
        description: 'Share via WhatsApp, Telegram, or Messages.',
        icon: Icons.chat_bubble_outline_rounded,
        color: Colors.pink,
        onTap: () =>
            _runAction(() => _handleSendFiles(target: 'Messaging apps')),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text('Share'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _ShareHero(
            accentColor: accentColor,
            onSelectFiles: () => _runAction(
              () => _handleSendFiles(target: 'System share sheet'),
            ),
            onViewHistory: _showHistorySheet,
            disabled: _isBusy,
          ),
          const SizedBox(height: 28),
          Text(
            'Quick actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final action in quickActions)
                _QuickActionCard(data: action, disabled: _isBusy),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Share channels',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ...[
            for (final channel in channels)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ChannelCard(channel: channel, disabled: _isBusy),
              ),
          ],
          const SizedBox(height: 12),
          _TipsPanel(accentColor: accentColor),
          const SizedBox(height: 32),
          Text(
            'Recent shares',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your share activity will appear here once you start sending files.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final entry in _history)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryTile(entry),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTile(_ShareHistoryEntry entry) {
    return _HistoryTile(
      entry: entry,
      timestampText: _formatTimestamp(entry.timestamp),
      onCopyLink: entry.link == null ? null : () => _copyLink(entry.link!),
    );
  }

  Future<void> _runAction(Future<void> Function() task) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _handleSendFiles({required String target}) async {
    try {
      final selectedFiles = await openFiles(
        acceptedTypeGroups: const [_allFilesTypeGroup],
      );
      if (selectedFiles.isEmpty) return;

      int totalBytes = 0;
      for (final file in selectedFiles) {
        try {
          totalBytes += await file.length();
        } catch (_) {
          // Ignore files that cannot report length; they still can be shared.
        }
      }

      final label = selectedFiles.length == 1
          ? selectedFiles.first.name
          : '${selectedFiles.length} files';

      await Share.shareXFiles(selectedFiles);

      _addHistoryEntry(
        _ShareHistoryEntry(
          label: label,
          size: _formatBytes(totalBytes),
          target: target,
          status: ShareStatus.completed,
          timestamp: DateTime.now(),
          link: null,
        ),
      );
    } on PlatformException catch (e) {
      _showSnack(e.message ?? 'Permission required to access files.');
    } catch (e) {
      _showSnack('Unable to share files: $e');
      _addHistoryEntry(
        _ShareHistoryEntry(
          label: 'Share attempt',
          size: '\u2014',
          target: target,
          status: ShareStatus.failed,
          timestamp: DateTime.now(),
          link: null,
        ),
      );
    }
  }

  Future<void> _handleCreateLink({required bool showQr}) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [_allFilesTypeGroup],
      );
      if (file == null) return;

      final filePath = file.path;
      final fileName = file.name;
      final fileSize = await File(filePath).length();
      final navigator = Navigator.of(context, rootNavigator: true);
      var dialogShown = false;

      try {
        dialogShown = true;
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _ProgressDialog(message: 'Uploading file...'),
          ),
        );

        final link = await _uploadFileToFileIo(filePath);

        if (dialogShown && navigator.mounted) {
          navigator.pop();
          dialogShown = false;
        }

        if (!mounted) return;

        if (showQr) {
          await _showQrSheet(link, fileName);
        } else {
          await _showLinkSheet(link, fileName);
        }

        _addHistoryEntry(
          _ShareHistoryEntry(
            label: fileName,
            size: _formatBytes(fileSize),
            target: showQr ? 'QR transfer' : 'Share link',
            status: ShareStatus.completed,
            timestamp: DateTime.now(),
            link: link,
          ),
        );
      } catch (e) {
        if (dialogShown && navigator.mounted) {
          navigator.pop();
        }

        _showSnack('Upload failed: $e');
        _addHistoryEntry(
          _ShareHistoryEntry(
            label: fileName,
            size: _formatBytes(fileSize),
            target: showQr ? 'QR transfer' : 'Share link',
            status: ShareStatus.failed,
            timestamp: DateTime.now(),
            link: null,
          ),
        );
      }
    } on PlatformException catch (e) {
      _showSnack(e.message ?? 'Permission required to access files.');
    }
  }

  Future<String> _uploadFileToFileIo(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw 'File no longer exists.';
    }

    final uri = Uri.parse('https://file.io/');
    final request = http.MultipartRequest('POST', uri)
      ..fields['maxDownloads'] = '1'
      ..fields['autoDelete'] = 'true'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          path,
          filename: p.basename(path),
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode})';
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (decoded['success'] != true || decoded['link'] == null) {
      throw decoded['message'] ?? 'Unexpected server response';
    }

    return decoded['link'] as String;
  }

  Future<void> _showLinkSheet(String link, String fileName) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share link ready',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(fileName, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SelectableText(
                link,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _copyLink(link),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Share.share(link, subject: fileName),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share link'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showQrSheet(String link, String fileName) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan to download',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: QrImageView(data: link, size: 220, gapless: true),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                link,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _copyLink(link),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Share.share(link, subject: fileName),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share link'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showHistorySheet() async {
    if (_history.isEmpty) {
      _showSnack('No share activity yet.');
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recent shares',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) =>
                      _buildHistoryTile(_history[index]),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: _history.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addHistoryEntry(_ShareHistoryEntry entry) {
    setState(() {
      _history.insert(0, entry);
      if (_history.length > 20) {
        _history.removeRange(20, _history.length);
      }
    });
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    _showSnack('Link copied to clipboard');
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final decimals = value >= 10 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('MMM d, h:mm a').format(timestamp);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProgressDialog extends StatelessWidget {
  final String message;

  const _ProgressDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareHero extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onSelectFiles;
  final VoidCallback onViewHistory;
  final bool disabled;

  const _ShareHero({
    required this.accentColor,
    required this.onSelectFiles,
    required this.onViewHistory,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.24),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: onAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.near_me_rounded, color: onAccent, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Move files faster',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Beam to nearby devices or share a private download link in seconds.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onAccent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  foregroundColor: onAccent,
                  backgroundColor: onAccent.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: disabled ? null : onSelectFiles,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Select files'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: onAccent,
                  side: BorderSide(color: onAccent.withValues(alpha: 0.45)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: disabled ? null : onViewHistory,
                icon: const Icon(Icons.history_rounded),
                label: const Text('View history'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;
  final bool disabled;

  const _QuickActionCard({required this.data, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : data.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(data.icon, color: data.color),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareChannel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareChannel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ChannelCard extends StatelessWidget {
  final _ShareChannel channel;
  final bool disabled;

  const _ChannelCard({required this.channel, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled ? null : channel.onTap,
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: channel.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(channel.icon, color: channel.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        channel.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipsPanel extends StatelessWidget {
  final Color accentColor;

  const _TipsPanel({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = accentColor.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;
    final tips = const [
      'Keep Bluetooth and Wi‑Fi enabled to discover nearby devices quickly.',
      'Bundle large folders into a ZIP before sharing for faster transfers.',
      'Protect sensitive files with a password before you send them.',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.92), accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sharing tips',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: onAccent.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onAccent.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum ShareStatus { completed, pending, failed }

class _ShareHistoryEntry {
  final String label;
  final String size;
  final String target;
  final ShareStatus status;
  final DateTime timestamp;
  final String? link;

  const _ShareHistoryEntry({
    required this.label,
    required this.size,
    required this.target,
    required this.status,
    required this.timestamp,
    this.link,
  });
}

class _HistoryTile extends StatelessWidget {
  final _ShareHistoryEntry entry;
  final String timestampText;
  final VoidCallback? onCopyLink;

  const _HistoryTile({
    required this.entry,
    required this.timestampText,
    this.onCopyLink,
  });

  Color _statusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (entry.status) {
      case ShareStatus.completed:
        return Colors.green;
      case ShareStatus.pending:
        return colorScheme.primary;
      case ShareStatus.failed:
        return colorScheme.error;
    }
  }

  IconData _statusIcon() {
    switch (entry.status) {
      case ShareStatus.completed:
        return Icons.check_circle_rounded;
      case ShareStatus.pending:
        return Icons.timelapse_rounded;
      case ShareStatus.failed:
        return Icons.error_rounded;
    }
  }

  String _statusLabel() {
    switch (entry.status) {
      case ShareStatus.completed:
        return 'Sent';
      case ShareStatus.pending:
        return 'Pending';
      case ShareStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon(), color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.size} · ${entry.target}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timestampText, style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(
                _statusLabel(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (entry.link != null && onCopyLink != null) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy link'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                    textStyle: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
