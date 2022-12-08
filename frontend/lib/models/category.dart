import 'package:flutter/material.dart';

class Category {
  String description;
  Color color;
  int? id;

  Category({required this.description, required this.color, this.id});

  @override
  operator ==(Object? other) => (other is Category &&
      description == other.description &&
      color == other.color &&
      id == other.id);

  @override
  get hashCode => (description.hashCode | color.hashCode | id.hashCode);

  Map<String, dynamic> toJson([bool includeId = false]) {
    final res = {
      'description': description,
      'color': color.value.toInt(),
    };

    if (includeId && id != null) {
      res["id"] = id!;
    }

    return res;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        description: json['description'],
        color: Color(json['color']).withOpacity(1),
        id: json['id']);
  }

  static String getCategoryDescription(Category category) {
    return category.description;
  }

  static Category getCategory(int categoryID, categories) {
    return categories.firstWhere((item) => item.id == categoryID);
  }

  static Category getCategoryByDesc(String categoryDesc, categories) {
    return categories.firstWhere((item) => item.description == categoryDesc);
  }

  static Category noneCategory =
      Category(description: "None", color: Colors.black);
}
