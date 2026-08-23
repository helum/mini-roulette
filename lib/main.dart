import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_roulette/app.dart';
import 'package:mini_roulette/data/datasources/local_roulettes_api.dart';
import 'package:mini_roulette/data/repositories/roulettes_repository_impl.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  const sharedPreferencesOptions = SharedPreferencesOptions();
  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
    sharedPreferencesAsyncOptions: sharedPreferencesOptions,
    migrationCompletedKey: '__roulette_prefs_migration_completed__',
  );

  final roulettesRepository = RoulettesRepositoryImpl(
    roulettesApi: await LocalRoulettesApi.create(
      plugin: SharedPreferencesAsync(options: sharedPreferencesOptions),
    ),
  );

  runApp(MiniRouletteApp(roulettesRepository: roulettesRepository));
}
