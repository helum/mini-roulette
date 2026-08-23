import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/application/roulette/usecases/add_roulette_item_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/create_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/delete_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/save_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/watch_roulettes_use_case.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/domain/value_objects/item_palette.dart';
import 'package:mocktail/mocktail.dart';

class MockRoulettesRepository extends Mock implements RoulettesRepository {}

class FakeRouletteCategory extends Fake implements RouletteCategory {}

void main() {
  late RoulettesRepository repository;

  const lunch = RouletteCategory(
    id: 'lunch',
    name: '今日のランチ',
    items: [
      RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A),
      RouletteItem(id: 'b', label: 'カレー', colorValue: 0xFF1B6CA8),
    ],
  );

  setUpAll(() {
    registerFallbackValue(FakeRouletteCategory());
  });

  setUp(() {
    repository = MockRoulettesRepository();
    when(() => repository.watchRoulettes()).thenAnswer((_) => const Stream.empty());
    when(() => repository.saveRoulette(any())).thenAnswer((_) async {});
    when(() => repository.deleteRoulette(any())).thenAnswer((_) async {});
  });

  group('WatchRoulettesUseCase', () {
    test('exposes categories from the repository stream', () async {
      when(() => repository.watchRoulettes()).thenAnswer(
        (_) => Stream.value([lunch]),
      );

      final categories = await WatchRoulettesUseCase(repository)().first;

      expect(categories, [lunch]);
    });
  });

  group('SaveRouletteUseCase', () {
    test('persists the category', () async {
      await SaveRouletteUseCase(repository)(lunch);

      verify(() => repository.saveRoulette(lunch)).called(1);
    });
  });

  group('DeleteRouletteUseCase', () {
    test('removes the category', () async {
      await DeleteRouletteUseCase(repository)(lunch);

      verify(() => repository.deleteRoulette(lunch.id)).called(1);
    });
  });

  group('CreateRouletteUseCase', () {
    test('saves a roulette with two default items', () async {
      var n = 0;
      final created = await CreateRouletteUseCase(
        repository,
        nextId: () => 'id-${n++}',
      )();

      expect(created.id, 'id-0');
      expect(created.name, '新しいルーレット');
      expect(created.items, hasLength(2));
      expect(created.items.first.label, '項目 1');
      expect(created.items.first.colorValue, ItemPalette.at(0));
      verify(() => repository.saveRoulette(created)).called(1);
    });
  });

  group('AddRouletteItemUseCase', () {
    test('appends a default item and saves', () async {
      final updated = await AddRouletteItemUseCase(
        repository,
        nextId: () => 'new-item',
      )(lunch);

      expect(updated.items, hasLength(3));
      expect(updated.items.last.label, '項目 3');
      expect(updated.items.last.colorValue, ItemPalette.at(2));
      verify(() => repository.saveRoulette(updated)).called(1);
    });
  });
}
