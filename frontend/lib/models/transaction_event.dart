import 'dart:convert';

import 'package:intl/intl.dart';

class Receipt {
  String? userId;
  String transactionId;
  String recipient;
  DateTime date;
  double? total;
  int? totalSumKr;
  int? totalSumOre;
  String? totalSumStr;
  List<ReceiptItem> items;

  Receipt(
      {this.userId,
      required this.transactionId,
      required this.recipient,
      required this.date,
      this.total,
      this.totalSumKr,
      this.totalSumOre,
      this.totalSumStr,
      required this.items});

  Map<String, dynamic> toMap() {
    
    return {
      'userId': userId,
      'transactionId': transactionId,
      'recipient': recipient,
      'date': date.toIso8601String(),
      'total': total,
      'totalSumKr': totalSumKr,
      'totalSumOre': totalSumOre,
      'totalSumStr': totalSumStr,
      'items': jsonEncode(items),
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    List<ReceiptItem> items = json['receipts'][0]["items"]
        .map((e) => ReceiptItem.fromJsonScanned(e))
        .toList()
        .cast<ReceiptItem>();

    return Receipt(
        transactionId: json['request_id'],
        recipient: json['receipts'][0]['merchant_name'],
        date: DateFormat('yyyy-MM-dd').parse(json['receipts'][0]['date']),
        total: json['receipts'][0]['total'],
        items: items);
  }

}

class ReceiptItem {
  String? itemId;
  String itemName;
  int? quantity;
  double amount;
  int? priceKr;
  int? priceOre;
  int? sumKr;
  int? sumOre;
  String? priceStr;
  String? sumStr;

  ReceiptItem(
      {required this.itemName,
      required this.amount,
      this.itemId,
      this.quantity,
      this.priceKr,
      this.priceOre,
      this.sumKr,
      this.sumOre,
      this.priceStr,
      this.sumStr});

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'amount': amount,
      'itemId': itemId,
      'quantity': quantity,
      'priceKr':priceKr,
      'priceOre': priceOre,
      'sumKr': sumKr,
      'sumOre':sumOre,
      'priceStr': priceStr,
      'sumStr': sumStr,
    };
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
