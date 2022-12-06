import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';

import 'package:economicalc_client/services/api_calls.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  String userId = "testUser";

  setUpAll(() async {
    await registerUser(userId);
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
        description:"Groceries",
        color: const Color(0xFFFF7733),
        id: 1234,
    );

    await postCategory(userId, category);

    List<Category> fetchedCategories = await fetchCategories(userId);
    expect(fetchedCategories, contains(category));
  });
}