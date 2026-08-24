import 'package:mini_roulette/domain/entities/roulette_category.dart';

abstract interface class NotificationScheduler {
  Stream<String> get tappedCategoryIds;

  Future<void> sync(RouletteCategory category);

  Future<void> cancel(String categoryId);

  Future<void> syncAll(List<RouletteCategory> categories);

  Future<bool> requestPermission();

  Future<String?> launchCategoryId();
}
