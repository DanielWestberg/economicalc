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
  int id;
  String itemName;
  int quantity;
  double price;
  double sum;

  ReceiptItem(
      {required this.id,
      required this.itemName,
      required this.quantity,
      required this.price,
      required this.sum});
}
