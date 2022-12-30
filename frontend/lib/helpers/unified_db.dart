import 'dart:io';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';

// Acts as common interface for local db and backend db.
class UnifiedDb implements SQFLite {
  SQFLite? _localDb;
  SQFLite get localDb {
    _localDb ??= SQFLite.instance;
    return _localDb!;
  }

  @override
  initDatabase() async => localDb.initDatabase();

  @override
  Future<void> wipeDB() async => localDb.wipeDB();

  /********** TRANSACTIONS **********/

  //@override
  //Future<void> insertTransaction(Transaction transaction) async {}

  @override
  Future<int> numOfCategoriesWithSameName(Transaction transaction) async =>
      localDb.numOfCategoriesWithSameName(transaction);

  @override
  Future<void> assignCategories(Transaction transaction) async =>
      localDb.assignCategories(transaction);

  //@override
  //Future<List<Transaction>> getAllTransactions() async {}

  @override
  Future<List<Transaction>> getFilteredTransactions(
      DateTime startDate,
      DateTime endDate,
      TransactionCategory category,
      bool onlyReceipts,
      ) async {

    final TransactionFilter filter = TransactionFilter(
      startDate: startDate,
      endDate: endDate,
      category: category,
      onlyReceipts: onlyReceipts,
    );

    return filter(await getAllTransactions()).toList();
  }

  @override
  Future<Transaction?> getTransactionByReceiptID(int receiptID) async =>
      localDb.getTransactionByReceiptID(receiptID);

  //@override
  //Future<void> updateTransaction(Transaction transaction) async {}

  //@override
  //Future<void> deleteTransaction(int id) async {}

  //@override
  //Future<void> deleteAllTransactions() async {}

  @override
  Map<String, dynamic> encodeTransaction(Transaction transaction) =>
      localDb.encodeTransaction(transaction);

  @override
  Future<Receipt?> checkForExistingReceipt(Transaction transaction) =>
      localDb.checkForExistingReceipt(transaction);

  @override
  Future<Transaction?> checkForExistingTransaction(Transaction transaction) =>
      localDb.checkForExistingTransaction(transaction);

  //@override
  //Future<List<int>> updateTransactions() {}

  /********** BANKTRANSACTIONS **********/

  @override
  Future<List<BankTransaction>> getAllBankTransactions() =>
      localDb.getAllBankTransactions();

  //@override
  //Future<void> postBankTransaction(BankTransaction bankTransaction) {}

  //@override
  //Future<void> postMissingBankTransactions(
      //List<BankTransaction> updatedBankTransactions
      //) {}

  //@override
  //Future<void> deleteAllBankTransactions() {}

  @override
  Future<BankTransaction> getBankTransactionfromID(int id) =>
      localDb.getBankTransactionfromID(id);

  /********** RECEIPTS **********/

  //@override
  //Future<int> insertReceipt(Receipt receipt, String categoryDesc) {}

  @override
  Future<List<ReceiptItem>> getAllReceiptItems(
      DateTime startDate,
      DateTime endDate,
      ) =>
      localDb.getAllReceiptItems(startDate, endDate);

  @override
  Future<List<Map<String, Object>>> getFilteredReceiptItems(
      DateTime startDate,
      DateTime endDate,
      TransactionCategory category,
      ) =>
      localDb.getFilteredReceiptItems(startDate, endDate, category);

  @override
  Future<List<Receipt>> getAllReceipts() => localDb.getAllReceipts();

  @override
  Future<Receipt> getReceiptfromID(int id) => localDb.getReceiptfromID(id);

  //@override
  //Future<void> updateReceipt(Receipt receipt) {}

  //@override
  //Future<void> deleteReceipt(int id) {}

  //@override
  //Future<void> deleteAllReceipts() {}

  @override
  Map<String, dynamic> encodeReceipt(Receipt receipt) =>
      localDb.encodeReceipt(receipt);

  @override
  List<ReceiptItem> parseReceiptItems(String decodedString) =>
      localDb.parseReceiptItems(decodedString);

  /********** CATEGORIES **********/

  @override
  Future<int?> getCategoryIDfromDescription(String description) =>
      localDb.getCategoryIDfromDescription(description);

  @override
  Future<String?> getCategoryDescriptionFromID(int id) =>
      localDb.getCategoryDescriptionfromID(id);

  @override
  Future<TransactionCategory?> getCategoryFromID(int id) =>
      localDb.getCategoryFromID(id);

  @override
  Future<List<Map<String, Object>>> getFilteredCategoryTotals(
      DateTime startDate,
      DateTime endDate,
      bool isExpenses,
      ) => localDb.getFilteredCategoryTotals(startDate, endDate, isExpenses);

  //@override
  //Future<void> insertDefaultCategories(Database db) {}

  //@override
  //Future<void> insertCategory(TransactionCategory category) {}

  //@override
  //Future<void> updateCategory(TransactionCategory category) {}

  //@override
  //Future<void> deleteCategoryByID(int id) {}

  @override
  Future<List<TransactionCategory>> getAllcategories() =>
      localDb.getAllcategories();

  /********** COOKIES **********/

  @override
  Future<Cookie?> getCookie() => localDb.getCookie();

  @override
  Future<void> setCookie(Cookie? cookie) => localDb.setCookie(cookie);
}