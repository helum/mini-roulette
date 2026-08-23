import 'package:flutter_test/flutter_test.dart';
import 'package:mini_roulette/domain/entities/roulette_category.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';

void main() {
  const item = RouletteItem(id: 'a', label: 'ラーメン', colorValue: 0xFFC41E3A);

  test('canSpin is false until there are two items', () {
    const one = RouletteCategory(id: '1', name: '食事', items: [item]);
    final two = one.copyWith(
      items: const [
        item,
        RouletteItem(id: 'b', label: 'カレー', colorValue: 0xFF1B6CA8),
      ],
    );

    expect(one.canSpin, isFalse);
    expect(two.canSpin, isTrue);
  });

  test('displayName falls back when the name is blank', () {
    const category = RouletteCategory(id: '1', name: '  ', items: []);
    expect(category.displayName, '無題のルーレット');
  });
}
