import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/pages/edit_category/edit_category_page.dart';
import 'package:mini_roulette/presentation/pages/spin/spin_page.dart';
import 'package:mini_roulette/presentation/shared/roulette_item_color.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ミニルーレット',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ルーレットを選んで回す',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: content.when(
                  skipLoadingOnReload: true,
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _CategoryCard(category: categories[index]);
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
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add),
        label: const Text('ルーレットを追加'),
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
          Icon(Icons.casino_outlined, size: 56, color: AppColors.gold),
          SizedBox(height: 16),
          Text('まだルーレットがありません'),
          SizedBox(height: 8),
          Text(
            '右下のボタンから最初のルーレットを作ってください',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});

  final RouletteCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(SpinPage.route(categoryId: category.id));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              _ColorDots(items: category.items),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.canSpin
                          ? '${category.items.length} 項目 · タップして回す'
                          : '項目が不足 · 編集して追加',
                      style: TextStyle(
                        color: category.canSpin
                            ? AppColors.muted
                            : AppColors.goldLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await Navigator.of(
                      context,
                    ).push(EditCategoryPage.route(categoryId: category.id));
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
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

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.items});

  final List<RouletteItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = items.take(4).map((item) => item.color).toList();
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 8.0,
              top: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
