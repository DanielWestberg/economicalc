import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_common/sqlite_api.dart' hide Transaction;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<String> getInMemoryDatabasePath() async => inMemoryDatabasePath;

main() async {
  final db = SQFLite(
    dbFactory: databaseFactoryFfi,
    path: getInMemoryDatabasePath,
  );

  test("Filter transactions by date", () async {
    final DateTime startDate = DateTime(2022, 1, 1);
    final DateTime endDate = DateTime(2022, 12, 31);

    final List<Transaction> matching = [
      Transaction(date: DateTime(2022, 1, 1)),
      Transaction(date: DateTime(2022, 2, 24)),
      Transaction(date: DateTime(2022, 7, 10), receiptID: 5),
      Transaction(date: DateTime(2022, 12, 31)),
    ];
    final List<Transaction> nonMatching = [
      Transaction(date: DateTime(1970, 1, 1)),
      Transaction(date: DateTime(2021, 12, 31), receiptID: 8),
      Transaction(date: DateTime(2023, 1, 1)),
      Transaction(date: DateTime(2038, 1, 18)),
    ];

    final List<Transaction> unfiltered = matching + nonMatching;
    final List<Transaction> filtered = db.filterTransactions(
      unfiltered,
      startDate,
      endDate,
      TransactionCategory(description: "None", color: const Color(0x00000000)),
      false,
    ).toList();

    expect(filtered.length, equals(matching.length));
    expect(filtered, containsAll(matching));
  });

  test("Filter transactions by Category", () async {
    final DateTime date = DateTime(2022, 1, 1);
    final TransactionCategory matchingCategory = TransactionCategory(
        description: "", color: const Color(0x12345678), id: 3
    );
    final TransactionCategory wrongCategory = TransactionCategory(
      description: "", color: const Color(0x12345678), id: 4
    );

    final List<Transaction> matching = [
      Transaction(date: date, categoryID: matchingCategory.id),
    ];

    final List<Transaction> nonMatching = [
      Transaction(date: date, categoryID: wrongCategory.id),
    ];

    final List<Transaction> unfiltered = matching + nonMatching;
    final List<Transaction> filtered = db.filterTransactions(
      unfiltered,
      date,
      date,
      matchingCategory,
      false,
    ).toList();

    expect(filtered.length, equals(matching.length));
    expect(filtered, containsAll(matching));
  });

  test("Filter transactions from receipts", () async {
    final DateTime date = DateTime(2022, 1, 1);
    final TransactionCategory category = TransactionCategory(
      description: "None", color: const Color(0x00000000),
    );

    final List<Transaction> matching = [
      Transaction(date: date, receiptID: 2),
    ];

    final List<Transaction> nonMatching = [
      Transaction(date: date,),
    ];

    final List<Transaction> unfiltered = matching + nonMatching;
    final List<Transaction> filtered = db.filterTransactions(
      unfiltered,
      date,
      date,
      category,
      true,
    ).toList();
  });
}