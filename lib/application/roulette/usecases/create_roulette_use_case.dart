import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/domain/value_objects/item_palette.dart';
import 'package:uuid/uuid.dart';

class CreateRouletteUseCase {
  CreateRouletteUseCase(
    this._repository, {
    String Function()? nextId,
  }) : _nextId = nextId ?? const Uuid().v4;

  final RoulettesRepository _repository;
  final String Function() _nextId;

  Future<RouletteCategory> call() async {
    final category = RouletteCategory(
      id: _nextId(),
      name: '新しいルーレット',
      items: [
        RouletteItem(
          id: _nextId(),
          label: '項目 1',
          colorValue: ItemPalette.at(0),
        ),
        RouletteItem(
          id: _nextId(),
          label: '項目 2',
          colorValue: ItemPalette.at(1),
        ),
      ],
    );
    await _repository.saveRoulette(category);
    return category;
  }
}
