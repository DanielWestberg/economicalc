import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert' as convert;

class LoginData {
  final Map<String, dynamic> accountReport;
  final Map<String, dynamic> transactionReport;

  LoginData({
    required this.accountReport,
    required this.transactionReport,
  });


  factory LoginData.fromResponse(http.Response response) {
    final dict = convert.jsonDecode(response.body)["data"];
    return LoginData(
      accountReport: dict["account_report"],
      transactionReport: dict["transaction_report"],
    );
  }
}
