import 'dart:convert';

import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:string_similarity/string_similarity.dart';

class Utils {
  static int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  static int compareNumber(bool ascending, num value1, num value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  // FONTSIZES
  static double drawerFontsize = 20;

  // COLORS
  static Color textColor = Colors.black87;
  static Color lightColor = Color(0xffFFFAFA);
  static Color mediumLightColor = Color(0xFFB8D8D8);
  static Color mediumDarkColor = Color(0xff7a9e9f);
  static Color darkColor = Color.fromARGB(255, 68, 104, 107);
  static Color errorColor = Color(0xFFfe5f55);

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

  static Receipt cleanReceipt(Receipt receipt) {
    var result = receipt;

    List<String> discounts_swe = [
      "Prisnedsättning",
      "Rabatt",
    ];
    List<String> stopwords = [
      "Mottaget",
      "Kontokort",
      "öresavrundning",
      "avrundning"
    ];
    List<String> invalidCharacters = ["%", ",", "#", "!", ".", "?"];
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
      if (desc.contains("C,kr/kg") || desc.contains("kr/kg")) {
        for (int j = 0; j < cleanedOcr.length; j++) {
          if (cleanedOcr[j].contains(items[i - 1].itemName)) {
            items[i].itemName = cleanedOcr[j + 1];
          }
        }
      }

      for (String stopword in discounts_swe) {
        String desc = items[i].itemName;
        double amount = items[i].amount;
        if (desc.toLowerCase().trim().contains(stopword.toLowerCase().trim())) {
          items[i - 1].itemName += " $desc";
          items[i - 1].amount += amount;
          items[i - 1].amount =
              double.parse(items[i - 1].amount.toStringAsFixed(2));
          items.removeAt(i);
          i--;
        }
      }
      for (String stopword in stopwords) {
        String desc = items[i].itemName;
        if (desc.toLowerCase().trim().contains(stopword.toLowerCase().trim())) {
          items.removeAt(i);
          i--;
        }
      }
      for (String invalidChar in invalidCharacters) {
        if (double.tryParse(desc.replaceAll(invalidChar, "")) != null) {
          items.removeAt(i);
          i--;
        }
      }
    }
    return result;
  }

  static bool isSimilarDate(DateTime receiptDate, DateTime bankTransDate) {
    return receiptDate.add(const Duration(days: 5)).compareTo(bankTransDate) >=
        0;
  }

  static String removeStopWords(String word, List<String> stopwords) {
    for (String municipality in stopwords) {
      word = word.toLowerCase().trim().replaceAll(
          municipality.toLowerCase().trim().replaceAll(" ", ""), "");
    }
    return word;
  }

  static bool isSimilarStoreName(String name1, String name2, double threshold) {
    return StringSimilarity.compareTwoStrings(
            name1.toLowerCase().trim(), name2.toLowerCase().trim()) >
        threshold;
  }

  static Future<bool> isReceiptAndTransactionEqual(
      Receipt receipt, Transaction transaction) async {
    String response =
        await rootBundle.loadString('assets/swedish_municipalities.json');
    List<dynamic> sweMuni = json.decode(response);

    List<String> list = [];

    sweMuni.forEach((element) {
      list.add(element);
    });

    if (transaction.receiptID == null &&
        receipt.total! == -transaction.totalAmount! &&
        Utils.isSimilarDate(receipt.date, transaction.date)) {
      String desc = transaction.store!;
      String desc1 = receipt.recipient;
      list.sort((a, b) => b.length.compareTo(a.length));
      String result = Utils.removeStopWords(desc, list);
      String result1 = Utils.removeStopWords(desc1, list);

      if (Utils.isSimilarStoreName(result, result1, 0.4)) return true;
    }
    return false;
  }

  static Future<bool> areTransactionsEqual(
      Transaction trans1, Transaction trans2) async {
    String response =
        await rootBundle.loadString('assets/swedish_municipalities.json');
    List<dynamic> sweMuni = json.decode(response);

    List<String> list = [];

    sweMuni.forEach((element) {
      list.add(element);
    });

    if (trans1.totalAmount! == trans2.totalAmount! &&
        Utils.isSimilarDate(trans1.date, trans2.date)) {
      String desc = trans1.store!;
      String desc1 = trans2.store!;
      list.sort((a, b) => b.length.compareTo(a.length));
      String result = Utils.removeStopWords(desc, list);
      String result1 = Utils.removeStopWords(desc1, list);

      if (Utils.isSimilarStoreName(result, result1, 0.4)) return true;
    }
    return false;
  }

  static Future<bool> categoricalSimilarity(
      Transaction trans1, Transaction trans2) async {
    String response =
        await rootBundle.loadString('assets/swedish_municipalities.json');
    List<dynamic> sweMuni = json.decode(response);

    List<String> list = [];

    sweMuni.forEach((element) {
      list.add(element);
    });

    String desc = trans1.store!;
    String desc1 = trans2.store!;
    list.sort((a, b) => b.length.compareTo(a.length));
    String result = Utils.removeStopWords(desc, list);
    String result1 = Utils.removeStopWords(desc1, list);

    if (Utils.isSimilarStoreName(result, result1, 0.3)) {
      return true;
    }
    return false;
  }

  static Future<bool> areBankTransactionsEqual(
      BankTransaction trans1, BankTransaction trans2) async {
    String response =
        await rootBundle.loadString('assets/swedish_municipalities.json');
    List<dynamic> sweMuni = json.decode(response);

    List<String> list = [];

    sweMuni.forEach((element) {
      list.add(element);
    });

    if (trans1.amount.abs() == trans2.amount.abs() &&
        Utils.isSimilarDate(trans1.date, trans2.date)) {
      String desc = trans1.description;
      String desc1 = trans2.description;
      list.sort((a, b) => b.length.compareTo(a.length));
      String result = Utils.removeStopWords(desc, list);
      String result1 = Utils.removeStopWords(desc1, list);

      if (Utils.isSimilarStoreName(result, result1, 0.4)) return true;
    }
    return false;
  }
}
