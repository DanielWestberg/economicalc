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
  get message =>
      "Missing parameter $paramName. "
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

  final loginData = await fetchLoginData(
      accountReportId, transactionReportId, true
  );
  final cookie = loginData.cookie;
  const int categoryId = 1234;

  setUpAll(() {
  });

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

  test ("Update image", () async {
    final image = XFile("../backend/tests/res/tsu.jpg");

    final receipts = await fetchReceipts(cookie);
    final backendId = receipts[0].backendId!;
    await updateImage(cookie, backendId, image);

    final responseImage = await fetchImage(cookie, backendId);
    final expectedBytes = await image.readAsBytes();
    final responseBytes = await responseImage.readAsBytes();

    final equals = const ListEquality().equals;
    expect(equals(expectedBytes, responseBytes), true);

    deleteImage(cookie, backendId);
  });

  test ("Update receipt", () async {
    final receipt = (await fetchReceipts(cookie))[0];
    receipt.items[0].itemName = "Snus";
    await updateReceipt(cookie, receipt.backendId, receipt);
    final responseReceipts = await fetchReceipts(cookie);
    expect(responseReceipts, contains(receipt));
  });

  test ("Post category", () async {
    final category = Category(
        description: "Groceries",
        color: const Color(0xFFFF7733),
        id: categoryId,
    );

    await postCategory(cookie, category);

    List<Category> fetchedCategories = await fetchCategories(cookie);
    expect(fetchedCategories, contains(category));

    await deleteCategory(cookie, categoryId);
  });

  test ("Update category", () async {
    final originalDescription = "Explosives";

    final category = Category(
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
}