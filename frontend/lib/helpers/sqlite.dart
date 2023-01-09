import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:flutter/material.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class SQFLite {
  static Database? _database;
  static final _databaseName = "transactions_database.db";
  static final _databaseVersion = 1;
  static const cookieId = 0;

  final DatabaseFactory _dbFactory;
  final Future<String> Function() _path;

  static Future<String> _defaultPath() async =>
      join(await getDatabasesPath(), _databaseName);

  SQFLite({DatabaseFactory? dbFactory, Future<String> Function()? path})
      : _dbFactory = dbFactory ?? databaseFactory,
        _path = path ?? _defaultPath;

  static SQFLite? _instance;
  static SQFLite get instance {
    _instance ??= SQFLite();
    return _instance!;
  }

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
    return await _dbFactory.openDatabase(await _path(),
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
        ));
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
        ocrText             TEXT,
        imagePath           TEXT,
        FOREIGN KEY (categoryID) REFERENCES category (id) )''',
    );

    await db.execute('''CREATE TABLE bankTransactions(
       id                       VARCHAR(32) NOT NULL UNIQUE PRIMARY KEY
      ,amountvalueunscaledValue VARCHAR(32) NOT NULL
      ,descriptionsdisplay      VARCHAR(32) NOT NULL
      ,datesbooked              DATE  NOT NULL
        ); ''');

    await db.execute(
      '''CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        color INTEGER)''',
    );

    await insertDefaultCategories(db);

    await db.execute('''CREATE TABLE cookies(
      id INTEGER PRIMARY KEY CHECK (id = $cookieId)
      ,cookie VARCHAR(128)
      );''');

    await _setCookie(null, db);
  }

  /*************************** TRANSACTIONS *******************************/

  // Define a function that inserts transactions into the database
  Future<void> insertTransaction(Transaction transaction) async {
    // Get a reference to the database.
    final db = await database;
    await db?.insert(
      'transactions',
      encodeTransaction(transaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Transaction>> numOfCategoriesWithSameName(
      Transaction transaction) async {
    List<Transaction> transToUpdate = [];
    List<Transaction> transactionsInLocalDb = await getAllTransactions();
    for (Transaction tran in transactionsInLocalDb) {
      if (await Utils.categoricalSimilarity(tran, transaction)) {
        tran.categoryID = transaction.categoryID;
        tran.categoryDesc = transaction.categoryDesc;
        transToUpdate.add(tran);
      }
    }
    return transToUpdate;
  }

  //Maybe a more suitable name can be found?
  Future<void> assignCategories(Transaction transaction) async {
    List<Transaction> transactionsInLocalDb = await getAllTransactions();
    for (Transaction tran in transactionsInLocalDb) {
      if (tran.store?.toLowerCase().trim() ==
          transaction.store?.toLowerCase().trim()) {
        tran.categoryID = transaction.categoryID;
        tran.categoryDesc = transaction.categoryDesc;
        await updateTransaction(tran);
      }
    }
  }

  // A method that retrieves all the transactions from the transactions table.
  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;

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

  Future<Transaction?> getTransactionByReceiptID(int receiptID) async {
    final db = await instance.database;
    List<Map<String, dynamic?>>? maps = await db
        ?.rawQuery('SELECT * FROM transactions WHERE receiptID = $receiptID');

    return maps != null ? Transaction.fromJson(maps[0]) : null;
  }

  Future<void> updateTransaction(Transaction transaction) async {
    // Get a reference to the database.
    final db = await database;

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
    final db = await database;

    // Remove the transaction from the database.
    await db?.delete(
      'transactions',
      // Use a `where` clause to delete a specific transaction.
      where: 'id = ?',
      // Pass the transaction's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> deleteAllTransactions() async {
    final db = await instance.database;
    await db?.rawQuery('DELETE FROM transactions');
  }

  Map<String, dynamic> encodeTransaction(Transaction transaction) {
    return transaction.toMap();
  }

  Future<Receipt?> checkForExistingReceipt(Transaction transaction) async {
    List<Receipt> receipts = await getAllReceipts();
    for (Receipt receipt in receipts) {
      bool equality =
          await Utils.isReceiptAndTransactionEqual(receipt, transaction);
      if (equality) return receipt;
    }
    return null;
  }

  Future<Transaction?> checkForExistingTransaction(
      Transaction transaction) async {
    List<Transaction> transactions = await getAllTransactions();
    for (Transaction trans in transactions) {
      bool equality = await Utils.areTransactionsEqual(trans, transaction);
      if (equality) return trans;
    }
    return null;
  }

  Future<List<int>> updateTransactions() async {
    final db = await database;

    List<BankTransaction> bankTransactions = await getAllBankTransactions();
    bankTransactions.sort(((a, b) => b.date.compareTo(a.date)));
    int updated = 0;
    int added = 0;

    for (var bankTransaction in bankTransactions) {
      List<Map<String, dynamic?>>? transaction = await db?.rawQuery(
          'SELECT * FROM transactions WHERE bankTransactionID = "${bankTransaction.id}"');

      if (transaction!.isEmpty) {
        Transaction newTransaction = Transaction(
          store: bankTransaction.description,
          date: bankTransaction.date,
          totalAmount: bankTransaction.amount,
          bankTransactionID: bankTransaction.id,
          categoryID: await getCategoryIDfromDescription("Uncategorized"),
          categoryDesc: "Uncategorized",
        );
        Receipt? existingReceipt =
            await checkForExistingReceipt(newTransaction);
        Transaction? existingTransaction =
            await checkForExistingTransaction(newTransaction);
        if (existingReceipt != null) {
          if (existingTransaction == null) {
            newTransaction.receiptID = existingReceipt.id;
            await insertTransaction(newTransaction);
            added++;
          } else {
            existingTransaction.bankTransactionID =
                newTransaction.bankTransactionID;
            await updateTransaction(existingTransaction);
            updated++;
          }
        } else if (existingTransaction != null) {
          existingTransaction.bankTransactionID = bankTransaction.id;
          existingTransaction.date = bankTransaction.date;
          await updateTransaction(existingTransaction);
          updated++;
        } else {
          await insertTransaction(newTransaction);
          added++;
        }
      } else {
        break;
      }
    }
    return [added, updated];
  }

  /*************************** BANKTRANSACTIONS *******************************/

  Future<List<BankTransaction>> getAllBankTransactions() async {
    final db = await database;

    final List<Map<String, dynamic>>? maps =
        await db?.query('bankTransactions');

    // Convert the List<Map<String, dynamic> into a List<transaction>.
    return List.generate(maps!.length, (i) {
      return BankTransaction.fromDB(maps[i]);
    });
  }

  Future<void> postBankTransaction(BankTransaction bankTransaction) async {
    final db = await database;

    await db?.insert(
      'bankTransactions',
      bankTransaction.toDbFormat(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> postMissingBankTransactions(
      List<BankTransaction> updatedBankTransactions) async {
    List<BankTransaction> bankTransactionsInDB = await getAllBankTransactions();

    if (bankTransactionsInDB.isEmpty) {
      for (BankTransaction bankTransaction in updatedBankTransactions) {
        await postBankTransaction(bankTransaction);
      }
    } else {
      bankTransactionsInDB.sort(((a, b) => b.date.compareTo(a.date)));
      updatedBankTransactions.sort(((a, b) => b.date.compareTo(a.date)));

      for (BankTransaction bankTransaction in updatedBankTransactions) {
        if (bankTransaction.date.compareTo(bankTransactionsInDB.first.date) <=
            0) break;
        for (int i = 0; i < 20; i++) {
          // Only need to check the 20 latest existing bank transactions
          bool equality = await Utils.areBankTransactionsEqual(
              bankTransaction, bankTransactionsInDB[i]);
          if (equality) continue;
          await postBankTransaction(bankTransaction);
          break;
        }
      }
    }
  }

  Future<void> deleteAllBankTransactions() async {
    final db = await instance.database;
    await db?.rawQuery('DELETE FROM bankTransactions');
  }

  Future<BankTransaction> getBankTransactionfromID(int id) async {
    final db = await database;

    List<Map<String, dynamic?>>? maps =
        await db?.rawQuery('SELECT * FROM bankTransactions WHERE id = "${id}"');

    return BankTransaction.fromDB(maps![0]);
  }

  /*************************** RECEIPTS *******************************/

  // Define a function that inserts receipts into the database
  Future<int> insertReceipt(Receipt receipt, String categoryDesc) async {
    // Get a reference to the database.
    int? categoryID = await getCategoryIDfromDescription(categoryDesc);
    final db = await database;
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
    final db = await database;

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
        ocrText: maps[i]['ocrText'],
        imagePath: maps[i]['imagePath'],
      );
    });
  }

  Future<Receipt> getReceiptfromID(int id) async {
    final db = await database;
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
        ocrText: maps[0]['ocrText'],
        imagePath: maps[0]['imagePath']);
  }

  Future<void> updateReceipt(Receipt receipt) async {
    // Get a reference to the database.
    final db = await database;

    int? categoryID = await getCategoryIDfromDescription(receipt.categoryDesc!);
    receipt.categoryID = categoryID;
    int receiptID = receipt.id!;

    // Update the given receipt.
    await db?.update(
      'receipts',
      encodeReceipt(receipt),
      // Ensure that the receipt has a matching id.
      where: 'id = ?',
      // Pass the receipt's id as a whereArg to prevent SQL injection.
      whereArgs: [receiptID],
    );
  }

  Future<void> deleteReceipt(int id) async {
    final db = await database;

    // Remove the receipt from the database.
    await db?.delete(
      'receipts',
      // Use a `where` clause to delete a specific receipt.
      where: 'id = ?',
      // Pass the receipt's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> deleteAllReceipts() async {
    final db = await instance.database;
    await db?.rawQuery('DELETE FROM receipts');
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
    final db = await database;
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

    final db = await database;
    await db?.insert(
      'categories',
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(TransactionCategory category) async {
    // Get a reference to the database.
    final db = await database;

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
    final db = await database;
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

  Future<bool> doesCategoryAlreadyExist(String description) async {
    List<TransactionCategory> categoriesInDB = await getAllcategories();
    return categoriesInDB
        .where((category) =>
            category.description.toLowerCase() == description.toLowerCase())
        .isNotEmpty;
  }

  Future<List<TransactionCategory>> getAllcategories() async {
    final db = await database;
    final List<Map<String, dynamic?>>? maps = await db?.query('categories');
    return List.generate(maps!.length, (i) {
      return TransactionCategory(
          description: maps[i]['description'],
          color: Color(maps[i]['color']),
          id: maps[i]['id']);
    });
  }

  /*************************** COOKIES *******************************/

  Future<Cookie?> getCookie() async {
    final db = await database;
    List<Map<String, dynamic>>? result = await db?.query(
      'cookies',
      where: 'id = $cookieId',
    );

    return Cookie.fromSetCookieValue(result?[0]["cookie"]);
  }

  Future<void> _setCookie(Cookie? cookie, Database db) async {
    final value = {
      'id': cookieId,
      'cookie': cookie.toString(),
    };

    await db.insert(
      'cookies',
      value,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setCookie(Cookie? cookie) async {
    Database? db = await database;
    _setCookie(cookie, db!);
  }
}
