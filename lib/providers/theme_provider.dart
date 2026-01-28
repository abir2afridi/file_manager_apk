import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final accentColorProvider = StateProvider<Color>(
  (ref) => const Color(0xFF1E88E5),
);
