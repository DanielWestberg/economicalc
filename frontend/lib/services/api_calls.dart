import 'package:economicalc_client/models/transaction_event.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const apiServer = "";

Future<List<TransactionEvent>> fetchMockedTransactions() async {
  final String response =
      await rootBundle.loadString('assets/random_generated_transactions.json');

  return (json.decode(response) as List)
      .map((e) => TransactionEvent.fromJson(e))
      .toList()
      .cast<TransactionEvent>();
}

Future<List<ReceiptItem>> fetchMockedReceiptItems() async {
  final String response =
      await rootBundle.loadString('assets/random_generated_transactions.json');

  return (json.decode(response) as List)
      .map((e) => TransactionEvent.fromJson(e))
      .toList()
      .cast<TransactionEvent>()[0]
      .items;
}
