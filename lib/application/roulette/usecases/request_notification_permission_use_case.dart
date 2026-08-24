import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';

class RequestNotificationPermissionUseCase {
  const RequestNotificationPermissionUseCase(this._scheduler);

  final NotificationScheduler _scheduler;

  Future<bool> call() {
    return _scheduler.requestPermission();
  }
}
