import 'dart:io';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/services/api_calls.dart';

// Acts as common interface for local db and backend db.
class UnifiedDb extends SQFLite {
  final ApiCaller _apiCaller = ApiCaller();
}