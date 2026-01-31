import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';

class FileIcon extends ConsumerWidget {
  final Color baseColor;
  final IconData glyph;
  final double size;

  const FileIcon({
    super.key,
    required this.baseColor,
    required this.glyph,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(folderStyleProvider);

    return CustomPaint(
      size: Size(size, size),
      painter: FileIconPainter(color: baseColor, glyph: glyph, style: style),
    );
  }
}

class FileIconPainter extends CustomPainter {
  final Color color;
  final IconData glyph;
  final FolderStyle style;

  FileIconPainter({
    required this.color,
    required this.glyph,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case FolderStyle.classic:
        _paintClassic(canvas, size);
        break;
      case FolderStyle.solid:
        _paintSolid(canvas, size);
        break;
      case FolderStyle.neon:
        _paintNeon(canvas, size);
        break;
      case FolderStyle.outline:
        _paintOutline(canvas, size);
        break;
    }
  }

  void _paintClassic(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withValues(alpha: 0.8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.9, size.height * 0.25)
      ..lineTo(size.width * 0.9, size.height)
      ..lineTo(size.width * 0.1, size.height)
      ..close();

    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(path, bodyPaint);

    // Folded corner
    final foldPath = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.9, size.height * 0.25)
      ..lineTo(size.width * 0.65, size.height * 0.25)
      ..close();

    canvas.drawPath(
      foldPath,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );

    _paintGlyph(canvas, size, Colors.white.withValues(alpha: 0.9));
  }

  void _paintSolid(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withValues(alpha: 0.85)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      bodyRect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(bodyRect, bodyPaint);

    // Subtle edge highlight
    canvas.drawRRect(
      bodyRect.inflate(-1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.1),
    );

    _paintGlyph(canvas, size, Colors.white.withValues(alpha: 0.95));
  }

  void _paintNeon(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.05);

    canvas.drawRRect(bodyRect, glowPaint);
    canvas.drawRRect(bodyRect, fillPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    _paintGlyph(canvas, size, color);
  }

  void _paintOutline(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.8);

    canvas.drawRRect(bodyRect, paint);
    _paintGlyph(canvas, size, color);
  }

  void _paintGlyph(Canvas canvas, Size size, Color glyphColor) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: size.height * 0.45,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          color: glyphColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final glyphOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, glyphOffset);
  }

  @override
  bool shouldRepaint(covariant FileIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.glyph != glyph ||
        oldDelegate.style != style;
  }
}
