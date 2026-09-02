import 'package:mini_roulette/data/datasources/onboarding_api.dart';

class InMemoryOnboardingApi implements OnboardingApi {
  InMemoryOnboardingApi({bool completed = false}) : _completed = completed;

  bool _completed;

  @override
  Future<bool> hasCompleted() async => _completed;

  @override
  Future<void> complete() async {
    _completed = true;
  }
}
