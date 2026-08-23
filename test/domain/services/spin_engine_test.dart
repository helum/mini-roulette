import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/services/spin_engine.dart';

void main() {
  List<RouletteItem> items({
    List<double> weights = const [1, 1, 1, 1],
  }) {
    return [
      for (var i = 0; i < weights.length; i++)
        RouletteItem(
          id: 'i$i',
          label: '項目$i',
          colorValue: 0xFF000000,
          weight: weights[i],
        ),
    ];
  }

  test('planSpin の停止位置は当選扇に入る', () {
    final random = Random(7);
    final source = items(weights: const [1, 3, 1, 5]);

    for (var i = 0; i < 200; i++) {
      final plan = SpinEngine.planSpin(
        items: source,
        currentRotation: i * 0.37,
        random: random,
      );
      expect(plan.winnerIndex, inInclusiveRange(0, source.length - 1));
      expect(
        SpinEngine.indexAtPointer(source, plan.endRotation),
        plan.winnerIndex,
      );
    }
  });

  test('重みが大きい項目がより多く選ばれる', () {
    final random = Random(3);
    final source = items(weights: const [1, 9]);
    var second = 0;
    const n = 400;
    for (var i = 0; i < n; i++) {
      final index = SpinEngine.pickWeightedIndex(source, random);
      if (index == 1) {
        second++;
      }
    }
    expect(second, greaterThan(280));
  });

  test('扇の角度は重みに比例する', () {
    final source = items(weights: const [1, 3]);
    final slices = SpinEngine.sliceGeometry(source);
    expect(slices[1].sweep, closeTo(slices[0].sweep * 3, 1e-9));
    expect(slices[0].sweep + slices[1].sweep, closeTo(SpinEngine.twoPi, 1e-9));
  });
}
