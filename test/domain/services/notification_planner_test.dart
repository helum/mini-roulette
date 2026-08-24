import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/services/notification_planner.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';

void main() {
  const category = RouletteCategory(
    id: 'lunch',
    name: '今日のランチ',
    items: [RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A)],
  );

  test('disabled settings produce no occurrences', () {
    expect(NotificationPlanner.plan(category), isEmpty);
  });

  test('daily settings produce one occurrence at the given time', () {
    final planned = category.copyWith(
      notification: const NotificationSettings(
        enabled: true,
        hour: 8,
        minute: 15,
      ),
    );

    final occurrences = NotificationPlanner.plan(planned);

    expect(occurrences, hasLength(1));
    expect(occurrences.single.id, NotificationPlanner.baseId('lunch'));
    expect(occurrences.single.hour, 8);
    expect(occurrences.single.minute, 15);
    expect(occurrences.single.weekday, isNull);
  });

  test('weekly settings produce one occurrence per weekday', () {
    final planned = category.copyWith(
      notification: const NotificationSettings(
        enabled: true,
        frequency: NotificationFrequency.weekly,
        hour: 9,
        minute: 0,
        weekdays: {DateTime.monday, DateTime.wednesday},
      ),
    );

    final occurrences = NotificationPlanner.plan(planned);
    final base = NotificationPlanner.baseId('lunch');

    expect(occurrences, hasLength(2));
    expect(occurrences.map((item) => item.weekday), [
      DateTime.monday,
      DateTime.wednesday,
    ]);
    expect(occurrences.map((item) => item.id), [
      base + DateTime.monday,
      base + DateTime.wednesday,
    ]);
  });

  test('plan ids always stay inside the cancellable id range', () {
    final weekly = category.copyWith(
      notification: const NotificationSettings(
        enabled: true,
        frequency: NotificationFrequency.weekly,
        weekdays: {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        },
      ),
    );
    final daily = category.copyWith(
      notification: const NotificationSettings(enabled: true),
    );
    final cancellable = NotificationPlanner.idsFor('lunch').toSet();

    for (final planned in [daily, weekly]) {
      for (final occurrence in NotificationPlanner.plan(planned)) {
        expect(cancellable, contains(occurrence.id));
      }
    }
  });

  test('notification ids fit in a 32-bit Android notification id', () {
    for (final id in NotificationPlanner.idsFor(
      'ffffffff-ffff-ffff-ffff-ffffffffffff',
    )) {
      expect(id, lessThanOrEqualTo(0x7fffffff));
      expect(id, greaterThanOrEqualTo(0));
    }
  });

  group('daysUntilNext', () {
    const daily = NotificationOccurrence(id: 0, hour: 20, minute: 0);

    test('daily before the time fires today', () {
      expect(
        NotificationPlanner.daysUntilNext(
          daily,
          nowWeekday: DateTime.wednesday,
          nowMinutesOfDay: 19 * 60 + 59,
        ),
        0,
      );
    });

    test('daily at or after the time fires tomorrow', () {
      expect(
        NotificationPlanner.daysUntilNext(
          daily,
          nowWeekday: DateTime.wednesday,
          nowMinutesOfDay: 20 * 60,
        ),
        1,
      );
      expect(
        NotificationPlanner.daysUntilNext(
          daily,
          nowWeekday: DateTime.wednesday,
          nowMinutesOfDay: 23 * 60,
        ),
        1,
      );
    });

    test('weekly waits until the requested weekday', () {
      const monday = NotificationOccurrence(
        id: 0,
        hour: 9,
        minute: 0,
        weekday: DateTime.monday,
      );

      expect(
        NotificationPlanner.daysUntilNext(
          monday,
          nowWeekday: DateTime.saturday,
          nowMinutesOfDay: 12 * 60,
        ),
        2,
      );
      expect(
        NotificationPlanner.daysUntilNext(
          monday,
          nowWeekday: DateTime.tuesday,
          nowMinutesOfDay: 12 * 60,
        ),
        6,
      );
    });

    test('weekly on the same weekday rolls over a full week once passed', () {
      const wednesday = NotificationOccurrence(
        id: 0,
        hour: 9,
        minute: 0,
        weekday: DateTime.wednesday,
      );

      expect(
        NotificationPlanner.daysUntilNext(
          wednesday,
          nowWeekday: DateTime.wednesday,
          nowMinutesOfDay: 8 * 60,
        ),
        0,
      );
      expect(
        NotificationPlanner.daysUntilNext(
          wednesday,
          nowWeekday: DateTime.wednesday,
          nowMinutesOfDay: 9 * 60,
        ),
        7,
      );
    });
  });
}
