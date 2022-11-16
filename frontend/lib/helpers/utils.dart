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
      ReceiptItem(
          id: 0,
          itemName: "Tomatoes",
          quantity: 19,
          price: 21.99,
          sum: 19 * 21.99),
      ReceiptItem(
          id: 1,
          itemName: "Potatoes",
          quantity: 32,
          price: 15.99,
          sum: 32 * 15.99),
      ReceiptItem(
          id: 2,
          itemName: "Marabou",
          quantity: 2,
          price: 20.00,
          sum: 2 * 20.00),
      ReceiptItem(
          id: 3,
          itemName: "Onion",
          quantity: 30,
          price: 21.00,
          sum: 30 * 21.00),
      ReceiptItem(
          id: 4,
          itemName: "Garlic",
          quantity: 20,
          price: 22.00,
          sum: 20 * 22.00),
      ReceiptItem(
          id: 5,
          itemName: "Cucumber",
          quantity: 15,
          price: 23.00,
          sum: 15 * 23.00),
      ReceiptItem(
          id: 6, itemName: "Flour", quantity: 5, price: 24.00, sum: 5 * 24.00),
      ReceiptItem(
          id: 7,
          itemName: "Yeast",
          quantity: 10,
          price: 25.00,
          sum: 10 * 25.00),
      ReceiptItem(
          id: 8, itemName: "Hat", quantity: 10, price: 26.00, sum: 10 * 26.00),
      ReceiptItem(
          id: 9, itemName: "Cheese", quantity: 1, price: 27.00, sum: 1 * 27.00),
      ReceiptItem(
          id: 10, itemName: "Milk", quantity: 3, price: 28.00, sum: 3 * 28.00),
      ReceiptItem(
          id: 11,
          itemName: "Yoghurt",
          quantity: 5,
          price: 29.00,
          sum: 5 * 29.00),
      ReceiptItem(
          id: 12, itemName: "Pasta", quantity: 3, price: 30.00, sum: 3 * 30.00),
      ReceiptItem(
          id: 13,
          itemName: "Meatballs",
          quantity: 2,
          price: 31.00,
          sum: 2 * 31.00),
      ReceiptItem(
          id: 13,
          itemName: "Spaghetti",
          quantity: 1,
          price: 15.00,
          sum: 1 * 15.00),
      ReceiptItem(
          id: 13, itemName: "Apple", quantity: 1, price: 15.00, sum: 1 * 15.00),
      ReceiptItem(
          id: 13, itemName: "Pear", quantity: 1, price: 15.00, sum: 1 * 15.00),
      ReceiptItem(
          id: 13,
          itemName: "Banana",
          quantity: 1,
          price: 15.00,
          sum: 1 * 15.00),
      ReceiptItem(
          id: 13,
          itemName: "Nutella",
          quantity: 1,
          price: 15.00,
          sum: 1 * 15.00),
    ];
  }
}
