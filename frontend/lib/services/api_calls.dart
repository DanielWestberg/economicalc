import 'package:economicalc_client/helpers/quota_exception.dart';
import 'package:economicalc_client/models/response.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert' as convert;

import '../models/LoginData.dart';

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([
    this.message = "Login via bank required"
  ]);

  @override
  String toString() => "UnauthorizedException: $message";
}

class ApiCaller {
  final bool testMode;
  final String apiServer;
  Cookie? _cookie;

  static const String _tinkReportEndpoint =
      "https://link.tink.com/1.0/reports/create-report"
      "?client_id=1a539460199a4e8bb374893752db14e6"
      "&redirect_uri=https://console.tink.com/callback&market=SE"
      "&report_types=TRANSACTION_REPORT,ACCOUNT_VERIFICATION_REPORT"
      "&refreshable_items="
      "IDENTITY_DATA"
      ",CHECKING_ACCOUNTS"
      ",SAVING_ACCOUNTS"
      ",CHECKING_TRANSACTIONS"
      ",SAVING_TRANSACTIONS"
      "&account_dialog_type=SINGLE";
  String get tinkReportEndpoint => _tinkReportEndpoint;

  ApiCaller._privateConstructor(this.testMode):
      apiServer = testMode ? "192.168.0.165:5000" : "api.economicalc.online";

  static ApiCaller nonTestInstance =
      ApiCaller._privateConstructor(false);
  static ApiCaller testInstance =
      kDebugMode ? ApiCaller._privateConstructor(true) : nonTestInstance;

  factory ApiCaller([bool testMode = true]) =>
    testMode ? testInstance : nonTestInstance;

  Uri getUri(String path) {
    if (testMode) {
      return Uri.http(apiServer, path);
    }

    return Uri.https(apiServer, path);
  }

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

  Future<LoginData> fetchLoginData(
      String account_report_id, String transaction_report_id, bool test) async {
    var headers = {
      'Content-type': 'application/json',
    };

    var data = {
      "account_report_id": account_report_id,
      "transaction_report_id": transaction_report_id
    };

    final testString = test ? "T" : "F";
    String path = ('tink_user_data/$testString');
    var uri = getUri(path);
    var response =
    await http.post(uri, headers: headers, body: json.encode(data));
    //print(uri);
    //print(response);
    if (response.statusCode != 200) {
      throw Exception('http.get error: statusCode= ${response.statusCode}');
    }
    //print(response.body);
    _cookie = Cookie.fromSetCookieValue(response.headers["set-cookie"] ?? "");
    return LoginData.fromResponse(response);
  }

  Future<List<BankTransaction>> fetchTransactions(String access_token) async {
    //print("INSIDE TRANSACTIOn");
    String path = '/tink_transaction_history/';
    path += access_token;
    final response = await http.get(getUri(path));
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

  Future<Response> CodeToAccessToken(String code, bool test) async {
    String path = '/tink_access_token/';
    path += code;
    if (test)
      path += '/T';
    else
      path += '/F';
    print("PATH: " + path);
    print("APISERVER: " + apiServer);
    print("URIU PÅATH");
    print(getUri(path));
    final response = await http.get(getUri(path));
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
    if (response.statusCode == 429) {
      throw QuotaException("Too many requests in a short time period");
    }
    if (response.statusCode != 200) {
      throw HttpException("Bad request");
    }
    final respStr = await response.stream.bytesToString();
    final respJson = await json.decode(respStr);
    if (respJson.containsKey("message")) {
      if (respJson['message'] ==
          'Hourly quota exceeded. Try again in a few hours or contact us to increase the quota: ocr@asprise.com') {
        throw QuotaException(respJson['message']);
      } else {
        throw Exception(respJson['message']);
      }
    }
    print(respJson);
    return respJson;
  }

  void _assertCookieNotNull() {
    if (_cookie == null) {
      throw const UnauthorizedException();
    }
  }

  fetchReceipts() async {
    _assertCookieNotNull();
    const String path = "/receipts";
    final Map<String, String> headers = {
      "Cookie": _cookie.toString(),
    };

    final response = await http.get(getUri(path), headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n{response.body}");
    }
    List<dynamic> receipts = convert.jsonDecode(response.body)["data"];
    List<Receipt> resultReceipts = [];
    for (dynamic receipt in receipts) {
      resultReceipts.add(Receipt.fromBackendJson(receipt));
    }

    return resultReceipts;
  }

  postReceipt(Receipt receipt) async {
    _assertCookieNotNull();
    const String path = "/receipts";
    final Uri uri = getUri(path);
    final headers = {
      "Content-type": "application/json",
      "Cookie": _cookie.toString(),
    };
    final body = convert.jsonEncode(receipt.toMap());
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode != 201) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
    return Receipt.fromBackendJson(convert.jsonDecode(response.body)["data"]);
  }

