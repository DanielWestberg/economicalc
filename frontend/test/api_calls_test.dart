import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';

import 'package:economicalc_client/services/api_calls.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  String userId = "testUser";
  int categoryId = 1234;

  setUpAll(() async {
    await registerUser(userId);
  });

  tearDownAll(() async {
    await deleteCategory(userId, categoryId);

    List<Receipt> receipts = await fetchReceipts(userId);
    for (Receipt receipt in receipts) {
      await deleteReceipt(userId, receipt);
    }

    receipts = await fetchReceipts(userId);
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

    final postedReceipt = await postReceipt(userId, receipt);
    List<Receipt> fetchedReceipts = await fetchReceipts(userId);

    expect(fetchedReceipts, contains(postedReceipt));
  });

  test ("Update image", () async {
    final image = XFile("../backend/tests/res/tsu.jpg");

    final receipts = await fetchReceipts(userId);
    final backendId = receipts[0].backendId!;
    await updateImage(userId, backendId, image);

    final responseImage = await fetchImage(userId, backendId);
    final expectedBytes = await image.readAsBytes();
    final responseBytes = await responseImage.readAsBytes();

    final equals = const ListEquality().equals;
    expect(equals(expectedBytes, responseBytes), true);

    deleteImage(userId, backendId);
  });

  test ("Update receipt", () async {
    final receipt = (await fetchReceipts(userId))[0];
    receipt.items[0].itemName = "Snus";
    await updateReceipt(userId, receipt.backendId, receipt);
    final responseReceipts = await fetchReceipts(userId);
    expect(responseReceipts, contains(receipt));
  });

  test ("Post category", () async {
    final category = Category(
        description: "Groceries",
        color: const Color(0xFFFF7733),
        id: categoryId,
    );

    await postCategory(userId, category);

    List<Category> fetchedCategories = await fetchCategories(userId);
    expect(fetchedCategories, contains(category));

    await deleteCategory(userId, categoryId);
  });

  test ("Update category", () async {
    final originalDescription = "Explosives";

    final category = Category(
      description: originalDescription,
      color: const Color(0xFFFF0000),
      id: categoryId,
    );

    await updateCategory(userId, category);

    var fetchedCategories = await fetchCategories(userId);
    expect(fetchedCategories, contains(category));

    category.description = "Nothing illegal";
    await updateCategory(userId, category);

    fetchedCategories = await fetchCategories(userId);
    expect(fetchedCategories, contains(category));

    category.description = originalDescription;
    expect(fetchedCategories, isNot(contains(category)));

    deleteCategory(userId, category.id!);
  });

  test ("Post multiple receipts", () async {
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

    final responseReceipts = await postManyReceipts(userId, receipts);
    final fetchedReceipts = await fetchReceipts(userId);
    for (Receipt receipt in receipts) {
      expect(responseReceipts, contains(receipt));
      expect(fetchedReceipts, contains(receipt));
    }
  });
}