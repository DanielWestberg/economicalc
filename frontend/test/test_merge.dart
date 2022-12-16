// Import the test package and Counter class
// ignore: depend_on_referenced_packages
import 'dart:convert';

import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

void runTest(String sname1, String sname2, double amount1, double amount2,
    String date1, String date2, bool one, bool two, bool three) async {
  String unscaledVal = (-amount1 * 10).toString();
  Value value = Value(unscaledValue: unscaledVal, scale: "1");
  Amount amount = Amount(value: value, currencyCode: "SEK");
  Descriptions descriptions = Descriptions(original: "ICA", display: sname1);
  Dates dates = Dates(booked: date2);
  BankTransaction transaction =
      BankTransaction(amount: amount, descriptions: descriptions, dates: dates);
  double damount =
      (double.parse(transaction.amount.value.unscaledValue) / 10).abs();

  Receipt receipt = Receipt(
      recipient: sname2,
      date: DateTime.parse(date1),
      items: [],
      total: amount2);

  bool sameAmount = receipt.total == damount;
  bool similarName = Utils.isSimilarStoreName(
      transaction.descriptions.display, receipt.recipient);
  bool similarDate = Utils.isSimilarDate(
      DateTime.parse(transaction.dates.booked), receipt.date);

  String response =
      await rootBundle.loadString('assets/swedish_municipalities.json');
  List<String> sweMuni = json.decode(response);

  print("Checking if ${receipt.total} == ${damount}...");
  expect(sameAmount, one);

  String desc = transaction.descriptions.display;
  for (String municipality in sweMuni) {
    desc.toLowerCase().replaceAll(municipality.toLowerCase(), "");
  }
  print("Checking if $desc == ${receipt.recipient}...");
  expect(desc, two);
  print("Checking if ${transaction.dates.booked} == ${receipt.date}...");
  expect(similarDate, three);
}

void main() {
  test('String similarity', () {
    runTest("ICA Nära", "Ica Uppsala", 75, 75, "2022-10-11", "2022-10-11", true,
        true, true);
  });
  test('String similarity 2', () {
    runTest("Ica", "Ica Uppsala", 100, 100, "2022-12-13", "2022-12-13", true,
        true, true);
  });
  test('String similarity 3', () {
    runTest(
        "IKEA", "Ica", 100, 100, "2022-12-13", "2022-12-13", true, false, true);
  });
  test('String similarity 4', () {
    runTest("Stora Coop", "Coop", 100, 100, "2022-12-13", "2022-12-13", true,
        true, true);
  });
  test('String similarity 5', () {
    runTest("Stora Coop Uppsala", "Coop Uppsala", 100, 100, "2022-12-13",
        "2022-12-13", true, true, true);
  });
  test('String similarity 6', () {
    runTest("ICA Uppsala", "Coop Uppsala", 100, 100, "2022-12-13", "2022-12-13",
        true, false, true);
  });
  test('String similarity 7', () {
    runTest("WILLYS VÄSBY CENTRUM, UPPLANDSVÄSBY", "WILLYS MÄRSTA, MÄRSTA", 100,
        100, "2022-12-13", "2022-12-13", true, false, true);
  });
}
