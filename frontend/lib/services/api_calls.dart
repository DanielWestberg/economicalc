import 'package:economicalc_client/models/response.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import '../models/transaction.dart';

const String apiServer = "192.168.1.6:5000";

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
  print("INSIDE TRANSACTIOn");
  String path = '/tink_transaction_history/';
  path += access_token;
  final response = await http.get(Uri.http(apiServer, path));
  if (response.statusCode == 200) {
    List<dynamic> transactions =
        convert.jsonDecode(response.body)["transactions"];
    print(transactions);
    List<Transaction> resTrans = [];
    transactions.forEach((transaction) {
      resTrans.add(Transaction.fromJson(transaction));
    });
    print("RESTRANSACT");
    print(resTrans);

    return resTrans;
  } else {
    throw Exception("No transactions associated with user");
  }
}

Future<Response> CodeToAccessToken(String code) async {
  String path = '/tink_access_token/';
  path += code;
  print("PATH: " + path);
  print("APISERVER: " + apiServer);
  print("URIU PÅATH");
  print(Uri.https(apiServer, path));
  final response = await http.get(Uri.http(apiServer, path));
  print("Hej");
  print("response: ${response.body}");
  Response accessToken = Response.fromJson(convert.jsonDecode(response.body));
  print("after response convert");
  return accessToken;
}
