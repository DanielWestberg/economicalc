import 'package:economicalc_client/models/transaction_event.dart';

class Utils {
  static List<TransactionEvent> getMockedTransactions() {
    return [
      TransactionEvent(
        userID: 1,
        recipient: "Ica",
        date: DateTime(2022, 10, 24),
        amount: 204.5,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Willys",
        date: DateTime(2022, 10, 24),
        amount: 55.00,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Donken",
        date: DateTime(2022, 10, 24),
        amount: 75.99,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "H&M",
        date: DateTime(2022, 10, 25),
        amount: 300.00,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Hemköp",
        date: DateTime(2022, 10, 27),
        amount: 109.99,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Donken",
        date: DateTime(2022, 10, 28),
        amount: 68.99,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Donken",
        date: DateTime(2022, 10, 24),
        amount: 75.99,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "H&M",
        date: DateTime(2022, 10, 25),
        amount: 300.00,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Hemköp",
        date: DateTime(2022, 10, 27),
        amount: 109.99,
        items: getMockedReceiptItems(),
      ),
      TransactionEvent(
        userID: 1,
        recipient: "Donken",
        date: DateTime(2022, 10, 28),
        amount: 68.99,
        items: getMockedReceiptItems(),
      ),
    ];
  }

  static List<ReceiptItem> getMockedReceiptItems() {
    return [
      ReceiptItem(itemName: "Tomatoes", quantity: 19, price: 21.99, sum: 21.99),
      ReceiptItem(itemName: "Potatoes", quantity: 32, price: 15.99, sum: 15.99),
      ReceiptItem(itemName: "Marabou", quantity: 2, price: 20.00, sum: 40.00),
      ReceiptItem(itemName: "Onion", quantity: 30, price: 21.00, sum: 40.00),
      ReceiptItem(itemName: "Garlic", quantity: 20, price: 22.00, sum: 40.00),
      ReceiptItem(itemName: "Cucumber", quantity: 15, price: 23.00, sum: 40.00),
      ReceiptItem(itemName: "Flour", quantity: 5, price: 24.00, sum: 40.00),
      ReceiptItem(itemName: "Yeast", quantity: 10, price: 25.00, sum: 40.00),
      ReceiptItem(itemName: "Hat", quantity: 59, price: 26.00, sum: 40.00),
      ReceiptItem(itemName: "Cheese", quantity: 1, price: 27.00, sum: 40.00),
      ReceiptItem(itemName: "Milk", quantity: 3, price: 28.00, sum: 40.00),
      ReceiptItem(itemName: "Yoghurt", quantity: 5, price: 29.00, sum: 40.00),
      ReceiptItem(itemName: "Pasta", quantity: 3, price: 30.00, sum: 40.00),
      ReceiptItem(itemName: "Meatballs", quantity: 2, price: 31.00, sum: 41.00),
    ];
  }
}
