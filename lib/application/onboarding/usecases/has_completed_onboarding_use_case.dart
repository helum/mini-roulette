import 'package:mini_roulette/domain/repositories/onboarding_repository.dart';

class HasCompletedOnboardingUseCase {
  const HasCompletedOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<bool> call() => _repository.hasCompleted();
}
