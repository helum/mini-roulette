import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/data/datasources/local_notifications_api.dart';
import 'package:mini_roulette/data/repositories/notification_scheduler_impl.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/services/notification_planner.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';

/// 呼び出し順まで検証したいので、プラグイン依存の本物ではなく
/// 契約だけを満たす記録用の実装を使う。
class RecordingNotificationsApi implements LocalNotificationsApi {
  final calls = <String>[];
  final cancelledIds = <int>[];
  final scheduled = <ScheduledNotification>[];
  Duration cancelDelay = Duration.zero;

  @override
  Future<void> cancel(int id) async {
    if (cancelDelay > Duration.zero) {
      await Future<void>.delayed(cancelDelay);
    }
    calls.add('cancel:$id');
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    calls.add('schedule:${notification.occurrence.id}');
    scheduled.add(notification);
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> launchCategoryId() async => null;

  @override
  Stream<String> get tappedCategoryIds => const Stream<String>.empty();

  @override
  void close() {}
}

void main() {
  const lunch = RouletteCategory(
    id: 'lunch',
    name: '今日のランチ',
    items: [RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A)],
    notification: NotificationSettings(enabled: true, hour: 9, minute: 30),
  );

  test('sync clears every reserved slot before scheduling', () async {
    final api = RecordingNotificationsApi();

    await NotificationSchedulerImpl(api: api).sync(lunch);

    expect(api.cancelledIds, NotificationPlanner.idsFor('lunch'));
    expect(api.calls.last, 'schedule:${NotificationPlanner.baseId('lunch')}');
    expect(api.scheduled.single.title, '今日のランチ');
    expect(api.scheduled.single.payload, 'lunch');
  });

  test('sync of a disabled category only cancels', () async {
    final api = RecordingNotificationsApi();

    await NotificationSchedulerImpl(
      api: api,
    ).sync(lunch.copyWith(notification: NotificationSettings.disabled));

    expect(api.scheduled, isEmpty);
    expect(api.cancelledIds, NotificationPlanner.idsFor('lunch'));
  });

  test('a blank display name still produces a readable title', () async {
    final api = RecordingNotificationsApi();

    await NotificationSchedulerImpl(api: api).sync(lunch.copyWith(name: '  '));

    expect(api.scheduled.single.title, '無題のルーレット');
  });

  test('syncAll wipes everything then reschedules each category', () async {
    final api = RecordingNotificationsApi();
    final dinner = lunch.copyWith(id: 'dinner', name: '夕食');

    await NotificationSchedulerImpl(api: api).syncAll([lunch, dinner]);

    expect(api.calls.first, 'cancelAll');
    expect(api.scheduled.map((item) => item.payload), ['lunch', 'dinner']);
  });

  test('overlapping writes never interleave cancel and schedule', () async {
    final api = RecordingNotificationsApi()
      ..cancelDelay = const Duration(milliseconds: 1);
    final scheduler = NotificationSchedulerImpl(api: api);

    await Future.wait([scheduler.sync(lunch), scheduler.sync(lunch)]);

    // 直列化されていれば cancel×8 → schedule が2周ぶん並ぶ。
    final base = NotificationPlanner.baseId('lunch');
    final oneRound = [
      for (final id in NotificationPlanner.idsFor('lunch')) 'cancel:$id',
      'schedule:$base',
    ];
    expect(api.calls, [...oneRound, ...oneRound]);
  });

  test('a failing write does not block later writes', () async {
    final api = _FailingOnceApi();
    final scheduler = NotificationSchedulerImpl(api: api);

    await expectLater(scheduler.cancel('lunch'), throwsStateError);
    await scheduler.cancel('dinner');

    expect(api.cancelledCategories, 1);
  });
}

class _FailingOnceApi extends RecordingNotificationsApi {
  bool _failed = false;
  int cancelledCategories = 0;

  @override
  Future<void> cancel(int id) async {
    if (!_failed) {
      _failed = true;
      throw StateError('boom');
    }
    if (id == NotificationPlanner.idsFor('dinner').first) {
      cancelledCategories++;
    }
  }
}
