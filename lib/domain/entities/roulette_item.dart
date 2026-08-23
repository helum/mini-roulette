import 'package:equatable/equatable.dart';

class RouletteItem extends Equatable {
  const RouletteItem({
    required this.id,
    required this.label,
    required this.colorValue,
    this.weight = 1,
  });

  final String id;
  final String label;
  final int colorValue;
  final double weight;

  String get displayLabel {
    final trimmed = label.trim();
    return trimmed.isEmpty ? '（無題）' : trimmed;
  }

  RouletteItem copyWith({
    String? id,
    String? label,
    int? colorValue,
    double? weight,
  }) {
    return RouletteItem(
      id: id ?? this.id,
      label: label ?? this.label,
      colorValue: colorValue ?? this.colorValue,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'colorValue': colorValue,
      'weight': weight,
    };
  }

  factory RouletteItem.fromJson(Map<String, dynamic> json) {
    return RouletteItem(
      id: json['id'] as String,
      label: json['label'] as String,
      colorValue: json['colorValue'] as int,
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  List<Object> get props => [id, label, colorValue, weight];
}
