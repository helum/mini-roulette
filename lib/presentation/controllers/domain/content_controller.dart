import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/application/roulette/usecases/add_roulette_item_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/create_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/delete_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/plan_spin_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/save_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/watch_roulettes_use_case.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/domain/value_objects/spin_plan.dart';

final roulettesRepositoryProvider = Provider<RoulettesRepository>((ref) {
  throw UnimplementedError(
    'roulettesRepositoryProvider must be overridden in ProviderScope',
  );
});

final watchRoulettesUseCaseProvider = Provider<WatchRoulettesUseCase>((ref) {
  return WatchRoulettesUseCase(ref.watch(roulettesRepositoryProvider));
});

final saveRouletteUseCaseProvider = Provider<SaveRouletteUseCase>((ref) {
  return SaveRouletteUseCase(ref.watch(roulettesRepositoryProvider));
});

final deleteRouletteUseCaseProvider = Provider<DeleteRouletteUseCase>((ref) {
  return DeleteRouletteUseCase(ref.watch(roulettesRepositoryProvider));
});

final createRouletteUseCaseProvider = Provider<CreateRouletteUseCase>((ref) {
  return CreateRouletteUseCase(ref.watch(roulettesRepositoryProvider));
});

final addRouletteItemUseCaseProvider = Provider<AddRouletteItemUseCase>((ref) {
  return AddRouletteItemUseCase(ref.watch(roulettesRepositoryProvider));
});

final planSpinUseCaseProvider = Provider<PlanSpinUseCase>((ref) {
  return const PlanSpinUseCase();
});

class ContentController extends StreamNotifier<List<RouletteCategory>> {
  @override
  Stream<List<RouletteCategory>> build() {
    return ref.watch(watchRoulettesUseCaseProvider)();
  }

  Future<void> save(RouletteCategory category) {
    return ref.read(saveRouletteUseCaseProvider)(category);
  }

  Future<void> delete(RouletteCategory category) {
    return ref.read(deleteRouletteUseCaseProvider)(category);
  }

  Future<RouletteCategory> create() {
    return ref.read(createRouletteUseCaseProvider)();
  }

  Future<RouletteCategory> addItem(RouletteCategory category) {
    return ref.read(addRouletteItemUseCaseProvider)(category);
  }

  SpinPlan planSpin({
    required List<RouletteItem> items,
    required double currentRotation,
    required Random random,
  }) {
    return ref.read(planSpinUseCaseProvider)(
      items: items,
      currentRotation: currentRotation,
      random: random,
    );
  }
}

final contentControllerProvider =
    StreamNotifierProvider<ContentController, List<RouletteCategory>>(
      ContentController.new,
    );
