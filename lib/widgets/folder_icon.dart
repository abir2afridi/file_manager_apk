import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_explorer_apk/providers/theme_provider.dart';

class FolderIcon extends ConsumerWidget {
  final Color baseColor;
  final IconData glyph;
  final double size;

  const FolderIcon({
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
      painter: FolderIconPainter(color: baseColor, glyph: glyph, style: style),
    );
  }
}

class FolderIconPainter extends CustomPainter {
  final Color color;
  final IconData glyph;
  final FolderStyle style;

  FolderIconPainter({
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

    final flapRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(2, 0, size.width * 0.4, size.height * 0.4),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(flapRect, bodyPaint);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.75),
      const Radius.circular(6),
    );

    // Dynamic depth shadow
    canvas.drawRRect(
      bodyRect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(bodyRect, bodyPaint);

    _paintGlyph(canvas, size, Colors.white.withValues(alpha: 0.9));
  }

  void _paintSolid(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withValues(alpha: 0.85)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final flapRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(size.width * 0.05, 0, size.width * 0.45, size.height * 0.4),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.28, size.width, size.height * 0.72),
      const Radius.circular(12),
    );

    canvas.drawRRect(flapRect, bodyPaint);

    canvas.drawRRect(
      bodyRect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(bodyRect, bodyPaint);
    _paintGlyph(canvas, size, Colors.white.withValues(alpha: 0.95));
  }

  void _paintNeon(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7),
      const Radius.circular(12),
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

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
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7),
      const Radius.circular(14),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.82);

    canvas.drawRRect(bodyRect, paint);

    final tabPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.31)
      ..lineTo(size.width * 0.1, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.1,
        size.width * 0.2,
        size.height * 0.1,
      )
      ..lineTo(size.width * 0.4, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width * 0.5,
        size.height * 0.2,
      )
      ..lineTo(size.width * 0.5, size.height * 0.31);

    canvas.drawPath(tabPath, paint);

    _paintGlyph(canvas, size, color);
  }

  void _paintGlyph(Canvas canvas, Size size, Color glyphColor) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: size.height * 0.36,
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
      (size.height * 0.3) + (size.height * 0.7 - textPainter.height) / 2,
    );
    textPainter.paint(canvas, glyphOffset);
  }

  @override
  bool shouldRepaint(covariant FolderIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.glyph != glyph ||
        oldDelegate.style != style;
  }
}
