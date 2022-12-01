import 'dart:convert';

import 'package:economicalc_client/models/category.dart';
import 'package:intl/intl.dart';

class Receipt {
  int? id;
  String recipient;
  DateTime date;
  double? total;
  String? categoryDesc;
  List<ReceiptItem> items;
  int? categoryID;

  Receipt(
      {this.id,
      required this.recipient,
      required this.date,
      this.total,
      required this.items,
      this.categoryDesc,
      this.categoryID});

  Map<String, dynamic> toMap() {
    return {
      'recipient': recipient,
      'date': date.toIso8601String(),
      'total': total,
      'categoryDesc': categoryDesc,
      'items': jsonEncode(items),
      'categoryID': categoryID
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    List<ReceiptItem> items = json['receipts'][0]["items"]
        .map((e) => ReceiptItem.fromJsonScanned(e))
        .toList()
        .cast<ReceiptItem>();

    return Receipt(
        recipient: json['receipts'][0]['merchant_name'],
        date: DateFormat('yyyy-MM-dd').parse(json['receipts'][0]['date']),
        total: json['receipts'][0]['total'],
        items: items);
  }
}

class ReceiptItem {
  String? itemId;
  String itemName;
  double amount;

  ReceiptItem({required this.itemName, required this.amount, this.itemId});

  Map<String, dynamic> toJson() {
    return {'itemName': itemName, 'amount': amount, 'itemId': itemId};
  }

  factory ReceiptItem.fromJsonScanned(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['description'],
      amount: json['amount'],
    );
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['itemName'],
      amount: json['amount'],
    );
  }
}
