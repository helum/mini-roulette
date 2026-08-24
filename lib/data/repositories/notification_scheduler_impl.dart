import 'dart:async';

import 'package:mini_roulette/data/datasources/local_notifications_api.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';
import 'package:mini_roulette/domain/services/notification_planner.dart';

class NotificationSchedulerImpl implements NotificationScheduler {
  NotificationSchedulerImpl({required LocalNotificationsApi api}) : _api = api;

  final LocalNotificationsApi _api;

  /// 予約の取消と再登録が交互に走らないよう、書き込み系を直列化する。
  Future<void> _queue = Future<void>.value();

  @override
  Stream<String> get tappedCategoryIds => _api.tappedCategoryIds;

  @override
  Future<void> sync(RouletteCategory category) {
    return _serialize(() async {
      await _cancelIds(category.id);
      await _schedule(category);
    });
  }

  @override
  Future<void> cancel(String categoryId) {
    return _serialize(() => _cancelIds(categoryId));
  }

  @override
  Future<void> syncAll(List<RouletteCategory> categories) {
    return _serialize(() async {
      await _api.cancelAll();
      for (final category in categories) {
        await _schedule(category);
      }
    });
  }

  @override
  Future<bool> requestPermission() => _api.requestPermission();

  @override
  Future<String?> launchCategoryId() => _api.launchCategoryId();

  Future<void> _serialize(Future<void> Function() action) {
    final completer = Completer<void>();
    _queue = _queue.then((_) async {
      try {
        await action();
        completer.complete();
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _cancelIds(String categoryId) async {
    for (final id in NotificationPlanner.idsFor(categoryId)) {
      await _api.cancel(id);
    }
  }

  Future<void> _schedule(RouletteCategory category) async {
    for (final occurrence in NotificationPlanner.plan(category)) {
      await _api.schedule(
        ScheduledNotification(
          occurrence: occurrence,
          title: category.displayName,
          body: 'ルーレットを回しましょう',
          payload: category.id,
        ),
      );
    }
  }
}
