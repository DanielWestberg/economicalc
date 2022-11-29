import 'package:economicalc_client/models/category.dart';
import 'package:flutter/material.dart';

class Utils {
  static int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  static int compareNumber(bool ascending, num value1, num value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  static Color backgroundColor = Color(0xFFB8D8D8);
  static Color tileColor = Color(0xffD4E6F3);
  static Color drawerColor = Color(0xff69A3A7);

  static List<Category> categories = [
    Category(description: "Groceries", color: Colors.blue),
    Category(description: "Transportation", color: Colors.purple),
    Category(description: "Stuff", color: Colors.green),
    Category(
        description: "My proud collection of teddy bears", color: Colors.brown),
  ];

  static String getCategoryDescription(Category category) {
    return category.description;
  }

  static Category getCategory(String desc, categories) {
    return categories.firstWhere((item) => item.description == desc);
  }
}