  updateReceipt(int receiptId, Receipt receipt) async {
    _assertCookieNotNull();
    final uri = getUri("/receipts/$receiptId");
    final headers = {
      "Content-type": "application/json",
      "Cookie": _cookie.toString(),
    };
    final body = convert.jsonEncode(receipt.toMap());
    final response = await http.put(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
  }

  deleteReceipt(Receipt receipt) async {
    _assertCookieNotNull();
    final uri = getUri("/receipts/${receipt.id}");
    final Map<String, String> headers = {
      "Cookie": _cookie.toString(),
    };
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 204) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
  }

  updateImage(int receiptId, XFile image) async {
    _assertCookieNotNull();
    final uri = getUri("/receipts/$receiptId/image");
    final mimeType = image.mimeType ?? "application/octet-stream";
    final request = http.MultipartRequest("PUT", uri)
      ..files.add(await http.MultipartFile.fromPath("file", image.path,
          contentType: http_parser.MediaType.parse(mimeType)));
    request.headers["Cookie"] = _cookie.toString();
    final response = await request.send();
    if (response.statusCode != 204) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${await response.stream.bytesToString()}");
    }
  }

  fetchImage(int receiptId) async {
    _assertCookieNotNull();
    final uri = getUri("/receipts/$receiptId/image");
    final Map<String, String> headers = {
      "Cookie": _cookie.toString(),
    };
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
    return XFile.fromData(response.bodyBytes);
  }

  deleteImage(int receiptId) async {
    _assertCookieNotNull();
    final uri = getUri("/receipts/$receiptId/image");
    final Map<String, String> headers = {
      "Cookie": _cookie.toString(),
    };
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 204) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
  }

  fetchCategories() async {
    _assertCookieNotNull();
    final uri = getUri("/categories");
    final Map<String, String> headers = {
      "Cookie": _cookie.toString(),
    };
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }

    List<dynamic> categories = convert.jsonDecode(response.body)["data"];
    return categories.map((e) => TransactionCategory.fromJson(e)).toList();
  }

  postCategory(TransactionCategory category) async {
    _assertCookieNotNull();
    final uri = getUri("/categories");
    final headers = {
      "Content-type": "application/json",
      "Cookie": _cookie.toString(),
    };
    final body = convert.jsonEncode(category.toJson(true));
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode != 201) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
  }

  updateCategory(TransactionCategory category) async {
    _assertCookieNotNull();
    final uri = getUri("/categories/${category.id!}");
    final headers = {
      "Content-type": "application/json",
      "Cookie": _cookie.toString(),
    };
    final body = convert.jsonEncode(category.toJson(true));
    final response = await http.put(uri, headers: headers, body: body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
  }

  deleteCategory(int categoryId) async {
    _assertCookieNotNull();
    final uri = getUri("/categories/$categoryId");
    final Map<String, String> headers = {
      "Cookie": _cookie.toString(),
    };
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 204) {
      throw Exception(
          "Unexpected status code ${response.statusCode}\n${response.body}");
    }
  }
}