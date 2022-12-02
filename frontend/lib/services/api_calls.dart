import 'package:economicalc_client/models/response.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert' as convert;

const String apiServer = "192.168.1.6:5000";

Future<List<Receipt>> fetchMockedTransactions() async {
  final String response =
      await rootBundle.loadString('assets/ocr_outputs.json');

  return (json.decode(response) as List)
      .map((e) => Receipt.fromJson(e))
      .toList()
      .cast<Receipt>();
}

Future<Receipt> fetchOneMockedTransaction() async {
  final String response =
      await rootBundle.loadString('assets/ocr_outputs.json');

  Receipt transaction = Receipt.fromJson(json.decode(response)[0]);
  return transaction;
}

Future<List<ReceiptItem>> fetchMockedReceiptItems() async {
  final String response =
      await rootBundle.loadString('assets/ocr_outputs.json');

  return (json.decode(response) as List)
      .map((e) => Receipt.fromJson(e))
      .toList()
      .cast<Receipt>()[0]
      .items;
}

Future<List<BankTransaction>> fetchTransactions(String access_token) async {
  //print("INSIDE TRANSACTIOn");
  String path = '/tink_transaction_history/';
  path += access_token;
  final response = await http.get(Uri.http(apiServer, path));
  if (response.statusCode == 200) {
    List<dynamic> transactions =
        convert.jsonDecode(response.body)["transactions"];
    //print(transactions);
    List<BankTransaction> resTrans = [];
    transactions.forEach((transaction) {
      resTrans.add(BankTransaction.fromJson(transaction));
    });
    //print("RESTRANSACT");
    //print(resTrans);

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

Future<List<ReceiptItem>> fetchMockedReceiptItemsBetweenDates(
    DateTime startDate, DateTime endDate) async {
  final String response =
      await rootBundle.loadString('assets/ocr_outputs.json');

  List<Receipt> transactions = (json.decode(response) as List)
      .map((e) => Receipt.fromJson(e))
      .toList()
      .cast<Receipt>();

  List<ReceiptItem> filteredItems = [];

  transactions.forEach((element) {
    if (element.date.compareTo(startDate) >= 0 &&
        element.date.compareTo(endDate) <= 0) {
      element.items.forEach((item) => filteredItems.add(item));
    }
  });

  return filteredItems;
}

processImageWithAsprise(File imageFile) async {
  String receiptOcrEndpoint = "https://ocr.asprise.com/api/v1/receipt";

  var stream = new http.ByteStream((imageFile.openRead()));
  // stream.cast();

  var length = await imageFile.length();

  var uri = Uri.parse(receiptOcrEndpoint);

  var request = new http.MultipartRequest("POST", uri);
  request.fields['api_key'] = 'TEST';
  request.fields['recognizer'] = 'auto';
  request.fields['ref_no'] = 'my_ref_123';

  var multipartFile = new http.MultipartFile('file', stream, length,
      filename: basename(imageFile.path));

  request.files.add(multipartFile);

  var response = await request.send();
  if (response.statusCode == 200) print('Success');
  final respStr = await response.stream.bytesToString();
  final respJson = await json.decode(respStr);
  return respJson;
}

fetchReceipts(String userId) async {
  final String path = "/users/$userId/receipts";
  final response = await http.get(Uri.http(apiServer, path));
  if (response.statusCode != 200) {
    throw Exception(
        "Unexpected status code ${response.statusCode}\n{response.body}"
    );
  }
  List<dynamic> receipts = convert.jsonDecode(response.body)["data"];
  List<Receipt> resultReceipts = [];
  for (dynamic receipt in receipts) {
    resultReceipts.add(Receipt.fromBackendJson(receipt));
  }

  return resultReceipts;
}

postReceipt(String userId, Receipt receipt) async {
  final String path = "/users/$userId/receipts";
  final Uri uri = Uri.http(apiServer, path);
  final headers = {"Content-type": "application/json"};
  final body = convert.jsonEncode(receipt.toMap());
  final response = await http.post(uri, headers: headers, body: body);
  if (response.statusCode != 201) {
    throw Exception(
      "Unexpected status code ${response.statusCode}\n${response.body}"
    );
  }
}

updateImage(String userId, String receiptId, XFile image) async {
  final uri = Uri.http(apiServer, "/users/$userId/receipts/$receiptId/image");
  final mimeType = image.mimeType ?? "application/octet-stream";
  final request = http.MultipartRequest("PUT", uri)
    ..files.add(await http.MultipartFile.fromPath(
      "file", image.path, contentType: http_parser.MediaType.parse(mimeType)
    ));
  final response = await request.send();
  if (response.statusCode != 204) {
    throw Exception(
      "Unexpected status code ${response.statusCode}\n${await response.stream.bytesToString()}"
    );
  }
}

fetchImage(String userId, String receiptId) async {
  final uri = Uri.http(apiServer, "/users/$userId/receipts/$receiptId/image");
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception(
        "Unexpected status code ${response.statusCode}\n${response.body}"
    );
  }
  return XFile.fromData(response.bodyBytes);
}
