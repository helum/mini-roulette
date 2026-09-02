import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/application/onboarding/usecases/complete_onboarding_use_case.dart';
import 'package:mini_roulette/application/onboarding/usecases/has_completed_onboarding_use_case.dart';
import 'package:mini_roulette/domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  throw UnimplementedError(
    'onboardingRepositoryProvider must be overridden in ProviderScope',
  );
});

final hasCompletedOnboardingUseCaseProvider =
    Provider<HasCompletedOnboardingUseCase>((ref) {
      return HasCompletedOnboardingUseCase(
        ref.watch(onboardingRepositoryProvider),
      );
    });

final completeOnboardingUseCaseProvider =
    Provider<CompleteOnboardingUseCase>((ref) {
      return CompleteOnboardingUseCase(ref.watch(onboardingRepositoryProvider));
    });

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(hasCompletedOnboardingUseCaseProvider)();
  }

  Future<void> complete() async {
    await ref.read(completeOnboardingUseCaseProvider)();
    state = const AsyncData(true);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);
