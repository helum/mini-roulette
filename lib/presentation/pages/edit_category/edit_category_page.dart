import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';

class EditCategoryPage extends ConsumerWidget {
  const EditCategoryPage({super.key, required this.categoryId});

  final String categoryId;

  static Route<void> route({required String categoryId}) {
    return MaterialPageRoute<void>(
      builder: (_) => EditCategoryPage(categoryId: categoryId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentControllerProvider);

    return content.when(
      skipLoadingOnReload: true,
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('編集')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('編集')),
        body: const Center(child: Text('読み込みに失敗しました')),
      ),
      data: (categories) {
        final category = _byId(categories, categoryId);
        if (category == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('編集')),
            body: const Center(child: Text('このルーレットは削除されています')),
          );
        }

        return _EditCategoryBody(category: category);
      },
    );
  }
}

class _EditCategoryBody extends ConsumerWidget {
  const _EditCategoryBody({required this.category});

  final RouletteCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ルーレットを編集')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _NameField(category: category),
          const SizedBox(height: 20),
          if (!category.canSpin)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '回すには項目を 2 つ以上登録してください',
                style: TextStyle(color: AppColors.goldLight),
              ),
            ),
          Row(
            children: [
              const Text(
                '項目',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${category.items.length} 件',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in category.items) ...[
            _ItemEditor(
              key: ValueKey(item.id),
              category: category,
              item: item,
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () {
              ref.read(contentControllerProvider.notifier).addItem(category);
            },
            icon: const Icon(Icons.add),
            label: const Text('項目を追加'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.goldLight,
              side: const BorderSide(color: AppColors.goldLine),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

RouletteCategory? _byId(List<RouletteCategory> categories, String id) {
  for (final category in categories) {
    if (category.id == id) {
      return category;
    }
  }
  return null;
}

class _NameField extends ConsumerStatefulWidget {
  const _NameField({required this.category});

  final RouletteCategory category;

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(labelText: 'ルーレット名'),
      onChanged: (value) {
        ref
            .read(contentControllerProvider.notifier)
            .save(widget.category.copyWith(name: value));
      },
    );
  }
}

class _ItemEditor extends ConsumerStatefulWidget {
  const _ItemEditor({super.key, required this.category, required this.item});

  final RouletteCategory category;
  final RouletteItem item;

  @override
  ConsumerState<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends ConsumerState<_ItemEditor> {
  late final TextEditingController _label;
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.item.label);
    _weight = TextEditingController(text: _formatWeight(widget.item.weight));
  }

  @override
  void dispose() {
    _label.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final category = widget.category;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _label,
                    decoration: const InputDecoration(
                      labelText: 'ラベル',
                      isDense: true,
                    ),
                    onChanged: (value) => _patch(item.copyWith(label: value)),
                  ),
                ),
                IconButton(
                  tooltip: '削除',
                  onPressed: () {
                    final next = [
                      for (final existing in category.items)
                        if (existing.id != item.id) existing,
                    ];
                    ref
                        .read(contentControllerProvider.notifier)
                        .save(category.copyWith(items: next));
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '色',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in AppColors.itemPalette)
                  GestureDetector(
                    onTap: () => _patch(
                      item.copyWith(colorValue: color.toARGB32()),
                    ),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.colorValue == color.toARGB32()
                              ? AppColors.goldLight
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weight,
              decoration: const InputDecoration(
                labelText: '重み（大きいほど当たりやすい）',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return;
                }
                _patch(item.copyWith(weight: parsed));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _patch(RouletteItem next) {
    final items = [
      for (final existing in widget.category.items)
        if (existing.id == next.id) next else existing,
    ];
    ref
        .read(contentControllerProvider.notifier)
        .save(widget.category.copyWith(items: items));
  }

  String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.round().toString();
    }
    return weight.toString();
  }
}
