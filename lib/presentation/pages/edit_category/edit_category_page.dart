import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/value_objects/notification_settings.dart';
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
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 48),
        children: [
          _NameField(category: category),
          const SizedBox(height: 20),
          _NotificationCard(category: category),
          const SizedBox(height: 28),
          if (!category.canSpin)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                '回すには項目を 2 つ以上登録してください',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          Row(
            children: [
              Text('項目', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${category.items.length} 件',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in category.items) ...[
            _ItemEditor(key: ValueKey(item.id), category: category, item: item),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: () {
              ref.read(contentControllerProvider.notifier).addItem(category);
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('項目を追加'),
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

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.category});

  final RouletteCategory category;

  static const _weekdayLabels = <int, String>{
    DateTime.monday: '月',
    DateTime.tuesday: '火',
    DateTime.wednesday: '水',
    DateTime.thursday: '木',
    DateTime.friday: '金',
    DateTime.saturday: '土',
    DateTime.sunday: '日',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = category.notification;
    final time = TimeOfDay(hour: settings.hour, minute: settings.minute);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('通知'),
              value: settings.enabled,
              onChanged: (enabled) => _setEnabled(context, ref, enabled),
            ),
            if (settings.enabled) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('時刻'),
                trailing: Text(time.format(context)),
                onTap: () => _pickTime(context, ref, time),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('毎日'),
                    selected: settings.frequency == NotificationFrequency.daily,
                    onSelected: (_) => _save(
                      context,
                      ref,
                      settings.copyWith(frequency: NotificationFrequency.daily),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('毎週'),
                    selected:
                        settings.frequency == NotificationFrequency.weekly,
                    onSelected: (_) => _save(
                      context,
                      ref,
                      settings.copyWith(
                        frequency: NotificationFrequency.weekly,
                        weekdays: settings.weekdays.isEmpty
                            ? {DateTime.monday}
                            : settings.weekdays,
                      ),
                    ),
                  ),
                ],
              ),
              if (settings.frequency == NotificationFrequency.weekly) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _weekdayLabels.entries)
                      FilterChip(
                        label: Text(entry.value),
                        selected: settings.weekdays.contains(entry.key),
                        onSelected: (selected) {
                          final next = {...settings.weekdays};
                          if (selected) {
                            next.add(entry.key);
                          } else {
                            next.remove(entry.key);
                          }
                          _save(
                            context,
                            ref,
                            settings.copyWith(weekdays: next),
                          );
                        },
                      ),
                  ],
                ),
                if (settings.weekdays.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '曜日を 1 つ以上選んでください',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      final granted = await ref
          .read(contentControllerProvider.notifier)
          .requestNotificationPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('通知の許可が必要です')));
        }
        return;
      }
      if (!context.mounted) {
        return;
      }
    }
    await _save(context, ref, _settingsOf(enabled: enabled));
  }

  NotificationSettings _settingsOf({required bool enabled}) {
    return category.notification.copyWith(enabled: enabled);
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay current,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _save(
      context,
      ref,
      category.notification.copyWith(hour: picked.hour, minute: picked.minute),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings notification,
  ) async {
    try {
      await ref
          .read(contentControllerProvider.notifier)
          .save(category.copyWith(notification: notification));
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('通知の設定を保存できませんでした')));
      }
    }
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
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 20),
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
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '色',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in AppColors.itemPalette)
                  GestureDetector(
                    onTap: () =>
                        _patch(item.copyWith(colorValue: color.toARGB32())),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.colorValue == color.toARGB32()
                              ? AppColors.ink
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weight,
              decoration: const InputDecoration(
                labelText: '重み（大きいほど出やすい）',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
