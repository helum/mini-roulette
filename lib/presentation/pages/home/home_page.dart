import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/pages/edit_category/edit_category_page.dart';
import 'package:mini_roulette/presentation/pages/spin/spin_page.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';
import 'package:mini_roulette/presentation/shared/widgets/roulette_wheel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ミニルーレット',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: content.when(
                  skipLoadingOnReload: true,
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        return _CategoryRow(category: categories[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('読み込みに失敗しました')),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
          child: TextButton.icon(
            onPressed: () async {
              final created = await ref
                  .read(contentControllerProvider.notifier)
                  .create();
              if (!context.mounted) {
                return;
              }
              await Navigator.of(
                context,
              ).push(EditCategoryPage.route(categoryId: created.id));
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('ルーレットを追加'),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RouletteWheel(
            items: [],
            rotation: 0,
            size: 128,
            showPointer: false,
            showLabels: false,
          ),
          SizedBox(height: 28),
          Text('まだルーレットがありません'),
          SizedBox(height: 8),
          Text(
            '下のボタンから作ってください',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final RouletteCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).push(SpinPage.route(categoryId: category.id));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              RouletteWheel(
                items: category.items,
                rotation: 0,
                size: 88,
                showPointer: false,
                showLabels: false,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.canSpin
                          ? '${category.items.length} 項目'
                          : '項目が不足 · 編集して追加',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.muted),
                onSelected: (value) async {
                  if (value == 'edit') {
                    await Navigator.of(
                      context,
                    ).push(EditCategoryPage.route(categoryId: category.id));
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierColor: AppColors.ink.withValues(alpha: 0.28),
                      builder: (context) => AlertDialog(
                        title: const Text('削除しますか？'),
                        content: Text('「${category.displayName}」を削除します。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('やめる'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('削除'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(contentControllerProvider.notifier)
                          .delete(category);
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('編集')),
                  PopupMenuItem(value: 'delete', child: Text('削除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
