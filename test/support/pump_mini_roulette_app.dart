import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/app.dart';
import 'package:mini_roulette/data/datasources/in_memory_onboarding_api.dart';
import 'package:mini_roulette/data/repositories/in_memory_notification_scheduler.dart';
import 'package:mini_roulette/data/repositories/onboarding_repository_impl.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';
import 'package:mini_roulette/domain/repositories/onboarding_repository.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';

OnboardingRepository createOnboardingRepository({bool completed = true}) {
  return OnboardingRepositoryImpl(
    onboardingApi: InMemoryOnboardingApi(completed: completed),
  );
}

Future<NotificationScheduler> pumpMiniRouletteApp(
  WidgetTester tester, {
  required RoulettesRepository repository,
  NotificationScheduler? notificationScheduler,
  bool onboardingCompleted = true,
}) async {
  final scheduler = notificationScheduler ?? InMemoryNotificationScheduler();
  if (notificationScheduler == null) {
    addTearDown((scheduler as InMemoryNotificationScheduler).dispose);
  }

  await tester.pumpWidget(
    MiniRouletteApp(
      roulettesRepository: repository,
      notificationScheduler: scheduler,
      onboardingRepository: createOnboardingRepository(
        completed: onboardingCompleted,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return scheduler;
}
