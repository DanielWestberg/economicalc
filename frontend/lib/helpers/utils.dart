import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/material.dart';

import '../models/receipt.dart';

class Utils {
  static int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  static int compareNumber(bool ascending, num value1, num value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  static Color backgroundColor = Color(0xFFB8D8D8);
  static Color tileColor = Color(0xffD4E6F3);
  static Color drawerColor = Color(0xff69A3A7);
  static Color chartBarColor = Color.fromARGB(255, 68, 104, 107);
  static Color snackBarError = Color(0xFFC72C41);

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

  Receipt cleanReceipt(Receipt receipt) {
    var result = receipt;

    List<String> discounts_swe = [
      "Prisnedsättning",
      "Rabatt",
    ];
    List<String> stopwords = ["Mottaget", "Kontokort"];

    List<ReceiptItem> items = result.items;
    String ocr_text = result.ocrText;
    List<String> ocr = ocr_text.split("\n");

    List<String> cleanedOcr = [];

    for (String str in ocr) {
      //cleanedOcr.add(str.replaceAll(RegExp(r"\s+"), ""));
      cleanedOcr.add(str.trim());
    }

    for (int i = 0; i < items.length; i++) {
      String desc = items[i].itemName;
      //print(desc);
      if (desc.contains("C,kr/kg") || desc.contains("kr/kg")) {
        for (int j = 0; j < cleanedOcr.length; j++) {
          if (cleanedOcr[j].contains(items[i - 1].itemName)) {
            print("Inside ${cleanedOcr[j]}");
            items[i].itemName = cleanedOcr[j + 1];
          }
        }
      }

      for (String stopword in discounts_swe) {
        String desc = items[i].itemName;
        double amount = items[i].amount;
        if (desc.contains(stopword)) {
          items[i - 1].itemName += " $desc";
          items[i - 1].amount += amount;
          items.removeAt(i);
          i--;
        }
      }
      for (String stopword in stopwords) {
        String desc = items[i].itemName;
        if (desc.contains(stopword)) {
          items.removeAt(i);
          i--;
        }
      }
      if (double.tryParse(desc.replaceAll(",", "")) != null) {
        items.removeAt(i);
        i--;
      }
    }
    return result;
  }
}
