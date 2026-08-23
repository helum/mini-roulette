import 'package:mini_roulette/data/datasources/roulettes_api.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';

class RoulettesRepositoryImpl implements RoulettesRepository {
  const RoulettesRepositoryImpl({required RoulettesApi roulettesApi})
    : _roulettesApi = roulettesApi;

  final RoulettesApi _roulettesApi;

  @override
  Stream<List<RouletteCategory>> watchRoulettes() {
    return _roulettesApi.watchRoulettes();
  }

  @override
  Future<void> saveRoulette(RouletteCategory category) {
    return _roulettesApi.saveRoulette(category);
  }

  @override
  Future<void> deleteRoulette(String id) {
    return _roulettesApi.deleteRoulette(id);
  }

  @override
  void close() => _roulettesApi.close();
}
