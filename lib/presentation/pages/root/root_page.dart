import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/presentation/controllers/domain/onboarding_controller.dart';
import 'package:mini_roulette/presentation/pages/home/home_page.dart';
import 'package:mini_roulette/presentation/pages/onboarding/onboarding_page.dart';

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingControllerProvider);

    return onboarding.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const HomePage(),
      data: (completed) => completed ? const HomePage() : const OnboardingPage(),
    );
  }
}
