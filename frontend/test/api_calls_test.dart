import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';

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

main() async {
  print("Report IDs can be found here: $tinkReportEndpoint");
  const accountReportId = String.fromEnvironment("accountReportId");
  const transactionReportId = String.fromEnvironment("transactionReportId");

  if (accountReportId == "") {
    throw const MissingParamException("accountReportId");
  }

  if (transactionReportId == "") {
    throw const MissingParamException("transactionReportId");
  }

  final loginData =
      await fetchLoginData(accountReportId, transactionReportId, true);
  final cookie = loginData.cookie;
  const int categoryId = 1234;

  setUpAll(() {});

  tearDownAll(() async {
    await deleteCategory(cookie, categoryId);

    List<Receipt> receipts = await fetchReceipts(cookie);
    for (Receipt receipt in receipts) {
      await deleteReceipt(cookie, receipt);
    }

    receipts = await fetchReceipts(cookie);
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
    );

    final postedReceipt = await postReceipt(cookie, receipt);
    List<Receipt> fetchedReceipts = await fetchReceipts(cookie);

    expect(fetchedReceipts, contains(postedReceipt));
  });

  test("Update image", () async {
    final image = XFile("../backend/tests/res/tsu.jpg");

    final receipts = await fetchReceipts(cookie);
    final id = receipts[0].id!;
    await updateImage(cookie, id, image);

    final responseImage = await fetchImage(cookie, id);
    final expectedBytes = await image.readAsBytes();
    final responseBytes = await responseImage.readAsBytes();

    final equals = const ListEquality().equals;
    expect(equals(expectedBytes, responseBytes), true);

    deleteImage(cookie, id);
  });

  test("Update receipt", () async {
    final receipt = (await fetchReceipts(cookie))[0];
    receipt.items[0].itemName = "Snus";
    await updateReceipt(cookie, receipt.id, receipt);
    final responseReceipts = await fetchReceipts(cookie);
    expect(responseReceipts, contains(receipt));
  });

  test("Post category", () async {
    final category = TransactionCategory(
      description: "Groceries",
      color: const Color(0xFFFF7733),
      id: categoryId,
    );

    await postCategory(cookie, category);

    List<TransactionCategory> fetchedCategories = await fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    await deleteCategory(cookie, categoryId);
  });

  test("Update category", () async {
    final originalDescription = "Explosives";

    final category = TransactionCategory(
      description: originalDescription,
      color: const Color(0xFFFF0000),
      id: categoryId,
    );

    await updateCategory(cookie, category);

    var fetchedCategories = await fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    category.description = "Nothing illegal";
    await updateCategory(cookie, category);

    fetchedCategories = await fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    category.description = originalDescription;
    expect(fetchedCategories, isNot(contains(category)));

    deleteCategory(cookie, category.id!);
  });

  test("Post multiple receipts", () async {
    List<Receipt> receipts = [
      Receipt(
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
      ),
      Receipt(
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
      ),
    ];

    final responseReceipts = await postManyReceipts(cookie, receipts);
    final fetchedReceipts = await fetchReceipts(cookie);
    for (Receipt receipt in responseReceipts) {
      expect(fetchedReceipts, contains(receipt));
    }
  });
}
