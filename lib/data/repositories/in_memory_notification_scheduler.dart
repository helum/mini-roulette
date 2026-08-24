import 'dart:async';

import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';

class InMemoryNotificationScheduler implements NotificationScheduler {
  InMemoryNotificationScheduler({this.permissionGranted = true});

  bool permissionGranted;
  String? launchId;
  final synced = <String, RouletteCategory>{};
  final cancelled = <String>{};
  final _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get tappedCategoryIds => _taps.stream;

  @override
  Future<void> sync(RouletteCategory category) async {
    cancelled.remove(category.id);
    synced[category.id] = category;
  }

  @override
  Future<void> cancel(String categoryId) async {
    synced.remove(categoryId);
    cancelled.add(categoryId);
  }

  @override
  Future<void> syncAll(List<RouletteCategory> categories) async {
    synced
      ..clear()
      ..addEntries(
        categories.map((category) => MapEntry(category.id, category)),
      );
    cancelled.clear();
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<String?> launchCategoryId() async => launchId;

  void emitTap(String categoryId) => _taps.add(categoryId);

  void dispose() => _taps.close();
}
