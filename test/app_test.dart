import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/app.dart';
import 'package:mini_roulette/data/datasources/in_memory_roulettes_api.dart';
import 'package:mini_roulette/data/repositories/in_memory_notification_scheduler.dart';
import 'package:mini_roulette/data/repositories/roulettes_repository_impl.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/presentation/pages/edit_category/edit_category_page.dart';
import 'package:mini_roulette/presentation/pages/spin/spin_page.dart';

void main() {
  const lunch = RouletteCategory(
    id: 'lunch',
    name: '今日のランチ',
    items: [
      RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A),
      RouletteItem(id: 'b', label: 'カレー', colorValue: 0xFF1B6CA8),
    ],
  );
  const lonely = RouletteCategory(
    id: 'lonely',
    name: '足りないルーレット',
    items: [RouletteItem(id: 'a', label: 'だけ', colorValue: 0xFFC41E3A)],
  );

  Future<InMemoryNotificationScheduler> pumpApp(
    WidgetTester tester,
    List<RouletteCategory> seed,
  ) async {
    final repository = RoulettesRepositoryImpl(
      roulettesApi: InMemoryRoulettesApi(seed: seed),
    );
    addTearDown(repository.close);
    final scheduler = InMemoryNotificationScheduler();
    addTearDown(scheduler.dispose);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();
    return scheduler;
  }

  testWidgets('通知タップで回せるルーレットの回転画面が開く', (tester) async {
    final scheduler = await pumpApp(tester, const [lunch]);

    scheduler.emitTap('lunch');
    await tester.pumpAndSettle();

    expect(find.byType(SpinPage), findsOneWidget);
  });

  testWidgets('回せないルーレットの通知タップは編集画面を開く', (tester) async {
    final scheduler = await pumpApp(tester, const [lonely]);

    scheduler.emitTap('lonely');
    await tester.pumpAndSettle();

    expect(find.byType(EditCategoryPage), findsOneWidget);
    expect(find.byType(SpinPage), findsNothing);
  });

  testWidgets('通知を連続でタップしても画面が積み上がらない', (tester) async {
    final scheduler = await pumpApp(tester, const [lunch]);

    scheduler.emitTap('lunch');
    await tester.pumpAndSettle();
    scheduler.emitTap('lunch');
    await tester.pumpAndSettle();
    scheduler.emitTap('lunch');
    await tester.pumpAndSettle();

    expect(find.byType(SpinPage), findsOneWidget);

    // 一覧まで戻して開き直しているので、戻るとホームに着く。
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SpinPage), findsNothing);
    expect(find.text('ミニルーレット'), findsOneWidget);
  });

  testWidgets('存在しないルーレットの通知タップは何も開かない', (tester) async {
    final scheduler = await pumpApp(tester, const [lunch]);

    scheduler.emitTap('missing');
    await tester.pumpAndSettle();

    expect(find.byType(SpinPage), findsNothing);
    expect(find.byType(EditCategoryPage), findsNothing);
  });

  testWidgets('通知から起動したときは該当ルーレットを開く', (tester) async {
    final repository = RoulettesRepositoryImpl(
      roulettesApi: InMemoryRoulettesApi(seed: const [lunch]),
    );
    addTearDown(repository.close);
    final scheduler = InMemoryNotificationScheduler()..launchId = 'lunch';
    addTearDown(scheduler.dispose);

    await tester.pumpWidget(
      MiniRouletteApp(
        roulettesRepository: repository,
        notificationScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SpinPage), findsOneWidget);
  });
}
