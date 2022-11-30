import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:intl/intl.dart';

class Transaction {
  int? id;
  DateTime date;
  double? totalAmount;
  String? store;
  String? bankTransactionID;
  int? receiptID;
  int? categoryID;
  String? categoryDesc;

  Transaction(
      {this.id,
      required this.date,
      this.totalAmount,
      this.store,
      this.bankTransactionID,
      this.receiptID,
      this.categoryID,
      this.categoryDesc});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'store': store,
      'bankTransactionID': bankTransactionID,
      'receiptID': receiptID,
      'categoryID': categoryID,
      'categoryDesc': categoryDesc
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: DateFormat('yyyy-MM-dd').parse(json['date']),
      totalAmount: json['totalAmount'],
      store: json['store'],
      bankTransactionID: json['bankTransactionID'],
      receiptID: json['receiptID'],
      categoryID: json['categoryID'],
      categoryDesc: json['categoryDesc'],
    );
  }
}
