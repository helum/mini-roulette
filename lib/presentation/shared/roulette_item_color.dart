import 'package:flutter/material.dart';
import 'package:mini_roulette/domain/entities/roulette_item.dart';

extension RouletteItemColor on RouletteItem {
  Color get color => Color(colorValue);
}
