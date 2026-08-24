import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';

class NotificationOccurrence {
  const NotificationOccurrence({
    required this.id,
    required this.hour,
    required this.minute,
    this.weekday,
  });

  final int id;
  final int hour;
  final int minute;
  final int? weekday;
}

abstract final class NotificationPlanner {
  static const _slotCount = 8;

  static const minutesPerDay = 24 * 60;

  static int baseId(String categoryId) {
    var hash = 2166136261;
    for (final code in categoryId.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return (hash % 100000000) * _slotCount;
  }

  static List<int> idsFor(String categoryId) {
    final base = baseId(categoryId);
    return [for (var i = 0; i < _slotCount; i++) base + i];
  }

  static List<NotificationOccurrence> plan(RouletteCategory category) {
    final settings = category.notification;
    if (!settings.isSchedulable) {
      return const [];
    }
    final base = baseId(category.id);
    if (settings.frequency == NotificationFrequency.daily) {
      return [
        NotificationOccurrence(
          id: base,
          hour: settings.hour,
          minute: settings.minute,
        ),
      ];
    }
    final days = settings.weekdays.toList()..sort();
    return [
      for (final day in days)
        NotificationOccurrence(
          id: base + day,
          hour: settings.hour,
          minute: settings.minute,
          weekday: day,
        ),
    ];
  }

  /// 今日から数えて何日後に [occurrence] が発火するかを返す。
  ///
  /// 当日ちょうどの時刻はすでに過ぎたものとして扱い、次の周期へ送る。
  /// 呼び出し側はこの日数を「今日の日付 + 戻り値」に足して予約時刻を組み立てる。
  static int daysUntilNext(
    NotificationOccurrence occurrence, {
    required int nowWeekday,
    required int nowMinutesOfDay,
  }) {
    final target = occurrence.hour * 60 + occurrence.minute;
    final weekday = occurrence.weekday;
    if (weekday == null) {
      return target > nowMinutesOfDay ? 0 : 1;
    }
    final days = (weekday - nowWeekday) % DateTime.daysPerWeek;
    if (days == 0 && target <= nowMinutesOfDay) {
      return DateTime.daysPerWeek;
    }
    return days;
  }
}
