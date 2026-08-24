import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';

class CancelRouletteNotificationUseCase {
  const CancelRouletteNotificationUseCase(this._scheduler);

  final NotificationScheduler _scheduler;

  Future<void> call(String categoryId) {
    return _scheduler.cancel(categoryId);
  }
}
