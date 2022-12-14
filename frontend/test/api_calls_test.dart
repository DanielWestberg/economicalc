import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';

import 'package:flutter_test/flutter_test.dart';

class MissingParamException implements Exception {
  final String paramName;
  get message => "Missing parameter $paramName. "
      "Please run 'flutter test' with the flag "
      "'--dart-define=$paramName=<value>";

  const MissingParamException(this.paramName);

  @override
  String toString() => "MissingParamException: $message";
}

Future<String> getInMemoryDatabasePath() async {
  return inMemoryDatabasePath;
}

main() async {
  final apiCaller = ApiCaller.withDb(
      SQFLite(
          dbFactory: databaseFactoryFfi,
          path: getInMemoryDatabasePath,
      )
  );

  print("Report IDs can be found here: ${apiCaller.tinkReportEndpoint}");
  const accountReportId = String.fromEnvironment("accountReportId");
  const transactionReportId = String.fromEnvironment("transactionReportId");

  if (accountReportId == "") {
    throw const MissingParamException("accountReportId");
  }

  if (transactionReportId == "") {
    throw const MissingParamException("transactionReportId");
  }

  const int categoryId = 1234;

  setUpAll(() async {
    await apiCaller.fetchLoginData(accountReportId, transactionReportId, true);
  });

  tearDownAll(() async {
    await apiCaller.deleteCategory(categoryId);

    List<Receipt> receipts = await apiCaller.fetchReceipts();
    for (Receipt receipt in receipts) {
      await apiCaller.deleteReceipt(receipt);
    }

    receipts = await apiCaller.fetchReceipts();
    expect(receipts.length, 0);
  });

  test("Post receipt", () async {
    List<ReceiptItem> items = [
      ReceiptItem(
        itemName: "Snusk",
        amount: 9001,
      ),
    ];
    Receipt receipt = Receipt(
      id: 1,
      recipient: "ica",
      date: DateTime.utc(1970, 1, 1),
      items: items,
      total: 100.0,
      categoryID: 1,
      ocrText: "",
    );

    final postedReceipt = await apiCaller.postReceipt(receipt);
    List<Receipt> fetchedReceipts = await apiCaller.fetchReceipts();

    expect(fetchedReceipts, contains(postedReceipt));
  });

  test("Update image", () async {
    final image = XFile("../backend/tests/res/tsu.jpg");

    final receipts = await apiCaller.fetchReceipts();
    final id = receipts[0].id!;
    await apiCaller.updateImage(id, image);

    final responseImage = await apiCaller.fetchImage(id);
    final expectedBytes = await image.readAsBytes();
    final responseBytes = await responseImage.readAsBytes();

    final equals = const ListEquality().equals;
    expect(equals(expectedBytes, responseBytes), true);

    apiCaller.deleteImage(id);
  });

  test("Update receipt", () async {
    final receipt = (await apiCaller.fetchReceipts())[0];
    receipt.items[0].itemName = "Snus";
    await apiCaller.updateReceipt(receipt.id, receipt);
    final responseReceipts = await apiCaller.fetchReceipts();
    expect(responseReceipts, contains(receipt));
  });

  test("Post category", () async {
    final category = TransactionCategory(
      description: "Groceries",
      color: const Color(0xFFFF7733),
      id: categoryId,
    );

    await apiCaller.postCategory(category);

    List<TransactionCategory> fetchedCategories = await apiCaller.fetchCategories();
    expect(fetchedCategories, contains(category));

    await apiCaller.deleteCategory(categoryId);
  });

  test("Update category", () async {
    final originalDescription = "Explosives";

    final category = TransactionCategory(
      description: originalDescription,
      color: const Color(0xFFFF0000),
      id: categoryId,
    );

    await apiCaller.updateCategory(category);

    var fetchedCategories = await apiCaller.fetchCategories();
    expect(fetchedCategories, contains(category));

    category.description = "Nothing illegal";
    await apiCaller.updateCategory(category);

    fetchedCategories = await apiCaller.fetchCategories();
    expect(fetchedCategories, contains(category));

    category.description = originalDescription;
    expect(fetchedCategories, isNot(contains(category)));

    apiCaller.deleteCategory(category.id!);
  });

  test("Can log in twice", () async {
    Receipt receipt = Receipt(
      id: 6,
      recipient: "b",
      date: DateTime.utc(1987, 1, 1),
      items: [
        ReceiptItem(
          itemName: "d",
          amount: 1,
        ),
      ],
      total: 2,
      categoryID: 9,
      ocrText: "",
    );
    receipt = await apiCaller.postReceipt(receipt);

    await apiCaller.fetchLoginData(accountReportId, transactionReportId, true);
    final responseReceipts = await apiCaller.fetchReceipts();
    expect(responseReceipts, contains(receipt));
  });

  test("Post multiple receipts", () async {
    List<Receipt> receipts = [
      Receipt(
        id: 3,
        recipient: "ica",
        date: DateTime.utc(2001, 9, 11),
        items: [
          ReceiptItem(
            itemName: "Toalettpapper",
            amount: 1,
          ),
          ReceiptItem(
            itemName: "Fil",
            amount: 3,
          ),
        ],
        total: 99.0,
        categoryID: 2,
        ocrText: "",
      ),
      Receipt(
        id: 4,
        recipient: "gamestop",
        date: DateTime.utc(2022, 2, 24),
        items: [
          ReceiptItem(
            itemName: "Hollow Knight",
            amount: 1
          ),
          ReceiptItem(
            itemName: "Kerbal Space Program",
            amount: 1
          ),
        ],
        total: 300.0,
        categoryID: 3,
        ocrText: "",
      ),
    ];

    final responseReceipts = await apiCaller.postManyReceipts(receipts);
    final fetchedReceipts = await apiCaller.fetchReceipts();
    for (Receipt receipt in responseReceipts) {
      expect(fetchedReceipts, contains(receipt));
    }
  });
}
