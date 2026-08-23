import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';

class WatchRoulettesUseCase {
  const WatchRoulettesUseCase(this._repository);

  final RoulettesRepository _repository;

  Stream<List<RouletteCategory>> call() => _repository.watchRoulettes();
}
