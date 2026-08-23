import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';

class SaveRouletteUseCase {
  const SaveRouletteUseCase(this._repository);

  final RoulettesRepository _repository;

  Future<void> call(RouletteCategory category) {
    return _repository.saveRoulette(category);
  }
}
