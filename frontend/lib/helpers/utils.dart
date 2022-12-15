import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/material.dart';

class Utils {
  static int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  static int compareNumber(bool ascending, num value1, num value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  // FONTSIZES
  static double drawerFontsize = 20;

  // COLORS
  static Color textColor = Colors.black87;
  static Color lightColor = Color(0xffD4E6F3);
  static Color mediumLightColor = Color(0xFFB8D8D8);
  static Color mediumDarkColor = Color(0xff7a9e9f);
  static Color darkColor = Color.fromARGB(255, 68, 104, 107);
  static Color errorColor = Color(0xFFfe5f55);

  static List<ReceiptCategory> categories = [
    ReceiptCategory(description: "Groceries", color: Colors.blue),
    ReceiptCategory(description: "Transportation", color: Colors.purple),
    ReceiptCategory(description: "Stuff", color: Colors.green),
    ReceiptCategory(
        description: "My proud collection of teddy bears", color: Colors.brown),
  ];

  static double getSumOfTransactionsTotals(
      List<Transaction> transactions, bool isExpenses) {
    double sum = 0;
    transactions.forEach((element) {
      if ((element.totalAmount! < 0) == isExpenses) {
        sum += element.totalAmount!;
      }
    });
    return isExpenses ? -sum : sum;
  }
}
