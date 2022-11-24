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

  factory Receipt.fromJson(Map<String, dynamic> json) {
    List<ReceiptItem> items = json['receipts'][0]["items"]
        .map((e) => ReceiptItem.fromJson(e))
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

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['description'],
      amount: json['amount'],
    );
  }
}
