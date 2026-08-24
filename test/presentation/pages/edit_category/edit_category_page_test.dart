import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/data/repositories/in_memory_notification_scheduler.dart';
import 'package:mini_roulette/data/datasources/in_memory_roulettes_api.dart';
import 'package:mini_roulette/data/repositories/roulettes_repository_impl.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/pages/edit_category/edit_category_page.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lunch = RouletteCategory(
    id: 'lunch',
    name: '今日のランチ',
    items: [
      RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A),
      RouletteItem(id: 'b', label: 'カレー', colorValue: 0xFF1B6CA8),
    ],
  );

  testWidgets('turning notification on shows time and frequency controls', (
    tester,
  ) async {
    final repository = RoulettesRepositoryImpl(
      roulettesApi: InMemoryRoulettesApi(seed: const [lunch]),
    );
    addTearDown(repository.close);
    final scheduler = InMemoryNotificationScheduler();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roulettesRepositoryProvider.overrideWithValue(repository),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: const [Locale('ja')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildAppTheme(),
          home: const EditCategoryPage(categoryId: 'lunch'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('毎日'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('毎日'), findsOneWidget);
    expect(find.text('毎週'), findsOneWidget);
    expect(scheduler.synced['lunch']?.notification.enabled, isTrue);
  });
}
