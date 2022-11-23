import 'package:intl/intl.dart';

class TransactionEvent {
  String userId;
  String transactionId;
  String recipient;
  DateTime date;
  int totalSumKr;
  int totalSumOre;
  String totalSumStr;
  List<ReceiptItem> items;

  TransactionEvent(
      {required this.userId,
      required this.transactionId,
      required this.recipient,
      required this.date,
      required this.totalSumKr,
      required this.totalSumOre,
      required this.totalSumStr,
      required this.items});

  factory TransactionEvent.fromJson(Map<String, dynamic> json) {
    List<ReceiptItem> items = json["items"]
        .map((e) => ReceiptItem.fromJson(e))
        .toList()
        .cast<ReceiptItem>();

    int totalSumOre =
        items.fold(0, (totalSumOre, item) => totalSumOre + item.sumOre);
    int totalSumKr =
        items.fold(0, (totalSumKr, item) => totalSumKr + item.sumKr) +
            totalSumOre ~/ 100;
    totalSumOre = totalSumOre % 100;

    return TransactionEvent(
        userId: json['userId'],
        transactionId: json['transactionId'],
        recipient: json['recipient'],
        date: DateFormat('yyyy-MM-dd').parse(json['date']),
        totalSumKr: totalSumKr,
        totalSumOre: totalSumOre,
        totalSumStr:
            "${NumberFormat.decimalPattern('sv-se').format(totalSumKr)},${totalSumOre.toString().padLeft(2, '0')}",
        items: items);
  }
}

class ReceiptItem {
  String itemId;
  String itemName;
  int quantity;
  int priceKr;
  int priceOre;
  int sumKr;
  int sumOre;
  String priceStr;
  String sumStr;

  ReceiptItem(
      {required this.itemId,
      required this.itemName,
      required this.quantity,
      required this.priceKr,
      required this.priceOre,
      required this.sumKr,
      required this.sumOre,
      required this.priceStr,
      required this.sumStr});

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    int sumOre = json['quantity'] * json['priceOre'];
    int sumKr = json['quantity'] * json['priceKr'] + sumOre ~/ 100;
    sumOre = sumOre % 100;

    return ReceiptItem(
      itemId: json['itemId'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      priceKr: json['priceKr'],
      priceOre: json['priceOre'],
      sumKr: sumKr,
      sumOre: sumOre,
      priceStr:
          "${NumberFormat.decimalPattern('sv-se').format(json['priceKr'])},${json['priceOre'].toString().padLeft(2, '0')}",
      sumStr:
          "${NumberFormat.decimalPattern('sv-se').format(sumKr)},${sumOre.toString().padLeft(2, '0')}",
    );
  }
}
