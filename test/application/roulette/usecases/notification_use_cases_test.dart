import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/application/roulette/usecases/cancel_roulette_notification_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/request_notification_permission_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/sync_roulette_notification_use_case.dart';
import 'package:mini_roulette/data/repositories/in_memory_notification_scheduler.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';

void main() {
  const lunch = RouletteCategory(
    id: 'lunch',
    name: '今日のランチ',
    items: [RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A)],
    notification: NotificationSettings(enabled: true),
  );

  test('SyncRouletteNotificationUseCase syncs the category', () async {
    final scheduler = InMemoryNotificationScheduler();

    await SyncRouletteNotificationUseCase(scheduler)(lunch);

    expect(scheduler.synced['lunch'], lunch);
  });

  test('CancelRouletteNotificationUseCase cancels by id', () async {
    final scheduler = InMemoryNotificationScheduler();
    await scheduler.sync(lunch);

    await CancelRouletteNotificationUseCase(scheduler)(lunch.id);

    expect(scheduler.synced.containsKey('lunch'), isFalse);
    expect(scheduler.cancelled, contains('lunch'));
  });

  test(
    'RequestNotificationPermissionUseCase returns the scheduler result',
    () async {
      final scheduler = InMemoryNotificationScheduler(permissionGranted: false);

      expect(await RequestNotificationPermissionUseCase(scheduler)(), isFalse);
    },
  );
}
