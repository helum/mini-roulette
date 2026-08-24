import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/pages/edit_category/edit_category_page.dart';
import 'package:mini_roulette/presentation/shared/roulette_item_color.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';
import 'package:mini_roulette/presentation/shared/widgets/roulette_wheel.dart';

class SpinPage extends ConsumerStatefulWidget {
  const SpinPage({super.key, required this.categoryId});

  final String categoryId;

  static Route<void> route({required String categoryId}) {
    return MaterialPageRoute<void>(
      builder: (_) => SpinPage(categoryId: categoryId),
    );
  }

  @override
  ConsumerState<SpinPage> createState() => _SpinPageState();
}

class _SpinPageState extends ConsumerState<SpinPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  double _currentRotation = 0;
  bool _spinning = false;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    );
    _rotation = AlwaysStoppedAnimation(_currentRotation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin(List<RouletteItem> items) async {
    if (_spinning || items.length < RouletteCategory.minItemsToSpin) {
      return;
    }

    final plan = ref
        .read(contentControllerProvider.notifier)
        .planSpin(
          items: items,
          currentRotation: _currentRotation,
          random: _random,
        );

    _controller.reset();
    setState(() {
      _spinning = true;
      _rotation = Tween<double>(begin: _currentRotation, end: plan.endRotation)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
    });
    await _controller.forward();
    _currentRotation = plan.endRotation;
    if (mounted) {
      setState(() => _spinning = false);
    }

    if (!mounted) {
      return;
    }
    final winner = items[plan.winnerIndex];
    HapticFeedback.lightImpact();
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.28),
      builder: (context) => AlertDialog(
        title: const Text(
          '結果',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            CircleAvatar(backgroundColor: winner.color, radius: 22),
            const SizedBox(height: 20),
            Text(
              winner.displayLabel,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentControllerProvider);
    if (content.isLoading && !content.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (content.hasError && !content.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('読み込みに失敗しました')),
      );
    }

    final categories = content.value ?? const <RouletteCategory>[];
    RouletteCategory? category;
    for (final item in categories) {
      if (item.id == widget.categoryId) {
        category = item;
        break;
      }
    }

    if (category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('このルーレットは削除されています')),
      );
    }

    final selected = category;
    return Scaffold(
      appBar: AppBar(
        title: Text(selected.displayName),
        actions: [
          IconButton(
            tooltip: '編集',
            onPressed: _spinning
                ? null
                : () {
                    Navigator.of(context).push(
                      EditCategoryPage.route(categoryId: widget.categoryId),
                    );
                  },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxSide = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final disc = maxSide / 1.08;
                    return Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return RouletteWheel(
                            items: selected.items,
                            rotation: _rotation.value,
                            size: disc,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (!selected.canSpin)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    '項目が 2 つ以上ないと回せません',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              FilledButton(
                onPressed: !_spinning && selected.canSpin
                    ? () => _spin(selected.items)
                    : null,
                child: Text(_spinning ? '回転中…' : '回す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
