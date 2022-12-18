import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/material.dart';
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
  static Color lightColor = Color(0xffD4E6F3);
  static Color mediumLightColor = Color(0xFFB8D8D8);
  static Color mediumDarkColor = Color(0xff7a9e9f);
  static Color darkColor = Color.fromARGB(255, 68, 104, 107);
  static Color errorColor = Color(0xFFfe5f55);

  static List<TransactionCategory> categories = [
    TransactionCategory(description: "Groceries", color: Colors.blue),
    TransactionCategory(description: "Transportation", color: Colors.purple),
    TransactionCategory(description: "Stuff", color: Colors.green),
    TransactionCategory(
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

  static bool isSimilarDate(DateTime receiptDate, DateTime bankTransDate) {
    return receiptDate.add(const Duration(days: 3)).compareTo(bankTransDate) >=
        0;
  }

  static String removeStopWords(String word, List<String> stopwords) {
    for (String municipality in stopwords) {
      //print(municipality.toLowerCase().trim().replaceAll(" ", ""));
      //print(desc.toLowerCase().trim());
      word = word.toLowerCase().trim().replaceAll(
          municipality.toLowerCase().trim().replaceAll(" ", ""), "");
    }
    return word;
  }

  static bool isSimilarStoreName(String name1, String name2) {
    print(StringSimilarity.compareTwoStrings(
        name1.toLowerCase(), name2.toLowerCase()));

    return StringSimilarity.compareTwoStrings(
            name1.toLowerCase().trim(), name2.toLowerCase().trim()) >
        0.4;
  }
}
