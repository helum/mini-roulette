abstract interface class OnboardingRepository {
  Future<bool> hasCompleted();

  Future<void> complete();
}
