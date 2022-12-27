import 'package:economicalc_client/models/account.dart';

class Bank {
  String ssn;
  String name;
  String bankName;
  String providerName;
  List<Account> accounts;
  double balance;

  Bank(
    this.ssn,
    this.accounts,
    this.balance,
    this.bankName,
    this.name,
    this.providerName,
  );
}
