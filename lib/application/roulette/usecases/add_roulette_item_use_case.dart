import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/domain/value_objects/item_palette.dart';
import 'package:uuid/uuid.dart';

class AddRouletteItemUseCase {
  AddRouletteItemUseCase(
    this._repository, {
    String Function()? nextId,
  }) : _nextId = nextId ?? const Uuid().v4;

  final RoulettesRepository _repository;
  final String Function() _nextId;

  Future<RouletteCategory> call(RouletteCategory category) async {
    final index = category.items.length;
    final updated = category.copyWith(
      items: [
        ...category.items,
        RouletteItem(
          id: _nextId(),
          label: '項目 ${index + 1}',
          colorValue: ItemPalette.at(index),
        ),
      ],
    );
    await _repository.saveRoulette(updated);
    return updated;
  }
}
