import 'package:equatable/equatable.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';

class RouletteCategory extends Equatable {
  const RouletteCategory({
    required this.id,
    required this.name,
    required this.items,
    this.notification = NotificationSettings.disabled,
  });

  static const minItemsToSpin = 2;

  final String id;
  final String name;
  final List<RouletteItem> items;
  final NotificationSettings notification;

  bool get canSpin => items.length >= minItemsToSpin;

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '無題のルーレット' : trimmed;
  }

  RouletteCategory copyWith({
    String? id,
    String? name,
    List<RouletteItem>? items,
    NotificationSettings? notification,
  }) {
    return RouletteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      notification: notification ?? this.notification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'notification': notification.toJson(),
    };
  }

  factory RouletteCategory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawNotification = json['notification'];
    return RouletteCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      items: rawItems
          .map((item) => RouletteItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      notification: rawNotification is Map
          ? NotificationSettings.fromJson(
              Map<String, dynamic>.from(rawNotification),
            )
          : NotificationSettings.disabled,
    );
  }

  @override
  List<Object> get props => [id, name, items, notification];
}
