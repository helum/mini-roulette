import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/pages/edit_category/edit_category_page.dart';
import 'package:mini_roulette/presentation/pages/home/home_page.dart';
import 'package:mini_roulette/presentation/pages/spin/spin_page.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';

class MiniRouletteApp extends StatelessWidget {
  const MiniRouletteApp({
    super.key,
    required this.roulettesRepository,
    required this.notificationScheduler,
    this.navigatorKey,
  });

  final RoulettesRepository roulettesRepository;
  final NotificationScheduler notificationScheduler;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        roulettesRepositoryProvider.overrideWithValue(roulettesRepository),
        notificationSchedulerProvider.overrideWithValue(notificationScheduler),
      ],
      child: _MiniRouletteAppView(navigatorKey: navigatorKey),
    );
  }
}

class _MiniRouletteAppView extends ConsumerStatefulWidget {
  const _MiniRouletteAppView({required this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  ConsumerState<_MiniRouletteAppView> createState() =>
      _MiniRouletteAppViewState();
}

class _MiniRouletteAppViewState extends ConsumerState<_MiniRouletteAppView> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  StreamSubscription<String>? _tapSub;
  ProviderSubscription<AsyncValue<List<RouletteCategory>>>? _contentSub;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    // 通知タップ時に一覧を読めるよう、画面の有無に関係なく購読を保つ。
    _contentSub = ref.listenManual(contentControllerProvider, (_, _) {});
    final scheduler = ref.read(notificationSchedulerProvider);
    _tapSub = scheduler.tappedCategoryIds.listen(_openCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 通知から起動した場合のみ ID が返る。プラグインの仕様上、
      // 起動を伴うタップは tappedCategoryIds には流れない。
      final categoryId = await scheduler.launchCategoryId();
      if (categoryId != null) {
        await _openCategory(categoryId);
      }
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _contentSub?.close();
    super.dispose();
  }

  Future<void> _openCategory(String categoryId) async {
    final categories = await ref.read(contentControllerProvider.future);
    if (!mounted) {
      return;
    }
    final category = _byId(categories, categoryId);
    if (category == null) {
      return;
    }
    final nav = _navigatorKey.currentState;
    if (nav == null) {
      return;
    }
    // 通知を続けてタップしても画面が積み上がらないよう、常に一覧へ戻してから開く。
    nav.popUntil((route) => route.isFirst);
    nav.push(
      category.canSpin
          ? SpinPage.route(categoryId: categoryId)
          : EditCategoryPage.route(categoryId: categoryId),
    );
  }

  RouletteCategory? _byId(List<RouletteCategory> categories, String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ミニルーレット',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: const HomePage(),
    );
  }
}
