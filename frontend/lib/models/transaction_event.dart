import 'package:intl/intl.dart';

class TransactionEvent {
  String userId;
  String transactionId;
  String recipient;
  DateTime date;
  double totalSum;
  List<ReceiptItem> items;

  TransactionEvent(
      {required this.userId,
      required this.transactionId,
      required this.recipient,
      required this.date,
      required this.totalSum,
      required this.items});

  factory TransactionEvent.fromJson(Map<String, dynamic> json) {
    List<ReceiptItem> items = json["items"]
        .map((e) => ReceiptItem.fromJson(e))
        .toList()
        .cast<ReceiptItem>();

    return TransactionEvent(
        userId: json['userId'],
        transactionId: json['transactionId'],
        recipient: json['recipient'],
        date: DateFormat('yyyy-MM-dd').parse(json['date']),
        totalSum: items.fold(0, (totalSum, item) => totalSum + item.sum),
        items: items);
  }
}

class ReceiptItem {
  String itemId;
  String itemName;
  int quantity;
  double price;
  double sum;

  ReceiptItem(
      {required this.itemId,
      required this.itemName,
      required this.quantity,
      required this.price,
      required this.sum});

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemId: json['itemId'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      price: json['price'],
      sum: json['quantity'] * json['price'],
    );
  }
}
