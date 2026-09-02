import 'package:mini_roulette/data/datasources/onboarding_api.dart';
import 'package:mini_roulette/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl({required OnboardingApi onboardingApi})
    : _onboardingApi = onboardingApi;

  final OnboardingApi _onboardingApi;

  @override
  Future<bool> hasCompleted() => _onboardingApi.hasCompleted();

  @override
  Future<void> complete() => _onboardingApi.complete();
}
