import 'dart:async';

import 'package:mini_roulette/data/datasources/roulettes_api.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';

class InMemoryRoulettesApi extends RoulettesApi {
  InMemoryRoulettesApi({List<RouletteCategory>? seed})
    : _categories = List<RouletteCategory>.of(seed ?? const []);

  final List<RouletteCategory> _categories;
  final _controller = StreamController<List<RouletteCategory>>.broadcast();

  @override
  Stream<List<RouletteCategory>> watchRoulettes() {
    return Stream<List<RouletteCategory>>.multi((controller) {
      controller.add(_snapshot());
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> saveRoulette(RouletteCategory category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
    _controller.add(_snapshot());
  }

  @override
  Future<void> deleteRoulette(String id) async {
    _categories.removeWhere((item) => item.id == id);
    _controller.add(_snapshot());
  }

  @override
  void close() {
    _controller.close();
  }

  List<RouletteCategory> _snapshot() => List<RouletteCategory>.unmodifiable(_categories);
}
