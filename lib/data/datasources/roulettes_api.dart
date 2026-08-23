import 'package:mini_roulette/domain/entities/roulette_category.dart';

abstract class RoulettesApi {
  const RoulettesApi();

  Stream<List<RouletteCategory>> watchRoulettes();

  Future<void> saveRoulette(RouletteCategory category);

  Future<void> deleteRoulette(String id);

  void close();
}
