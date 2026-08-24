import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/data/repositories/in_memory_notification_scheduler.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockRoulettesRepository extends Mock implements RoulettesRepository {}

class FakeRouletteCategory extends Fake implements RouletteCategory {}

void main() {
  late RoulettesRepository repository;
  late InMemoryNotificationScheduler scheduler;

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
    scheduler = InMemoryNotificationScheduler();
    when(
      () => repository.watchRoulettes(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.saveRoulette(any())).thenAnswer((_) async {});
    when(() => repository.deleteRoulette(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer.test(
      overrides: [
        roulettesRepositoryProvider.overrideWithValue(repository),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// StreamNotifier は購読者がいないと値を出さないので、購読を保ったまま待つ。
  Future<List<RouletteCategory>> awaitLoaded(ProviderContainer container) {
    final subscription = container.listen(contentControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    return container.read(contentControllerProvider.future);
  }

  group('ContentController', () {
    test('exposes categories from the watch use case', () async {
      when(
        () => repository.watchRoulettes(),
      ).thenAnswer((_) => Stream.value([lunch]));

      final container = createContainer();
      final subscription = container.listen(
        contentControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final categories = await container.read(contentControllerProvider.future);
      expect(categories, [lunch]);
    });

    test('save persists the category through the use case', () async {
      final container = createContainer();

      await container.read(contentControllerProvider.notifier).save(lunch);

      verify(() => repository.saveRoulette(lunch)).called(1);
    });

    test(
      'save does not touch the scheduler when no notification is set',
      () async {
        final container = createContainer();

        await container.read(contentControllerProvider.notifier).save(lunch);

        expect(scheduler.synced, isEmpty);
      },
    );

    test('save syncs when notification settings change', () async {
      final container = createContainer();
      final enabled = lunch.copyWith(
        notification: const NotificationSettings(enabled: true),
      );

      await container.read(contentControllerProvider.notifier).save(enabled);

      expect(scheduler.synced['lunch'], enabled);
    });

    test('save skips the scheduler when only an item changes', () async {
      final scheduled = lunch.copyWith(
        notification: const NotificationSettings(enabled: true),
      );
      when(
        () => repository.watchRoulettes(),
      ).thenAnswer((_) => Stream.value([scheduled]));
      final container = createContainer();
      await awaitLoaded(container);

      await container
          .read(contentControllerProvider.notifier)
          .save(
            scheduled.copyWith(
              items: [
                scheduled.items.first.copyWith(label: 'つけ麺'),
                ...scheduled.items.skip(1),
              ],
            ),
          );

      expect(scheduler.synced, isEmpty);
    });

    test(
      'save syncs when the name changes so the title stays correct',
      () async {
        final scheduled = lunch.copyWith(
          notification: const NotificationSettings(enabled: true),
        );
        when(
          () => repository.watchRoulettes(),
        ).thenAnswer((_) => Stream.value([scheduled]));
        final container = createContainer();
        await awaitLoaded(container);

        final renamed = scheduled.copyWith(name: '夕食');
        await container.read(contentControllerProvider.notifier).save(renamed);

        expect(scheduler.synced['lunch'], renamed);
      },
    );

    test('delete removes the category and cancels its notification', () async {
      final container = createContainer();

      await container.read(contentControllerProvider.notifier).delete(lunch);

      verify(() => repository.deleteRoulette(lunch.id)).called(1);
      expect(scheduler.cancelled, contains('lunch'));
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
