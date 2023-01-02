import 'dart:io';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/services/api_calls.dart';

import 'package:sqflite/sqflite.dart' show DatabaseFactory;

// Acts as common interface for local db and backend db.
class UnifiedDb extends SQFLite {
  final ApiCaller _apiCaller = ApiCaller();

  Future<void> _loginCallback() async {
    await syncCategories();
    await syncReceipts();
  }

  Future<void> syncCategories() async {
    Iterable<TransactionCategory> localCategories = await getAllcategories();
    Iterable<TransactionCategory> remoteCategories = await
        _apiCaller.fetchCategories();

    Iterable<TransactionCategory> categoriesToPost = localCategories.where(
        (TransactionCategory category) => !(remoteCategories.contains(category))
    );
    Iterable<TransactionCategory> categoriesToSave = remoteCategories.where(
        (TransactionCategory category) => !(localCategories.contains(category))
    );

    for (TransactionCategory category in categoriesToPost) {
      await _apiCaller.postCategory(category);
    }
    for (TransactionCategory category in categoriesToSave) {
      await insertCategory(category);
    }
  }

  Future<void> syncReceipts() async {
    Iterable<Receipt> localReceipts = await getAllReceipts();
    Iterable<Receipt> remoteReceipts = await _apiCaller.fetchReceipts();

    Iterable<Receipt> receiptsToPost = localReceipts.where((Receipt receipt) =>
        !(remoteReceipts.contains(receipt))
    );
    Iterable<Receipt> receiptsToSave = localReceipts.where((Receipt receipt) =>
        !(localReceipts.contains(receipt))
    );

    await _apiCaller.postManyReceipts(receiptsToPost.toList());
    for (Receipt receipt in receiptsToSave) {
      insertReceipt(receipt, receipt.categoryDesc!);
    }
  }

  UnifiedDb({DatabaseFactory? dbFactory, Future<String> Function()? path}) :
    super(dbFactory: dbFactory, path: path) {
    _apiCaller.addLoginCallback(_loginCallback);
  }

  static UnifiedDb? _instance;
  static UnifiedDb get instance {
    _instance ??= UnifiedDb();
    return _instance!;
  }

  /********** RECEIPTS **********/

  @override
  Future<int> insertReceipt(Receipt receipt, String categoryDesc) async {
    receipt.id = await super.insertReceipt(receipt, categoryDesc);
    if (_apiCaller.cookie != null) {
      await _apiCaller.postReceipt(receipt);
    }

    return receipt.id!;
  }

  @override
  Future<void> updateReceipt(Receipt receipt) async {
    await super.updateReceipt(receipt);
    if (_apiCaller.cookie != null) {
      await _apiCaller.updateReceipt(receipt.id!, receipt);
    }
  }

  @override
  Future<void> deleteReceipt(int id) async {
    Receipt receipt = await getReceiptfromID(id);
    await super.deleteReceipt(id);
    if (_apiCaller.cookie != null) {
      await _apiCaller.deleteReceipt(receipt);
    }
  }

  @override
  Future<void> deleteAllReceipts() async {
    Iterable<Receipt> receipts = await getAllReceipts();
    await super.deleteAllReceipts();
    if (_apiCaller.cookie == null) {
      return;
    }

    for (Receipt receipt in receipts) {
      await _apiCaller.deleteReceipt(receipt);
    }
  }

  /********** CATEGORIES **********/

  @override
  Future<void> insertCategory(TransactionCategory category) async {
    await super.insertCategory(category);
    if (_apiCaller.cookie != null) {
      await _apiCaller.postCategory(category);
    }
  }

  @override
  Future<void> updateCategory(TransactionCategory category) async {
    await super.updateCategory(category);
    if (_apiCaller.cookie != null) {
      await _apiCaller.updateCategory(category);
    }
  }

  @override
  Future<void> deleteCategoryByID(int id) async {
    await super.deleteCategoryByID(id);
    if (_apiCaller.cookie != null) {
      await _apiCaller.deleteCategory(id);
    }
  }
}