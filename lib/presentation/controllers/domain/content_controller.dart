import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/application/roulette/usecases/add_roulette_item_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/cancel_roulette_notification_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/create_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/delete_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/plan_spin_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/request_notification_permission_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/save_roulette_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/sync_roulette_notification_use_case.dart';
import 'package:mini_roulette/application/roulette/usecases/watch_roulettes_use_case.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/repositories/notification_scheduler.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/domain/value_objects/spin_plan.dart';

final roulettesRepositoryProvider = Provider<RoulettesRepository>((ref) {
  throw UnimplementedError(
    'roulettesRepositoryProvider must be overridden in ProviderScope',
  );
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  throw UnimplementedError(
    'notificationSchedulerProvider must be overridden in ProviderScope',
  );
});

final watchRoulettesUseCaseProvider = Provider<WatchRoulettesUseCase>((ref) {
  return WatchRoulettesUseCase(ref.watch(roulettesRepositoryProvider));
});

final saveRouletteUseCaseProvider = Provider<SaveRouletteUseCase>((ref) {
  return SaveRouletteUseCase(ref.watch(roulettesRepositoryProvider));
});

final deleteRouletteUseCaseProvider = Provider<DeleteRouletteUseCase>((ref) {
  return DeleteRouletteUseCase(ref.watch(roulettesRepositoryProvider));
});

final createRouletteUseCaseProvider = Provider<CreateRouletteUseCase>((ref) {
  return CreateRouletteUseCase(ref.watch(roulettesRepositoryProvider));
});

final addRouletteItemUseCaseProvider = Provider<AddRouletteItemUseCase>((ref) {
  return AddRouletteItemUseCase(ref.watch(roulettesRepositoryProvider));
});

final planSpinUseCaseProvider = Provider<PlanSpinUseCase>((ref) {
  return const PlanSpinUseCase();
});

final syncRouletteNotificationUseCaseProvider =
    Provider<SyncRouletteNotificationUseCase>((ref) {
      return SyncRouletteNotificationUseCase(
        ref.watch(notificationSchedulerProvider),
      );
    });

final cancelRouletteNotificationUseCaseProvider =
    Provider<CancelRouletteNotificationUseCase>((ref) {
      return CancelRouletteNotificationUseCase(
        ref.watch(notificationSchedulerProvider),
      );
    });

final requestNotificationPermissionUseCaseProvider =
    Provider<RequestNotificationPermissionUseCase>((ref) {
      return RequestNotificationPermissionUseCase(
        ref.watch(notificationSchedulerProvider),
      );
    });

class ContentController extends StreamNotifier<List<RouletteCategory>> {
  @override
  Stream<List<RouletteCategory>> build() {
    return ref.watch(watchRoulettesUseCaseProvider)();
  }

  Future<void> save(RouletteCategory category) async {
    final previous = _categoryById(category.id);
    await ref.read(saveRouletteUseCaseProvider)(category);
    if (_needsNotificationSync(previous, category)) {
      await ref.read(syncRouletteNotificationUseCaseProvider)(category);
    }
  }

  Future<void> delete(RouletteCategory category) async {
    await ref.read(deleteRouletteUseCaseProvider)(category);
    await ref.read(cancelRouletteNotificationUseCaseProvider)(category.id);
  }

  Future<RouletteCategory> create() {
    return ref.read(createRouletteUseCaseProvider)();
  }

  Future<RouletteCategory> addItem(RouletteCategory category) {
    return ref.read(addRouletteItemUseCaseProvider)(category);
  }

  Future<bool> requestNotificationPermission() {
    return ref.read(requestNotificationPermissionUseCaseProvider)();
  }

  RouletteCategory? _categoryById(String id) {
    for (final category in state.value ?? const <RouletteCategory>[]) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  /// 名前と項目は1文字ごとに保存されるため、通知に影響しない保存では
  /// OS への再予約を行わない。予約は取消8件＋登録N件のプラットフォーム
  /// 呼び出しになるので、無条件に走らせると入力が詰まる。
  bool _needsNotificationSync(
    RouletteCategory? previous,
    RouletteCategory next,
  ) {
    if (previous == null) {
      return next.notification.isSchedulable;
    }
    return previous.notification != next.notification ||
        previous.displayName != next.displayName;
  }

  SpinPlan planSpin({
    required List<RouletteItem> items,
    required double currentRotation,
    required Random random,
  }) {
    return ref.read(planSpinUseCaseProvider)(
      items: items,
      currentRotation: currentRotation,
      random: random,
    );
  }
}

final contentControllerProvider =
    StreamNotifierProvider<ContentController, List<RouletteCategory>>(
      ContentController.new,
    );
