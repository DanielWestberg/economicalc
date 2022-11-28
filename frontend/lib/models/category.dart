import 'package:flutter/material.dart';

class Category {
  String description;
  Color color;

  Category({required this.description, required this.color});

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'color': color.value.toInt(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      description: json['description'],
      color: Color(json['color']).withOpacity(1),
    );
  }

  static String getCategoryDescription(Category category) {
    return category.description;
  }

  static Category getCategory(String desc, categories) {
    return categories.firstWhere((item) => item.description == desc);
  }
}
