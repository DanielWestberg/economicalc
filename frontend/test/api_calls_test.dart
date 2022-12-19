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
  final apiCaller = ApiCaller();
  print("Report IDs can be found here: ${apiCaller.tinkReportEndpoint}");
  const accountReportId = String.fromEnvironment("accountReportId");
  const transactionReportId = String.fromEnvironment("transactionReportId");

  if (accountReportId == "") {
    throw const MissingParamException("accountReportId");
  }

  if (transactionReportId == "") {
    throw const MissingParamException("transactionReportId");
  }

  final loginData = await
      apiCaller.fetchLoginData(accountReportId, transactionReportId, true);
  final cookie = loginData.cookie;
  const int categoryId = 1234;

  setUpAll(() {});

  tearDownAll(() async {
    await apiCaller.deleteCategory(cookie, categoryId);

    List<Receipt> receipts = await apiCaller.fetchReceipts(cookie);
    for (Receipt receipt in receipts) {
      await apiCaller.deleteReceipt(cookie, receipt);
    }

    receipts = await apiCaller.fetchReceipts(cookie);
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

    final postedReceipt = await apiCaller.postReceipt(cookie, receipt);
    List<Receipt> fetchedReceipts = await apiCaller.fetchReceipts(cookie);

    expect(fetchedReceipts, contains(postedReceipt));
  });

  test("Update image", () async {
    final image = XFile("../backend/tests/res/tsu.jpg");

    final receipts = await apiCaller.fetchReceipts(cookie);
    final id = receipts[0].id!;
    await apiCaller.updateImage(cookie, id, image);

    final responseImage = await apiCaller.fetchImage(cookie, id);
    final expectedBytes = await image.readAsBytes();
    final responseBytes = await responseImage.readAsBytes();

    final equals = const ListEquality().equals;
    expect(equals(expectedBytes, responseBytes), true);

    apiCaller.deleteImage(cookie, id);
  });

  test("Update receipt", () async {
    final receipt = (await apiCaller.fetchReceipts(cookie))[0];
    receipt.items[0].itemName = "Snus";
    await apiCaller.updateReceipt(cookie, receipt.id, receipt);
    final responseReceipts = await apiCaller.fetchReceipts(cookie);
    expect(responseReceipts, contains(receipt));
  });

  test("Post category", () async {
    final category = TransactionCategory(
      description: "Groceries",
      color: const Color(0xFFFF7733),
      id: categoryId,
    );

    await apiCaller.postCategory(cookie, category);

    List<TransactionCategory> fetchedCategories = await apiCaller.fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    await apiCaller.deleteCategory(cookie, categoryId);
  });

  test("Update category", () async {
    final originalDescription = "Explosives";

    final category = TransactionCategory(
      description: originalDescription,
      color: const Color(0xFFFF0000),
      id: categoryId,
    );

    await apiCaller.updateCategory(cookie, category);

    var fetchedCategories = await apiCaller.fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    category.description = "Nothing illegal";
    await apiCaller.updateCategory(cookie, category);

    fetchedCategories = await apiCaller.fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    category.description = originalDescription;
    expect(fetchedCategories, isNot(contains(category)));

    apiCaller.deleteCategory(cookie, category.id!);
  });
}
