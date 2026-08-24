import 'package:equatable/equatable.dart';

enum NotificationFrequency { daily, weekly }

class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.enabled = false,
    this.frequency = NotificationFrequency.daily,
    this.hour = 20,
    this.minute = 0,
    this.weekdays = const {},
  });

  static const disabled = NotificationSettings();

  final bool enabled;
  final NotificationFrequency frequency;
  final int hour;
  final int minute;
  final Set<int> weekdays;

  bool get isSchedulable {
    if (!enabled) {
      return false;
    }
    if (frequency == NotificationFrequency.weekly && weekdays.isEmpty) {
      return false;
    }
    return true;
  }

  NotificationSettings copyWith({
    bool? enabled,
    NotificationFrequency? frequency,
    int? hour,
    int? minute,
    Set<int>? weekdays,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  Map<String, dynamic> toJson() {
    final days = weekdays.toList()..sort();
    return {
      'enabled': enabled,
      'frequency': frequency.name,
      'hour': hour,
      'minute': minute,
      'weekdays': days,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return disabled;
    }
    final rawDays = json['weekdays'] as List<dynamic>? ?? const [];
    final frequencyName = json['frequency'] as String?;
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? false,
      frequency: frequencyName == NotificationFrequency.weekly.name
          ? NotificationFrequency.weekly
          : NotificationFrequency.daily,
      hour: json['hour'] as int? ?? 20,
      minute: json['minute'] as int? ?? 0,
      weekdays: {
        for (final day in rawDays)
          if (day is int && day >= DateTime.monday && day <= DateTime.sunday)
            day,
      },
    );
  }

  @override
  List<Object> get props {
    final days = weekdays.toList()..sort();
    return [enabled, frequency, hour, minute, days];
  }
}
