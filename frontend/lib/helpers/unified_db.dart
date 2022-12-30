import 'dart:io';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/services/api_calls.dart';

// Acts as common interface for local db and backend db.
class UnifiedDb implements SQFLite {
  SQFLite? __localDb;
  SQFLite get _localDb {
    __localDb ??= SQFLite.instance;
    return __localDb!;
  }
  ApiCaller _apiCaller = ApiCaller();

  @override
  initDatabase() async => _localDb.initDatabase();

  @override
  Future<void> wipeDB() async => _localDb.wipeDB();

  /********** TRANSACTIONS **********/

  @override
  Future<void> insertTransaction(Transaction transaction) async =>
      _localDb.insertTransaction(transaction);

  @override
  Future<int> numOfCategoriesWithSameName(Transaction transaction) async =>
      _localDb.numOfCategoriesWithSameName(transaction);

  @override
  Future<void> assignCategories(Transaction transaction) async =>
      _localDb.assignCategories(transaction);

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
      _localDb.getTransactionByReceiptID(receiptID);

  //@override
  //Future<void> updateTransaction(Transaction transaction) async {}

  //@override
  //Future<void> deleteTransaction(int id) async {}

  //@override
  //Future<void> deleteAllTransactions() async {}

  @override
  Map<String, dynamic> encodeTransaction(Transaction transaction) =>
      _localDb.encodeTransaction(transaction);

  @override
  Future<Receipt?> checkForExistingReceipt(Transaction transaction) =>
      _localDb.checkForExistingReceipt(transaction);

  @override
  Future<Transaction?> checkForExistingTransaction(Transaction transaction) =>
      _localDb.checkForExistingTransaction(transaction);

  //@override
  //Future<List<int>> updateTransactions() {}

  /********** BANKTRANSACTIONS **********/

  @override
  Future<List<BankTransaction>> getAllBankTransactions() =>
      _localDb.getAllBankTransactions();

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
      _localDb.getBankTransactionfromID(id);

  /********** RECEIPTS **********/

  //@override
  //Future<int> insertReceipt(Receipt receipt, String categoryDesc) {}

  @override
  Future<List<ReceiptItem>> getAllReceiptItems(
      DateTime startDate,
      DateTime endDate,
      ) =>
      _localDb.getAllReceiptItems(startDate, endDate);

  @override
  Future<List<Map<String, Object>>> getFilteredReceiptItems(
      DateTime startDate,
      DateTime endDate,
      TransactionCategory category,
      ) =>
      _localDb.getFilteredReceiptItems(startDate, endDate, category);

  @override
  Future<List<Receipt>> getAllReceipts() => _localDb.getAllReceipts();

  @override
  Future<Receipt> getReceiptfromID(int id) => _localDb.getReceiptfromID(id);

  //@override
  //Future<void> updateReceipt(Receipt receipt) {}

  //@override
  //Future<void> deleteReceipt(int id) {}

  //@override
  //Future<void> deleteAllReceipts() {}

  @override
  Map<String, dynamic> encodeReceipt(Receipt receipt) =>
      _localDb.encodeReceipt(receipt);

  @override
  List<ReceiptItem> parseReceiptItems(String decodedString) =>
      _localDb.parseReceiptItems(decodedString);

  /********** CATEGORIES **********/

  @override
  Future<int?> getCategoryIDfromDescription(String description) =>
      _localDb.getCategoryIDfromDescription(description);

  @override
  Future<String?> getCategoryDescriptionFromID(int id) =>
      _localDb.getCategoryDescriptionfromID(id);

  @override
  Future<TransactionCategory?> getCategoryFromID(int id) =>
      _localDb.getCategoryFromID(id);

  @override
  Future<List<Map<String, Object>>> getFilteredCategoryTotals(
      DateTime startDate,
      DateTime endDate,
      bool isExpenses,
      ) => _localDb.getFilteredCategoryTotals(startDate, endDate, isExpenses);

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
      _localDb.getAllcategories();

  /********** COOKIES **********/

  @override
  Future<Cookie?> getCookie() => _localDb.getCookie();

  @override
  Future<void> setCookie(Cookie? cookie) => _localDb.setCookie(cookie);
}