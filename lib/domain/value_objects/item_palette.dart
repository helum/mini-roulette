abstract final class ItemPalette {
  static const values = <int>[
    0xFFE07A6E,
    0xFF5B9BD5,
    0xFF6DBF8B,
    0xFFE8A85A,
    0xFF8B7EC8,
    0xFF4AA8A4,
    0xFFD4729A,
    0xFF7A8B9A,
  ];

  static int at(int index) => values[index % values.length];
}
