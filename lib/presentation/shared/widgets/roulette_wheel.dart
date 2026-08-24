import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/services/spin_engine.dart';
import 'package:mini_roulette/presentation/shared/roulette_item_color.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';

class RouletteWheel extends StatelessWidget {
  const RouletteWheel({
    super.key,
    required this.items,
    required this.rotation,
    this.size = 320,
    this.showPointer = true,
    this.showLabels = true,
  });

  final List<RouletteItem> items;
  final double rotation;
  final double size;
  final bool showPointer;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final pointerWidth = size * 0.09;
    final pointerHeight = size * 0.12;
    final overhang = showPointer ? pointerHeight * 0.38 : 0.0;
    final visualRotation = showPointer ? rotation : rotation - 0.62;

    return SizedBox(
      width: size,
      height: size + overhang,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: overhang,
            child: _EnamelDisc(
              size: size,
              items: items,
              rotation: visualRotation,
              showLabels: showLabels,
              lifted: showPointer,
            ),
          ),
          if (showPointer)
            PointerMark(width: pointerWidth, height: pointerHeight),
        ],
      ),
    );
  }
}

class _EnamelDisc extends StatelessWidget {
  const _EnamelDisc({
    required this.size,
    required this.items,
    required this.rotation,
    required this.showLabels,
    required this.lifted,
  });

  final double size;
  final List<RouletteItem> items;
  final double rotation;
  final bool showLabels;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: lifted ? 0.08 : 0.06),
            blurRadius: lifted ? 32 : 14,
            offset: Offset(0, lifted ? 14 : 5),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: RouletteWheelPainter(
          items: items,
          rotation: rotation,
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class PointerMark extends StatelessWidget {
  const PointerMark({super.key, this.width = 28, this.height = 34});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h)
      ..quadraticBezierTo(0, h * 0.48, w * 0.18, h * 0.28)
      ..arcToPoint(
        Offset(w * 0.82, h * 0.28),
        radius: Radius.circular(w * 0.34),
      )
      ..quadraticBezierTo(w, h * 0.48, w / 2, h)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.play
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(w / 2, h * 0.3),
      w * 0.16,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouletteWheelPainter extends CustomPainter {
  RouletteWheelPainter({
    required this.items,
    required this.rotation,
    this.showLabels = true,
  });

  final List<RouletteItem> items;
  final double rotation;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    canvas.drawCircle(center, radius, Paint()..color = AppColors.surface);

    if (items.isEmpty) {
      canvas.drawCircle(
        center,
        radius * 0.78,
        Paint()
          ..color = AppColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    final slices = SpinEngine.sliceGeometry(items);
    final sliceRadius = radius * 0.86;
    final wheelRect = Rect.fromCircle(center: center, radius: sliceRadius);

    for (var i = 0; i < items.length; i++) {
      final slice = slices[i];
      final gap = items.length > 1 && slice.sweep > 0.08 ? 0.016 : 0.0;
      final sweep = slice.sweep - gap;
      if (sweep <= 0) {
        continue;
      }
      canvas.drawArc(
        wheelRect,
        slice.start + rotation + gap / 2,
        sweep,
        true,
        Paint()..color = items[i].color,
      );
    }

    if (showLabels) {
      _paintLabels(canvas, center, radius, slices);
    }

    canvas.drawCircle(center, radius * 0.16, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      center,
      radius * 0.045,
      Paint()..color = AppColors.line,
    );
  }

  void _paintLabels(
    Canvas canvas,
    Offset center,
    double radius,
    List<({double start, double sweep})> slices,
  ) {
    for (var i = 0; i < items.length; i++) {
      final slice = slices[i];
      if (slice.sweep < 0.22) {
        continue;
      }
      final mid = slice.start + slice.sweep / 2 + rotation;
      final offset = Offset(
        center.dx + math.cos(mid) * radius * 0.52,
        center.dy + math.sin(mid) * radius * 0.52,
      );
      final color = items[i].color.computeLuminance() > 0.55
          ? AppColors.ink
          : const Color(0xFFFFFFFF);
      final painter = TextPainter(
        text: TextSpan(
          text: items[i].displayLabel,
          style: TextStyle(
            color: color,
            fontSize: slice.sweep > 0.7 ? 14 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.4);
      painter.paint(
        canvas,
        offset - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RouletteWheelPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.items != items ||
        oldDelegate.showLabels != showLabels;
  }
}
