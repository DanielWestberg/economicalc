import 'package:economicalc_client/models/account.dart';

class Bank {
  String ssn;
  String name;
  String bankName;
  String providerName;

  Bank({
    required this.ssn,
    required this.bankName,
    required this.name,
    required this.providerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'ssn': ssn,
      'bankName': bankName,
      'name': name,
      'providerName': providerName
    };
  }

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      ssn: json['userDataByprovider'],
      name: json[''],
      bankName: json[''],
      providerName: json[''],
    );
  }
}
