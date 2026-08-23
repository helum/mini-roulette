import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/data/datasources/local_roulettes_api.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalRoulettesApi', () {
    late SharedPreferencesAsync prefs;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      prefs = SharedPreferencesAsync();
    });

    test('watchRoulettes emits the sample lunch roulette when storage is empty', () async {
      final api = await LocalRoulettesApi.create(plugin: prefs);

      final first = await api.watchRoulettes().first;
      expect(first.single.id, 'sample-lunch');
      expect(first.single.name, '今日のランチ');
      api.close();
    });

    test('saved categories are still available after a new instance is created', () async {
      const category = RouletteCategory(
        id: '1',
        name: '罰ゲーム',
        items: [
          RouletteItem(
            id: 'a',
            label: '一本締め',
            colorValue: 0xFFC41E3A,
            weight: 2,
          ),
        ],
      );

      final writer = await LocalRoulettesApi.create(plugin: prefs);
      await writer.saveRoulette(category);
      writer.close();

      final reader = await LocalRoulettesApi.create(plugin: prefs);
      final loaded = await reader.watchRoulettes().first;
      expect(loaded.map((item) => item.id), contains('1'));
      expect(
        loaded.firstWhere((item) => item.id == '1').items.first.weight,
        2,
      );
      reader.close();
    });

    test('deleteRoulette removes the category from persisted storage', () async {
      final writer = await LocalRoulettesApi.create(plugin: prefs);
      await writer.deleteRoulette('sample-lunch');
      writer.close();

      final reader = await LocalRoulettesApi.create(plugin: prefs);
      expect(await reader.watchRoulettes().first, isEmpty);
      reader.close();
    });
  });
}
