import 'dart:io';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/services/api_calls.dart';

import 'package:sqflite/sqflite.dart' show DatabaseFactory;

// Acts as common interface for local db and backend db.
class UnifiedDb extends SQFLite {
  final ApiCaller _apiCaller = ApiCaller();

  UnifiedDb({DatabaseFactory? dbFactory, Future<String> Function()? path}) :
    super(dbFactory: dbFactory, path: path);

  static UnifiedDb? _instance;
  static UnifiedDb get instance {
    _instance ??= UnifiedDb();
    return _instance!;
  }
}