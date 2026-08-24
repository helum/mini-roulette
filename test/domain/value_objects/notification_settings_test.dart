import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';

void main() {
  test('fromJson falls back to disabled when the map is missing', () {
    expect(NotificationSettings.fromJson(null), NotificationSettings.disabled);
  });

  test('fromJson round-trips a weekly schedule', () {
    const settings = NotificationSettings(
      enabled: true,
      frequency: NotificationFrequency.weekly,
      hour: 8,
      minute: 30,
      weekdays: {DateTime.monday, DateTime.friday},
    );

    expect(NotificationSettings.fromJson(settings.toJson()), settings);
  });

  test('weekly with no weekdays is not schedulable', () {
    const settings = NotificationSettings(
      enabled: true,
      frequency: NotificationFrequency.weekly,
    );

    expect(settings.isSchedulable, isFalse);
  });

  test('enabled daily is schedulable', () {
    const settings = NotificationSettings(enabled: true);

    expect(settings.isSchedulable, isTrue);
  });
}
