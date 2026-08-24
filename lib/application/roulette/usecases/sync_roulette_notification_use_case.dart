import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';

class SyncRouletteNotificationUseCase {
  const SyncRouletteNotificationUseCase(this._scheduler);

  final NotificationScheduler _scheduler;

  Future<void> call(RouletteCategory category) {
    return _scheduler.sync(category);
  }
}
