import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';

class DeleteRouletteUseCase {
  const DeleteRouletteUseCase(this._repository);

  final RoulettesRepository _repository;

  Future<void> call(RouletteCategory category) {
    return _repository.deleteRoulette(category.id);
  }
}
