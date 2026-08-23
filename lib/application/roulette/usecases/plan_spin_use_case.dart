import 'dart:math';

import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/services/spin_engine.dart';
import 'package:mini_roulette/domain/value_objects/spin_plan.dart';

class PlanSpinUseCase {
  const PlanSpinUseCase();

  SpinPlan call({
    required List<RouletteItem> items,
    required double currentRotation,
    required Random random,
  }) {
    return SpinEngine.planSpin(
      items: items,
      currentRotation: currentRotation,
      random: random,
    );
  }
}
