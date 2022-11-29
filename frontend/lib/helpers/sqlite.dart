import 'dart:async';
import 'dart:convert';
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
      'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, userId TEXT, transactionId TEXT, recipient TEXT, date TEXT, total REAL, totalSumKr INTEGER, totalSumOre INTEGER, totalSumStr TEXT, items TEXT, categoryDesc TEXT, categoryID INTEGER, FOREIGN KEY (categoryID) REFERENCES category (id) )',
    );
    await db.execute(
      'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, color INTEGER)',
    );

    await insertDefaultCategories(db);
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
    print("bajsen");
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
}
