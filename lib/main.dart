import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_roulette/app.dart';
import 'package:mini_roulette/data/datasources/local_notifications_api.dart';
import 'package:mini_roulette/data/datasources/local_onboarding_api.dart';
import 'package:mini_roulette/data/datasources/local_roulettes_api.dart';
import 'package:mini_roulette/data/repositories/notification_scheduler_impl.dart';
import 'package:mini_roulette/data/repositories/onboarding_repository_impl.dart';
import 'package:mini_roulette/data/repositories/roulettes_repository_impl.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.canvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  const sharedPreferencesOptions = SharedPreferencesOptions();
  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
    sharedPreferencesAsyncOptions: sharedPreferencesOptions,
    migrationCompletedKey: '__roulette_prefs_migration_completed__',
  );

  final preferences = SharedPreferencesAsync(options: sharedPreferencesOptions);
  final roulettesRepository = RoulettesRepositoryImpl(
    roulettesApi: await LocalRoulettesApi.create(plugin: preferences),
  );
  final onboardingRepository = OnboardingRepositoryImpl(
    onboardingApi: LocalOnboardingApi(plugin: preferences),
  );
  final notificationScheduler = NotificationSchedulerImpl(
    api: await LocalNotificationsApi.create(),
  );

  runApp(
    MiniRouletteApp(
      roulettesRepository: roulettesRepository,
      notificationScheduler: notificationScheduler,
      onboardingRepository: onboardingRepository,
    ),
  );

  // 全件の再予約は初回フレームを待たせないよう起動後に回す。
  // NotificationSchedulerImpl 側で書き込みを直列化しているため、
  // この間にユーザーが行った保存と取消・登録が混ざることはない。
  unawaited(_resyncNotifications(roulettesRepository, notificationScheduler));
}

Future<void> _resyncNotifications(
  RoulettesRepository repository,
  NotificationScheduler scheduler,
) async {
  try {
    await scheduler.syncAll(await repository.watchRoulettes().first);
  } on Object catch (error, stackTrace) {
    debugPrint('通知の再同期に失敗しました: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
