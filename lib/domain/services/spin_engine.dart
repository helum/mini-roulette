import 'dart:math' as math;

import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/value_objects/spin_plan.dart';

abstract final class SpinEngine {
  static const twoPi = math.pi * 2;

  /// 12時方向。Canvas の 0 は 3 時なので -π/2。
  static const pointerAngle = -math.pi / 2;

  static double normalize(double angle) {
    var value = angle % twoPi;
    if (value < 0) {
      value += twoPi;
    }
    return value;
  }

  static double totalWeight(List<RouletteItem> items) {
    return items.fold<double>(0, (sum, item) => sum + math.max(item.weight, 0));
  }

  static int pickWeightedIndex(List<RouletteItem> items, math.Random random) {
    final total = totalWeight(items);
    if (items.isEmpty || total <= 0) {
      throw ArgumentError('重みが正の項目が必要です');
    }

    var ticket = random.nextDouble() * total;
    for (var i = 0; i < items.length; i++) {
      ticket -= math.max(items[i].weight, 0);
      if (ticket <= 0) {
        return i;
      }
    }
    return items.length - 1;
  }

  static List<({double start, double sweep})> sliceGeometry(
    List<RouletteItem> items,
  ) {
    final total = totalWeight(items);
    var start = pointerAngle;
    final slices = <({double start, double sweep})>[];
    for (final item in items) {
      final sweep = total <= 0
          ? 0.0
          : (math.max(item.weight, 0) / total) * twoPi;
      slices.add((start: start, sweep: sweep));
      start += sweep;
    }
    return slices;
  }

  static bool _containsAngle(double start, double sweep, double angle) {
    if (sweep <= 0) {
      return false;
    }
    final origin = normalize(start);
    final point = normalize(angle);
    final end = origin + sweep;
    if (end <= twoPi) {
      return point >= origin && point < end;
    }
    return point >= origin || point < (end - twoPi);
  }

  static int indexAtPointer(List<RouletteItem> items, double rotation) {
    final slices = sliceGeometry(items);
    final localPointer = pointerAngle - rotation;
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      if (_containsAngle(slice.start, slice.sweep, localPointer)) {
        return i;
      }
    }
    return items.isEmpty ? -1 : items.length - 1;
  }

  static SpinPlan planSpin({
    required List<RouletteItem> items,
    required double currentRotation,
    required math.Random random,
  }) {
    final winnerIndex = pickWeightedIndex(items, random);
    final slices = sliceGeometry(items);
    final slice = slices[winnerIndex];

    final inset = slice.sweep < 0.12 ? slice.sweep / 2 : slice.sweep * 0.18;
    final usable = math.max(slice.sweep - inset * 2, 0.0);
    final offset = usable == 0
        ? slice.sweep / 2
        : inset + random.nextDouble() * usable;
    final targetLocal = slice.start + offset;

    final targetRotation = pointerAngle - targetLocal;
    final currentMod = normalize(currentRotation);
    final targetMod = normalize(targetRotation);
    var delta = targetMod - currentMod;
    if (delta < 0) {
      delta += twoPi;
    }

    final extraTurns = 4 + random.nextInt(3);
    final endRotation = currentRotation + extraTurns * twoPi + delta;
    return SpinPlan(winnerIndex: winnerIndex, endRotation: endRotation);
  }
}
