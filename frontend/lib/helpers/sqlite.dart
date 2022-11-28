import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:html';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:economicalc_client/models/transaction.dart' as bank_transaction;
import 'package:flutter/services.dart';
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
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
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

    await db.execute('''CREATE TABLE banktransactions(
       id                       VARCHAR(32) NOT NULL PRIMARY KEY
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

    Future<String> jsondata = rootBundle.loadString('test_data.json');
    final List<dynamic> data = await json.decode(await jsondata);
    final List<bank_transaction.Transaction> test_transactions = [];
    print(data);
    data.forEach((transaction) {
      test_transactions.add(transaction);
    });
    print(test_transactions);
    test_transactions.forEach((transaction) {
      postBankTransactions(transaction);
    });
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
              original: maps[i]['descriptionoriginal'],
              display: maps[i]['descriptionsdisplay']),
          dates: bank_transaction.Dates(booked: maps[i]['datebooked']),
          types: bank_transaction.Types(type: maps[i]['typestype']),
          status: maps[i]['status'],
          providerMutability: maps[i]['providerMutability']);
    });
  }

  Future<void> postBankTransactions(
      bank_transaction.Transaction transaction) async {
    final db = await instance.database;

    await db?.insert(
      'banktransactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> encodeTransaction(Receipt transaction) {
    return transaction.toMap();
  }

  // Define a function that inserts transactions into the database
  Future<void> inserttransaction(Receipt transaction) async {
    // Get a reference to the database.

    final db = await instance.database;
    await db?.insert(
      'transactions',
      encodeTransaction(transaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
        userId: maps[i]['userId'],
        transactionId: maps[i]['transactionId'],
        recipient: maps[i]['recipient'],
        date: DateTime.parse(maps[i]['date']),
        total: maps[i]['total'],
        items: parseReceiptItems(maps[i]['items']),
        totalSumKr: maps[i]['totalSumKr'],
        totalSumOre: maps[i]['totalSumOre'],
        totalSumStr: maps[i]['totalSumStr'],
      );
    });
  }

  Future<void> updatetransaction(Receipt transaction) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the given transaction.
    await db?.update(
      'transactions',
      transaction.toMap(),
      // Ensure that the transaction has a matching id.
      where: 'id = ?',
      // Pass the transaction's id as a whereArg to prevent SQL injection.
      whereArgs: [transaction.userId],
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
