import 'dart:async';
import 'dart:convert';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/bank_transaction.dart'
    as bank_transaction;
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

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

  Future<void> wipeDB() async {
    await deleteDatabase(join(await getDatabasesPath(), _databaseName));
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE transactions(
        id                  INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
        date                TEXT,
        totalAmount         REAL,
        store               TEXT,
        bankTransactionID   TEXT,
        receiptID           INTEGER,
        categoryID          INTEGER,
        categoryDesc        TEXT,
        FOREIGN KEY (bankTransactionID) REFERENCES bankTransaction (id),
        FOREIGN KEY (receiptID) REFERENCES receipt (id),
        FOREIGN KEY (categoryID) REFERENCES category (id) )''',
    );

    await db.execute(
      '''CREATE TABLE receipts(
        id                  INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
        recipient           TEXT,
        date                TEXT,
        total               REAL,
        items               TEXT,
        categoryDesc        TEXT,
        categoryID          INTEGER,
        FOREIGN KEY (categoryID) REFERENCES category (id) )''',
    );

    await db.execute('''CREATE TABLE bankTransactions(
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

    await db.execute(
      '''CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        color INTEGER)''',
    );

    await insertDefaultCategories(db);
  }

  /*************************** TRANSACTIONS *******************************/

  // Define a function that inserts transactions into the database
  Future<void> insertTransaction(Transaction transaction) async {
    // Get a reference to the database.
    final db = await instance.database;
    await db?.insert(
      'transactions',
      encodeTransaction(transaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> numOfCategoriesWithSameName(Transaction transaction) async {
    int n = 0;
    List<Transaction> transactionsInLocalDb = await getAllTransactions();
    for (Transaction tran in transactionsInLocalDb) {
      if (tran.store!.toLowerCase().trim() ==
          transaction.store!.toLowerCase().trim()) {
        n++;
      }
    }
    return (n - 1);
  }

  //Maybe a more suitable name can be found?
  Future<void> assignCategories(Transaction transaction) async {
    List<Transaction> transactionsInLocalDb = await getAllTransactions();
    for (Transaction tran in transactionsInLocalDb) {
      if (tran.store?.toLowerCase().trim() ==
          transaction.store?.toLowerCase().trim()) {
        tran.categoryID = transaction.categoryID;
        tran.categoryDesc = transaction.categoryDesc;
        updateTransaction(tran);
      }
    }
  }

  // A method that retrieves all the transactions from the transactions table.
  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;

    final List<Map<String, dynamic?>>? maps = await db?.query('transactions');

    // Convert the List<Map<String, dynamic> into a List<transaction>.
    return List.generate(maps!.length, (i) {
      return Transaction(
        id: maps[i]['id'],
        store: maps[i]['store'],
        date: DateTime.parse(maps[i]['date']),
        totalAmount: maps[i]['totalAmount'],
        bankTransactionID: maps[i]['bankTransactionID'],
        receiptID: maps[i]['receiptID'],
        categoryID: maps[i]['categoryID'],
        categoryDesc: maps[i]['categoryDesc'],
      );
    });
  }

  Future<List<Transaction>> getFilteredTransactions(
      startDate, endDate, category, onlyReceipts) async {
    final transactions = await getAllTransactions();
    List<Transaction> filteredTransactions = [];

    for (var transaction in transactions) {
      bool dateCondition = transaction.date.compareTo(startDate) >= 0 &&
          transaction.date.compareTo(endDate) <= 0;
      bool onlyReceiptsCondition =
          ((onlyReceipts == true) && (transaction.receiptID != null)) ||
              (onlyReceipts == false);
      bool isNone = category.description == 'None';

      if (dateCondition &&
          onlyReceiptsCondition &&
          (isNone || !isNone && transaction.categoryID == category.id)) {
        filteredTransactions.add(transaction);
      }
    }
    return filteredTransactions;
  }

  Future<void> updateTransaction(Transaction transaction) async {
    // Get a reference to the database.
    final db = await instance.database;

    int? categoryID =
        await getCategoryIDfromDescription(transaction.categoryDesc!);
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

  Future<void> deleteTransaction(int id) async {
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

  Map<String, dynamic> encodeTransaction(Transaction transaction) {
    return transaction.toMap();
  }

  Future<void> importMissingBankTransactions() async {
    final db = await instance.database;

    List<Map<String, dynamic?>>? bankTransactions =
        await db?.rawQuery('SELECT * FROM bankTransactions');

    for (var bankTransaction in bankTransactions!) {
      var id = bankTransaction['id'];
      List<Map<String, dynamic?>>? transaction = await db?.rawQuery(
          'SELECT * FROM transactions WHERE bankTransactionID = "$id"');

      if (transaction!.length == 0) {
        Transaction newTransaction = Transaction(
          store: bankTransaction['descriptionsoriginal'],
          date: DateTime.parse(bankTransaction['datesbooked']),
          totalAmount:
              double.parse(bankTransaction['amountvalueunscaledValue']) / 10,
          bankTransactionID: id,
          categoryID: await getCategoryIDfromDescription("Uncategorized"),
          categoryDesc: "Uncategorized",
        );
        insertTransaction(newTransaction);
      }
    }
  }

  /*************************** BANKTRANSACTIONS *******************************/

  Future<List<bank_transaction.BankTransaction>> getBankTransactions() async {
    final db = await instance.database;

    final List<Map<String, dynamic>>? maps =
        await db?.query('bankTransactions');

    // Convert the List<Map<String, dynamic> into a List<transaction>.
    return List.generate(maps!.length, (i) {
      return bank_transaction.BankTransaction(
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
      bank_transaction.BankTransaction bankTransaction) async {
    final db = await instance.database;

    await db?.insert(
      'bankTransactions',
      bankTransaction.toDbFormat(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bank_transaction.BankTransaction> getBankTransactionfromID(
      int id) async {
    final db = await instance.database;

    List<Map<String, dynamic?>>? maps =
        await db?.rawQuery('SELECT * FROM bankTransactions WHERE id = "${id}"');

    // Convert the List<Map<String, dynamic> into a BankTransaction.
    return bank_transaction.BankTransaction(
        id: maps![0]['id'],
        accountId: maps[0]['accountId'],
        amount: bank_transaction.Amount(
            value: bank_transaction.Value(
                unscaledValue: maps[0]['amountvalueunscaledValue'],
                scale: maps[0]['amountvaluescale']),
            currencyCode: maps[0]['amountcurrencyCode']),
        descriptions: bank_transaction.Descriptions(
            original: maps[0]['descriptionsoriginal'],
            display: maps[0]['descriptionsdisplay']),
        dates: bank_transaction.Dates(booked: maps[0]['datesbooked']),
        types: bank_transaction.Types(type: maps[0]['typestype']),
        status: maps[0]['status'],
        providerMutability: maps[0]['providerMutability']);
  }

  /*************************** RECEIPTS *******************************/

  // Define a function that inserts receipts into the database
  Future<int> insertReceipt(Receipt receipt, String categoryDesc) async {
    // Get a reference to the database.
    int? categoryID = await getCategoryIDfromDescription(categoryDesc);
    final db = await instance.database;
    receipt.categoryDesc = categoryDesc;
    receipt.categoryID = categoryID;
    return db!.insert(
      'receipts',
      encodeReceipt(receipt),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReceiptItem>> getAllReceiptItems(startDate, endDate) async {
    final receipts = await getAllReceipts();
    List<ReceiptItem> items = [];

    receipts.forEach((receipt) {
      receipt.items.forEach((item) => items.add(item));
    });

    return items;
  }

  Future<List<Map<String, Object>>> getFilteredReceiptItems(
      startDate, endDate, category) async {
    final receipts = await getAllReceipts();
    List<Map<String, Object>> filteredItems = [];

    if (category.description == 'None') {
      for (var receipt in receipts) {
        if (receipt.date.compareTo(startDate) >= 0 &&
            receipt.date.compareTo(endDate) <= 0) {
          TransactionCategory? category =
              await getCategoryFromID(receipt.categoryID!);
          receipt.items.forEach((item) => filteredItems.add({
                "category": category!,
                "receiptItem": item,
              }));
        }
      }
    } else {
      for (var receipt in receipts) {
        if (receipt.date.compareTo(startDate) >= 0 &&
            receipt.date.compareTo(endDate) <= 0 &&
            receipt.categoryID == category.id) {
          TransactionCategory? category =
              await getCategoryFromID(receipt.categoryID!);
          receipt.items.forEach((item) => filteredItems.add({
                "category": category!,
                "receiptItem": item,
              }));
        }
      }
    }

    return filteredItems;
  }

  // A method that retrieves all the receipts from the receipts table.
  Future<List<Receipt>> getAllReceipts() async {
    final db = await instance.database;

    final List<Map<String, dynamic?>>? maps = await db?.query('receipts');

    // Convert the List<Map<String, dynamic> into a List<receipts>.
    return List.generate(maps!.length, (i) {
      return Receipt(
        id: maps[i]['id'],
        recipient: maps[i]['recipient'],
        date: DateTime.parse(maps[i]['date']),
        total: maps[i]['total'],
        items: parseReceiptItems(maps[i]['items']),
        categoryDesc: maps[i]['categoryDesc'],
        categoryID: maps[i]['categoryID'],
      );
    });
  }

  Future<Receipt> getReceiptfromID(int id) async {
    final db = await instance.database;
    List<Map<String, dynamic?>>? maps =
        await db?.rawQuery('SELECT * FROM receipts WHERE id = "${id}"');

    return Receipt(
      id: maps![0]['id'],
      recipient: maps[0]['recipient'],
      date: DateTime.parse(maps[0]['date']),
      total: maps[0]['total'],
      items: parseReceiptItems(maps[0]['items']),
      categoryDesc: maps[0]['categoryDesc'],
      categoryID: maps[0]['categoryID'],
    );
  }

  Future<void> updateReceipt(Receipt receipt) async {
    // Get a reference to the database.
    final db = await instance.database;

    int? categoryID = await getCategoryIDfromDescription(receipt.categoryDesc!);
    receipt.categoryID = categoryID;

    // Update the given receipt.
    await db?.update(
      'receipts',
      encodeReceipt(receipt),
      // Ensure that the receipt has a matching id.
      where: 'id = ?',
      // Pass the receipt's id as a whereArg to prevent SQL injection.
      whereArgs: [receipt.id],
    );
  }

  Future<void> deleteReceipt(int id) async {
    final db = await instance.database;

    // Remove the receipt from the database.
    await db?.delete(
      'receipts',
      // Use a `where` clause to delete a specific receipt.
      where: 'id = ?',
      // Pass the receipt's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Map<String, dynamic> encodeReceipt(Receipt receipt) {
    Map<String, dynamic> receiptMap = receipt.toMap();
    receiptMap['items'] = jsonEncode(receiptMap['items']);
    return receiptMap;
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

  /*************************** CATEGORIES *******************************/

  Future<int?> getCategoryIDfromDescription(String description) async {
    final db = await instance.database;
    List<Map<String, Object?>>? obj = await db?.rawQuery(
        'SELECT id FROM categories WHERE description = "${description}" ');
    return obj![0]['id'] as int;
  }

  Future<String?> getCategoryDescriptionfromID(int id) async {
    final db = await instance.database;
    List<Map<String, Object?>>? obj = await db
        ?.rawQuery('SELECT description FROM categories WHERE id = "${id}"');
    return obj![0]['description'] as String;
  }

  Future<TransactionCategory?> getCategoryFromID(int id) async {
    final db = await instance.database;
    List<Map<String, dynamic?>>? obj =
        await db?.rawQuery('SELECT * FROM categories WHERE id = "$id"');
    return TransactionCategory.fromJson(obj![0]);
  }

  Future<List<Map<String, Object>>> getFilteredCategoryTotals(
      startDate, endDate, isExpenses) async {
    final categories = await getAllcategories();

    List<Map<String, Object>> categoryTotals = [];

    for (var category in categories) {
      var filteredTransactions =
          await getFilteredTransactions(startDate, endDate, category, false);
      var categoryTotal = {
        "category": category,
        "totalSum":
            Utils.getSumOfTransactionsTotals(filteredTransactions, isExpenses)
      };
      categoryTotals.add(categoryTotal);
    }

    return categoryTotals;
  }

  Future<void> insertDefaultCategories(Database db) async {
    List<TransactionCategory> categories = [
      TransactionCategory(description: "Uncategorized", color: Colors.grey),
      TransactionCategory(description: "Groceries", color: Colors.blue),
      TransactionCategory(description: "Hardware", color: Colors.black),
      TransactionCategory(description: "Transportation", color: Colors.purple),
      TransactionCategory(description: "Stuff", color: Colors.green),
      TransactionCategory(
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

  Future<void> insertCategory(TransactionCategory category) async {
    // Get a reference to the database.

    final db = await instance.database;
    await db?.insert(
      'categories',
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(TransactionCategory category) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the given category.
    await db?.update(
      'categories',
      category.toJson(),
      // Ensure that the category has a matching id.
      where: 'id = ?',
      // Pass the category's id as a whereArg to prevent SQL injection.
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategoryByID(int id) async {
    final db = await instance.database;
    int? uncategorizedID = await getCategoryIDfromDescription("Uncategorized");

    await db?.rawQuery(
        'UPDATE transactions SET categoryID = ${uncategorizedID}, categoryDesc = "Uncategorized" WHERE categoryID = ${id} ');

    // Remove the category from the database.
    await db?.delete(
      'categories',
      // Use a `where` clause to delete a specific category.
      where: 'id = ?',
      // Pass the category's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<List<TransactionCategory>> getAllcategories() async {
    final db = await instance.database;
    final List<Map<String, dynamic?>>? maps = await db?.query('categories');
    return List.generate(maps!.length, (i) {
      return TransactionCategory(
          description: maps[i]['description'],
          color: Color(maps[i]['color']),
          id: maps[i]['id']);
    });
  }
}
