import 'dart:async';
import 'dart:convert';

import 'package:mini_roulette/data/datasources/roulettes_api.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:mini_roulette/domain/value_objects/item_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalRoulettesApi extends RoulettesApi {
  LocalRoulettesApi._({
    required SharedPreferencesAsync plugin,
    required List<RouletteCategory> categories,
  }) : _plugin = plugin,
       _categories = categories;

  static Future<LocalRoulettesApi> create({
    required SharedPreferencesAsync plugin,
  }) async {
    return LocalRoulettesApi._(
      plugin: plugin,
      categories: await _load(plugin),
    );
  }

  static const kRoulettesStorageKey = 'roulette_categories';

  final SharedPreferencesAsync _plugin;
  final List<RouletteCategory> _categories;
  final _controller = StreamController<List<RouletteCategory>>.broadcast();

  @override
  Stream<List<RouletteCategory>> watchRoulettes() {
    return Stream<List<RouletteCategory>>.multi((controller) {
      controller.add(_snapshot());
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> saveRoulette(RouletteCategory category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
    await _persist();
    _controller.add(_snapshot());
  }

  @override
  Future<void> deleteRoulette(String id) async {
    _categories.removeWhere((item) => item.id == id);
    await _persist();
    _controller.add(_snapshot());
  }

  @override
  void close() {
    _controller.close();
  }

  static Future<List<RouletteCategory>> _load(
    SharedPreferencesAsync plugin,
  ) async {
    final encoded = await plugin.getString(kRoulettesStorageKey);
    if (encoded == null) {
      final seeded = sampleCategories();
      await plugin.setString(
        kRoulettesStorageKey,
        json.encode(seeded.map((category) => category.toJson()).toList()),
      );
      return seeded;
    }
    final decoded = json.decode(encoded) as List<dynamic>;
    return decoded
        .map(
          (item) => RouletteCategory.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _persist() async {
    final encoded = json.encode(
      _categories.map((category) => category.toJson()).toList(),
    );
    await _plugin.setString(kRoulettesStorageKey, encoded);
  }

  List<RouletteCategory> _snapshot() {
    return List<RouletteCategory>.unmodifiable(_categories);
  }

  static List<RouletteCategory> sampleCategories() {
    return [
      RouletteCategory(
        id: 'sample-lunch',
        name: '今日のランチ',
        items: [
          RouletteItem(
            id: 'sample-lunch-ramen',
            label: 'ラーメン',
            colorValue: ItemPalette.at(0),
          ),
          RouletteItem(
            id: 'sample-lunch-curry',
            label: 'カレー',
            colorValue: ItemPalette.at(1),
          ),
          RouletteItem(
            id: 'sample-lunch-sushi',
            label: '寿司',
            colorValue: ItemPalette.at(2),
          ),
          RouletteItem(
            id: 'sample-lunch-udon',
            label: 'うどん',
            colorValue: ItemPalette.at(3),
          ),
        ],
      ),
    ];
  }
}
