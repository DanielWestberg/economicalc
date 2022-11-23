import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import '../models/transaction.dart';

const apiServer = "127.0.0.1:5000/";

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

Future<List<Transaction>> fetchTransactions(String access_token) async {
  String path = '/tink_transaction_history/';
  path += access_token;
  final response = await http.get(Uri.https(apiServer, path));
  if (response.statusCode == 200) {
    List<Transaction> transactions = convert.jsonDecode(response.body);
    return transactions;
  } else {
    throw Exception("No transactions associated with user");
  }
}

Future<String> CodeToAccessToken(String code) async {
  String path = '/tink_access_token/';
  path += code;
  final response = await http.get(Uri.https(apiServer, path));
  if (response.statusCode == 200) {
    String access_token = convert.jsonDecode(response.body);
    return access_token;
  } else {
    return "ERROR WITH CODE";
  }
}
