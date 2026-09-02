abstract interface class OnboardingApi {
  Future<bool> hasCompleted();

  Future<void> complete();
}
