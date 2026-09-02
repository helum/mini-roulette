import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/data/datasources/in_memory_onboarding_api.dart';
import 'package:mini_roulette/data/datasources/local_onboarding_api.dart';
import 'package:mini_roulette/data/repositories/onboarding_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('初回は操作説明を未完了として読み込む', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final api = LocalOnboardingApi(plugin: SharedPreferencesAsync());
    final repository = OnboardingRepositoryImpl(onboardingApi: api);

    expect(await repository.hasCompleted(), isFalse);
  });

  test('complete 後は完了として読み込む', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final api = LocalOnboardingApi(plugin: SharedPreferencesAsync());
    final repository = OnboardingRepositoryImpl(onboardingApi: api);

    await repository.complete();

    expect(await repository.hasCompleted(), isTrue);
  });

  test('InMemory は初期状態を保持する', () async {
    final api = InMemoryOnboardingApi(completed: false);
    final repository = OnboardingRepositoryImpl(onboardingApi: api);

    expect(await repository.hasCompleted(), isFalse);
    await repository.complete();
    expect(await repository.hasCompleted(), isTrue);
  });
}
