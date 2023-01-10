import 'package:flutter/material.dart';

class TransactionCategory {
  String description;
  Color color;
  int? id;

  TransactionCategory(
      {required this.description, required this.color, this.id});

  @override
  operator ==(Object? other) => (other is TransactionCategory &&
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

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
        description: json['description'],
        color: Color(json['color']).withOpacity(1),
        id: json['id']);
  }

  static String getCategoryDescription(TransactionCategory category) {
    return category.description;
  }

  static TransactionCategory getCategory(int categoryID, categories) {
    return categories.firstWhere((item) => item.id == categoryID);
  }

  static TransactionCategory getCategoryByDesc(
      String categoryDesc, categories) {
    return categories.firstWhere((item) => item.description == categoryDesc);
  }

  static TransactionCategory allCategory =
      TransactionCategory(description: "All", color: Colors.black);
}
