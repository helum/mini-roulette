abstract final class ItemPalette {
  static const values = <int>[
    0xFFC41E3A,
    0xFF1B6CA8,
    0xFF2A9D6A,
    0xFFD97706,
    0xFF6D28D9,
    0xFF0F766E,
    0xFFBE185D,
    0xFF1E3A5F,
  ];

  static int at(int index) => values[index % values.length];
}
