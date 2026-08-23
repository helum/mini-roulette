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
  });

  final List<RouletteItem> items;
  final double rotation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: CustomPaint(
              size: Size.square(size - 18),
              painter: RouletteWheelPainter(items: items, rotation: rotation),
            ),
          ),
          const PointerMark(),
        ],
      ),
    );
  }
}

class PointerMark extends StatelessWidget {
  const PointerMark({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 34),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 4)
      ..lineTo(size.width, 4)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouletteWheelPainter extends CustomPainter {
  RouletteWheelPainter({required this.items, required this.rotation});

  final List<RouletteItem> items;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final wheelRect = Rect.fromCircle(center: center, radius: radius - 6);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = const Color(0xFF3A2A16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (items.isEmpty) {
      canvas.drawCircle(center, radius - 8, Paint()..color = AppColors.felt);
      return;
    }

    final slices = SpinEngine.sliceGeometry(items);
    for (var i = 0; i < items.length; i++) {
      final slice = slices[i];
      if (slice.sweep <= 0) {
        continue;
      }
      canvas.drawArc(
        wheelRect,
        slice.start + rotation,
        slice.sweep,
        true,
        Paint()..color = items[i].color,
      );
    }

    final divider = Paint()
      ..color = AppColors.washi.withValues(alpha: 0.28)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final slice in slices) {
      final angle = slice.start + rotation;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 6),
        center.dy + math.sin(angle) * (radius - 6),
      );
      canvas.drawLine(center, outer, divider);
    }

    _paintLabels(canvas, center, radius, slices);

    canvas.drawCircle(center, radius * 0.14, Paint()..color = AppColors.ink);
    canvas.drawCircle(
      center,
      radius * 0.14,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(center, radius * 0.045, Paint()..color = AppColors.gold);
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
        center.dx + math.cos(mid) * radius * 0.58,
        center.dy + math.sin(mid) * radius * 0.58,
      );
      final color = items[i].color.computeLuminance() > 0.45
          ? AppColors.ink
          : AppColors.washi;
      final painter = TextPainter(
        text: TextSpan(
          text: items[i].displayLabel,
          style: TextStyle(
            color: color,
            fontSize: slice.sweep > 0.7 ? 15 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.42);
      painter.paint(
        canvas,
        offset - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RouletteWheelPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.items != items;
  }
}
