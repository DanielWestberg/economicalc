import 'dart:io';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/services/api_calls.dart';

import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:sqflite/sqflite.dart' show DatabaseFactory;

// Acts as common interface for local db and backend db.
class UnifiedDb extends SQFLite {
  final ApiCaller _apiCaller = ApiCaller();

  // TODO: sync algorithm is very naive and does not account for the possibility
  // of the frontend and backend having receipts with the same ID but different
  // content. It also does not account for items being deleted in one database
  // but not the other.
  Future<void> syncWithBackend() async {
    if (kDebugMode) {
      print("UnifiedDb: Syncing with backend...");
    }

    await _syncCategories();
    await _syncReceipts();

    if (kDebugMode) {
      print("UnifiedDb: Sync finished");
    }
  }

  Future<void> _syncCategories() async {
    Iterable<TransactionCategory> localCategories = await getAllcategories();
    Iterable<TransactionCategory> remoteCategories = await
        _apiCaller.fetchCategories();

    Iterable<TransactionCategory> categoriesToPost = localCategories.where(
        (TransactionCategory category) => !(remoteCategories.contains(category))
    );
    Iterable<TransactionCategory> categoriesToSave = remoteCategories.where(
        (TransactionCategory category) => !(localCategories.contains(category))
    );

    // For logging purposes only
    int postedCategories = 0;
    int savedCategories = 0;

    for (TransactionCategory category in categoriesToPost) {
      await _apiCaller.postCategory(category);
      postedCategories++;
    }
    for (TransactionCategory category in categoriesToSave) {
      await insertCategory(category);
      savedCategories++;
    }

    if (kDebugMode) {
      print("UnifiedDb: Posted $postedCategories categories");
      print("UnifiedDb: Saved $savedCategories categories");
    }
  }

  Future<void> _syncReceipts() async {
    Iterable<Receipt> localReceipts = await getAllReceipts();
    Iterable<Receipt> remoteReceipts = await _apiCaller.fetchReceipts();

    Iterable<Receipt> receiptsToPost = localReceipts.where((Receipt receipt) =>
        !(remoteReceipts.contains(receipt))
    );
    Iterable<Receipt> receiptsToSave = localReceipts.where((Receipt receipt) =>
        !(localReceipts.contains(receipt))
    );

    List<Receipt> receiptsToPostList = receiptsToPost.toList();

    // For logging purposes only
    int savedReceipts = 0;

    await _apiCaller.postManyReceipts(receiptsToPostList);
    for (Receipt receipt in receiptsToSave) {
      insertReceipt(receipt, receipt.categoryDesc!);
      savedReceipts++;
    }

    if (kDebugMode) {
      print("UnifiedDb: Posted ${receiptsToPostList.length} receipts");
      print("UnifiedDb: Saved $savedReceipts receipts");
    }
  }

  UnifiedDb({DatabaseFactory? dbFactory, Future<String> Function()? path}) :
    super(dbFactory: dbFactory, path: path);

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