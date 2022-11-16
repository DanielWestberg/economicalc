class TransactionEvent {
  int userID;
  String recipient;
  DateTime date;
  num amount;
  List<ReceiptItem> items;

  TransactionEvent(
      {required this.userID,
      required this.recipient,
      required this.date,
      required this.amount,
      required this.items});
}

class ReceiptItem {
  String itemName;
  int quantity;
  num price;
  num sum;

  ReceiptItem(
      {required this.itemName,
      required this.quantity,
      required this.price,
      required this.sum});
}
