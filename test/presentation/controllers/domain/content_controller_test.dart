import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
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

  ProviderContainer createContainer() {
    final container = ProviderContainer.test(
      overrides: [
        roulettesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ContentController', () {
    test('exposes categories from the watch use case', () async {
      when(() => repository.watchRoulettes()).thenAnswer(
        (_) => Stream.value([lunch]),
      );

      final container = createContainer();
      final subscription = container.listen(contentControllerProvider, (_, _) {});
      addTearDown(subscription.close);

      final categories = await container.read(contentControllerProvider.future);
      expect(categories, [lunch]);
    });

    test('save persists the category through the use case', () async {
      final container = createContainer();

      await container.read(contentControllerProvider.notifier).save(lunch);

      verify(() => repository.saveRoulette(lunch)).called(1);
    });

    test('delete removes the category', () async {
      final container = createContainer();

      await container.read(contentControllerProvider.notifier).delete(lunch);

      verify(() => repository.deleteRoulette(lunch.id)).called(1);
    });

    test('create saves a new roulette', () async {
      final container = createContainer();

      final created = await container
          .read(contentControllerProvider.notifier)
          .create();

      expect(created.name, '新しいルーレット');
      expect(created.items, hasLength(2));
      verify(() => repository.saveRoulette(created)).called(1);
    });
  });
}
