import 'package:flutter/material.dart';

class ReceiptCategory {
  String description;
  Color color;
  int? id;

  ReceiptCategory({required this.description, required this.color, this.id});

  @override
  operator ==(Object? other) => (other is ReceiptCategory &&
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

  factory ReceiptCategory.fromJson(Map<String, dynamic> json) {
    return ReceiptCategory(
        description: json['description'],
        color: Color(json['color']).withOpacity(1),
        id: json['id']);
  }

  static String getCategoryDescription(ReceiptCategory category) {
    return category.description;
  }

  static ReceiptCategory getCategory(int categoryID, categories) {
    return categories.firstWhere((item) => item.id == categoryID);
  }

  static ReceiptCategory getCategoryByDesc(String categoryDesc, categories) {
    return categories.firstWhere((item) => item.description == categoryDesc);
  }

  static ReceiptCategory noneCategory =
      ReceiptCategory(description: "None", color: Colors.black);
}
