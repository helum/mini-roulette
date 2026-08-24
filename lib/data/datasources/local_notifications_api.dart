import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mini_roulette/domain/services/notification_planner.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ScheduledNotification {
  const ScheduledNotification({
    required this.occurrence,
    required this.title,
    required this.body,
    required this.payload,
  });

  final NotificationOccurrence occurrence;
  final String title;
  final String body;
  final String payload;
}

class LocalNotificationsApi {
  LocalNotificationsApi(this._plugin);

  static const channelId = 'roulette_reminders';
  static const channelName = 'ルーレットのリマインダー';
  static const channelDescription = '設定した時刻にルーレットを回すよう知らせます';

  /// flutter_timezone がタイムゾーンを返せなかったときの既定値。
  /// 本アプリは日本語ロケール専用なので UTC ではなく JST に寄せる。
  static const fallbackTimeZone = 'Asia/Tokyo';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();

  Stream<String> get tappedCategoryIds => _taps.stream;

  static Future<LocalNotificationsApi> create({
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(await _resolveLocation());

    final instance = plugin ?? FlutterLocalNotificationsPlugin();
    final api = LocalNotificationsApi(instance);
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await instance.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: api._onTap,
    );
    return api;
  }

  static Future<tz.Location> _resolveLocation() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(info.identifier);
    } on Object {
      return tz.getLocation(fallbackTimeZone);
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }
    _taps.add(payload);
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> schedule(ScheduledNotification notification) async {
    final occurrence = notification.occurrence;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: occurrence.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: _nextInstance(occurrence),
      notificationDetails: details,
      // リマインダー用途なので厳密なアラーム権限は要求しない。
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: notification.payload,
      matchDateTimeComponents: occurrence.weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<String?> launchCategoryId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return null;
    }
    final payload = details?.notificationResponse?.payload;
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return payload;
  }

  tz.TZDateTime _nextInstance(NotificationOccurrence occurrence) {
    final now = tz.TZDateTime.now(tz.local);
    final days = NotificationPlanner.daysUntilNext(
      occurrence,
      nowWeekday: now.weekday,
      nowMinutesOfDay: now.hour * 60 + now.minute,
    );
    // 日付の繰り上がりは TZDateTime に正規化させる。Duration を足すと
    // 夏時間の境界で壁時計の時刻がずれるため。
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + days,
      occurrence.hour,
      occurrence.minute,
    );
  }

  void close() => _taps.close();
}
