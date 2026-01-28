import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/models/file_model.dart';

enum ClipboardAction { move, copy }

class ClipboardData {
  final FileModel file;
  final ClipboardAction action;

  ClipboardData({required this.file, required this.action});
}

class ClipboardNotifier extends StateNotifier<ClipboardData?> {
  ClipboardNotifier() : super(null);

  void copy(FileModel file) {
    state = ClipboardData(file: file, action: ClipboardAction.copy);
  }

  void move(FileModel file) {
    state = ClipboardData(file: file, action: ClipboardAction.move);
  }

  void clear() {
    state = null;
  }
}

final clipboardProvider =
    StateNotifierProvider<ClipboardNotifier, ClipboardData?>((ref) {
      return ClipboardNotifier();
    });
