import 'package:mini_roulette/domain/entities/roulette_category.dart';

abstract interface class RoulettesRepository {
  Stream<List<RouletteCategory>> watchRoulettes();

  Future<void> saveRoulette(RouletteCategory category);

  Future<void> deleteRoulette(String id);

  void close();
}
