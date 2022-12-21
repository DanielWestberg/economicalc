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
  String? backendId;
  String ocrText;

  Receipt({
    this.id,
    required this.recipient,
    required this.date,
    this.total,
    required this.items,
    this.categoryDesc,
    this.categoryID,
    this.backendId,
    required this.ocrText,
  });

  @override
  operator ==(Object? other) => (other is Receipt &&
      id == other.id &&
      recipient == other.recipient &&
      date == other.date &&
      total == other.total &&
      categoryDesc == other.categoryDesc &&
      items.every((item) => other.items.contains(item)) &&
      categoryID == other.categoryID &&
      backendId == other.backendId);

  @override
  get hashCode => (id.hashCode |
      recipient.hashCode |
      date.hashCode |
      total.hashCode |
      categoryDesc.hashCode |
      items.fold(
          0, (previousValue, element) => previousValue | element.hashCode) |
      categoryID.hashCode |
      backendId.hashCode);

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> items = [];
    for (ReceiptItem item in this.items) {
      items.add(item.toJson());
    }

    var result = {
      'recipient': recipient,
      'date': date.toIso8601String(),
      'total': total,
      'categoryDesc': categoryDesc,
      'items': items,
      'categoryID': categoryID,
      'ocrText': ocrText
    };

    if (backendId != null) {
      result["_id"] = backendId;
    }

    return result;
  }

  @override
  toString() {
    return "Receipt ${backendId ?? ""}: "
        "{$recipient, $date, $total, $items, $categoryID}";
  }

  factory Receipt.fromBackendJson(Map<String, dynamic> json) {
    List<ReceiptItem> items = json["items"]
        .map((i) => ReceiptItem.fromJson(i))
        .toList()
        .cast<ReceiptItem>();

    return Receipt(
        recipient: json["recipient"],
        date: DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'")
            .parseUtc(json["date"]),
        total: json["total"],
        items: items,
        categoryID: json["categoryID"],
        backendId: json["_id"],
        ocrText: json["ocr_text"]);
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
        items: items,
        ocrText: json['receipts'][0]["ocr_text"]);
  }
}

class ReceiptItem {
  String? itemId;
  String itemName;
  double amount;

  ReceiptItem({required this.itemName, required this.amount, this.itemId});

  @override
  toString() {
    return "{$itemName, $amount}";
  }

  @override
  operator ==(Object? other) => (other is ReceiptItem &&
      itemId == other.itemId &&
      itemName == other.itemName &&
      amount == other.amount);

  @override
  get hashCode => (itemId.hashCode | itemName.hashCode | amount.hashCode);

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
