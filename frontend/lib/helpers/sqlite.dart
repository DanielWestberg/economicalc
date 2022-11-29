import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:economicalc_client/models/transaction.dart' as bank_transaction;
import 'package:flutter/services.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:flutter/material.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQFLite {
  static Database? _database;
  static final _databaseName = "transactions_database.db";
  static final _databaseVersion = 1;

  SQFLite._privateConstructor();
  static final SQFLite instance = SQFLite._privateConstructor();
  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }

    // lazily instantiate the db the first time it is accessed
    // deleteDatabase(_databaseName);
    _database = await initDatabase();
    return _database;
  }

  initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, userId TEXT, transactionId TEXT, recipient TEXT, date TEXT, total REAL, totalSumKr INTEGER, totalSumOre INTEGER, totalSumStr TEXT, items TEXT)',
    );

    await db.execute(
      'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, color INTEGER)',
    );

    await insertDefaultCategories(db);

    await db.execute('''CREATE TABLE banktransactions(
       id                       VARCHAR(32) NOT NULL UNIQUE PRIMARY KEY
      ,accountId                VARCHAR(32) NOT NULL
      ,amountvalueunscaledValue VARCHAR(32) NOT NULL
      ,amountvaluescale         VARCHAR(32) NOT NULL
      ,amountcurrencyCode       VARCHAR(32) NOT NULL
      ,descriptionsoriginal     VARCHAR(32) NOT NULL
      ,descriptionsdisplay      VARCHAR(32) NOT NULL
      ,datesbooked              DATE  NOT NULL
      ,typestype                VARCHAR(32) NOT NULL
      ,status                   VARCHAR(32) NOT NULL
      ,providerMutability       VARCHAR(32) NOT NULL
        ); ''');
  }

  Future<List<bank_transaction.Transaction>> getBankTransactions() async {
    final db = await instance.database;

    final List<Map<String, dynamic>>? maps =
        await db?.query('banktransactions');

    // Convert the List<Map<String, dynamic> into a List<transaction>.
    return List.generate(maps!.length, (i) {
      return bank_transaction.Transaction(
          id: maps[i]['id'],
          accountId: maps[i]['accountId'],
          amount: bank_transaction.Amount(
              value: bank_transaction.Value(
                  unscaledValue: maps[i]['amountvalueunscaledValue'],
                  scale: maps[i]['amountvaluescale']),
              currencyCode: maps[i]['amountcurrencyCode']),
          descriptions: bank_transaction.Descriptions(
              original: maps[i]['descriptionsoriginal'],
              display: maps[i]['descriptionsdisplay']),
          dates: bank_transaction.Dates(booked: maps[i]['datesbooked']),
          types: bank_transaction.Types(type: maps[i]['typestype']),
          status: maps[i]['status'],
          providerMutability: maps[i]['providerMutability']);
    });
  }

  Future<void> postBankTransaction(
      bank_transaction.Transaction transaction) async {
    final db = await instance.database;

    await db?.insert(
      'banktransactions',
      transaction.toDbFormat(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> encodeTransaction(Receipt transaction) {
    return transaction.toMap();
  }

  Future<int?> getcategoryIDfromDescription(String description) async {
    final db = await instance.database;
    List<Map<String, Object?>>? obj = await db?.rawQuery(
        'SELECT id FROM categories WHERE description = "${description}" ');
    return obj![0]['id'] as int;
  }

  Future<void> insertDefaultCategories(Database db) async {
    List<Category> categories = [
      Category(description: "Uncategorized", color: Colors.grey),
      Category(description: "Groceries", color: Colors.blue),
      Category(description: "Hardware", color: Colors.black),
      Category(description: "Transportation", color: Colors.purple),
      Category(description: "Stuff", color: Colors.green),
      Category(
          description: "My proud collection of teddy bears",
          color: Colors.brown),
    ];
    ;
    for (var category in categories) {
      await db.insert(
        'categories',
        category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> insertCategory(Category category) async {
    // Get a reference to the database.

    final db = await instance.database;
    await db?.insert(
      'categories',
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the given transaction.
    await db?.update(
      'categories',
      category.toJson(),
      // Ensure that the transaction has a matching id.
      where: 'id = ?',
      // Pass the transaction's id as a whereArg to prevent SQL injection.
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await instance.database;
    int? uncategorizedID = await getcategoryIDfromDescription("Uncategorized");

    await db?.rawQuery(
        'UPDATE transactions SET categoryID = ${uncategorizedID}, categoryDesc = "Uncategorized" WHERE categoryID = ${id} ');

    // Remove the transaction from the database.
    await db?.delete(
      'categories',
      // Use a `where` clause to delete a specific transaction.
      where: 'id = ?',
      // Pass the transaction's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  // Define a function that inserts transactions into the database
  Future<void> inserttransaction(
      Receipt transaction, String categoryDesc) async {
    // Get a reference to the database.
    int? categoryID = await getcategoryIDfromDescription(categoryDesc);
    final db = await instance.database;
    transaction.categoryDesc = categoryDesc;
    transaction.categoryID = categoryID;
    await db?.insert(
      'transactions',
      encodeTransaction(transaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Category>> categories() async {
    final db = await instance.database;
    final List<Map<String, dynamic?>>? maps = await db?.query('categories');
    return List.generate(maps!.length, (i) {
      return Category(
          description: maps[i]['description'],
          color: Color(maps[i]['color']),
          id: maps[i]['id']);
    });
  }

  List<ReceiptItem> parseReceiptItems(String decodedString) {
    List<dynamic> decoded = jsonDecode(decodedString);
    List<ReceiptItem> decodedItems = <ReceiptItem>[];
    for (var item in decoded) {
      ReceiptItem receiptItem = ReceiptItem.fromJson(item);
      decodedItems.add(receiptItem);
    }

    return decodedItems;
  }

  // A method that retrieves all the transactions from the transactions table.
  Future<List<Receipt>> transactions() async {
    final db = await instance.database;

    final List<Map<String, dynamic?>>? maps = await db?.query('transactions');

    // Convert the List<Map<String, dynamic> into a List<transaction>.
    return List.generate(maps!.length, (i) {
      return Receipt(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        transactionId: maps[i]['transactionId'],
        recipient: maps[i]['recipient'],
        date: DateTime.parse(maps[i]['date']),
        total: maps[i]['total'],
        items: parseReceiptItems(maps[i]['items']),
        totalSumKr: maps[i]['totalSumKr'],
        totalSumOre: maps[i]['totalSumOre'],
        totalSumStr: maps[i]['totalSumStr'],
        categoryDesc: maps[i]['categoryDesc'],
      );
    });
  }

  Future<void> updatetransaction(Receipt transaction) async {
    // Get a reference to the database.
    final db = await instance.database;

    int? categoryID =
        await getcategoryIDfromDescription(transaction.categoryDesc!);
    transaction.categoryID = categoryID;

    // Update the given transaction.
    await db?.update(
      'transactions',
      transaction.toMap(),
      // Ensure that the transaction has a matching id.
      where: 'id = ?',
      // Pass the transaction's id as a whereArg to prevent SQL injection.
      whereArgs: [transaction.id],
    );
  }

  Future<void> deletetransaction(int id) async {
    final db = await instance.database;

    // Remove the transaction from the database.
    await db?.delete(
      'transactions',
      // Use a `where` clause to delete a specific transaction.
      where: 'id = ?',
      // Pass the transaction's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> wipeDB() async {
    await deleteDatabase(join(await getDatabasesPath(), _databaseName));
  }
  void main() {}
}
