import 'package:mini_roulette/data/datasources/onboarding_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalOnboardingApi implements OnboardingApi {
  const LocalOnboardingApi({required SharedPreferencesAsync plugin})
    : _plugin = plugin;

  static const kOnboardingCompletedKey = 'onboarding_completed';

  final SharedPreferencesAsync _plugin;

  @override
  Future<bool> hasCompleted() async {
    return await _plugin.getBool(kOnboardingCompletedKey) ?? false;
  }

  @override
  Future<void> complete() async {
    await _plugin.setBool(kOnboardingCompletedKey, true);
  }
}
