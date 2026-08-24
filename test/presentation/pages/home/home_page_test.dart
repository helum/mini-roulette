import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/app.dart';
import 'package:mini_roulette/data/repositories/in_memory_notification_scheduler.dart';
import 'package:mini_roulette/data/datasources/in_memory_roulettes_api.dart';
import 'package:mini_roulette/data/datasources/local_roulettes_api.dart';
import 'package:mini_roulette/data/repositories/roulettes_repository_impl.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('初回はサンプルのランチルーレットが表示される', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final repository = RoulettesRepositoryImpl(
      roulettesApi: await LocalRoulettesApi.create(
        plugin: SharedPreferencesAsync(),
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: InMemoryNotificationScheduler(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ミニルーレット'), findsOneWidget);
    expect(find.text('今日のランチ'), findsOneWidget);
    expect(find.textContaining('4 項目'), findsOneWidget);
  });

  testWidgets('カードをタップすると回転画面が開き、回すボタンがある', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final repository = RoulettesRepositoryImpl(
      roulettesApi: await LocalRoulettesApi.create(
        plugin: SharedPreferencesAsync(),
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: InMemoryNotificationScheduler(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日のランチ'));
    await tester.pumpAndSettle();

    expect(find.text('回す'), findsOneWidget);
    expect(find.text('今日のランチ'), findsOneWidget);
  });

  testWidgets('回すと結果ダイアログが出る', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final repository = RoulettesRepositoryImpl(
      roulettesApi: await LocalRoulettesApi.create(
        plugin: SharedPreferencesAsync(),
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: InMemoryNotificationScheduler(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日のランチ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('回す'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('結果'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
  });

  testWidgets('項目が1つだと回せない', (tester) async {
    const category = RouletteCategory(
      id: 'one',
      name: '足りないルーレット',
      items: [RouletteItem(id: 'a', label: 'だけ', colorValue: 0xFFC41E3A)],
    );
    final repository = RoulettesRepositoryImpl(
      roulettesApi: InMemoryRoulettesApi(seed: const [category]),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: InMemoryNotificationScheduler(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('足りないルーレット'));
    await tester.pumpAndSettle();

    expect(find.text('項目が 2 つ以上ないと回せません'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('ルーレットを追加すると編集画面が開く', (tester) async {
    final repository = RoulettesRepositoryImpl(
      roulettesApi: InMemoryRoulettesApi(),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: InMemoryNotificationScheduler(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ルーレットを追加'));
    await tester.pumpAndSettle();

    expect(find.text('ルーレットを編集'), findsOneWidget);
    expect(find.text('新しいルーレット'), findsOneWidget);
    expect(find.text('項目 1'), findsOneWidget);
  });
}
