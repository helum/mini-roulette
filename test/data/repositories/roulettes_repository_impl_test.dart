import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/data/datasources/in_memory_roulettes_api.dart';
import 'package:mini_roulette/data/repositories/roulettes_repository_impl.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';

void main() {
  group('RoulettesRepositoryImpl', () {
    late RoulettesRepository repository;

    setUp(() {
      repository = RoulettesRepositoryImpl(roulettesApi: InMemoryRoulettesApi());
    });

    tearDown(() {
      repository.close();
    });

    test('watchRoulettes emits an empty list initially', () async {
      expect(await repository.watchRoulettes().first, isEmpty);
    });

    test('saveRoulette inserts and watchRoulettes emits the new list', () async {
      const category = RouletteCategory(
        id: '1',
        name: '罰ゲーム',
        items: [
          RouletteItem(id: 'a', label: '一本締め', colorValue: 0xFFC41E3A),
        ],
      );
      final events = <List<RouletteCategory>>[];
      final subscription = repository.watchRoulettes().listen(events.add);
      await Future<void>.delayed(Duration.zero);

      expect(events, [isEmpty]);

      await repository.saveRoulette(category);
      await Future<void>.delayed(Duration.zero);

      expect(events.last, [category]);
      await subscription.cancel();
    });

    test('saveRoulette with the same id updates the existing category', () async {
      const category = RouletteCategory(id: '1', name: '食事', items: []);
      final updated = category.copyWith(name: '今日のランチ');
      await repository.saveRoulette(category);

      final events = <List<RouletteCategory>>[];
      final subscription = repository.watchRoulettes().listen(events.add);
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        [category],
      ]);

      await repository.saveRoulette(updated);
      await Future<void>.delayed(Duration.zero);

      expect(events.last, [updated]);
      await subscription.cancel();
    });

    test('deleteRoulette removes the category from subsequent emissions', () async {
      const category = RouletteCategory(id: '1', name: '食事', items: []);
      await repository.saveRoulette(category);

      final events = <List<RouletteCategory>>[];
      final subscription = repository.watchRoulettes().listen(events.add);
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        [category],
      ]);

      await repository.deleteRoulette('1');
      await Future<void>.delayed(Duration.zero);

      expect(events.last, isEmpty);
      await subscription.cancel();
    });
  });
}
