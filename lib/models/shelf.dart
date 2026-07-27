import 'package:flutter/material.dart';

class Shelf {
  final String id;
  String name;
  int colorValue; // stored as int so it can be JSON-encoded

  Shelf({
    required this.id,
    required this.name,
    Color color = Colors.brown,
  }) : colorValue = color.value;

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory Shelf.fromJson(Map<String, dynamic> json) {
    final shelf = Shelf(id: json['id'], name: json['name']);
    shelf.colorValue = json['colorValue'] ?? Colors.brown.value;
    return shelf;
  }
}
