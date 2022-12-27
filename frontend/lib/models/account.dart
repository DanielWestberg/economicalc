class Account {
  String id;
  String holderName;
  String accountName;
  List<String> parties;
  String iban;
  String currencyCode;
  double balance;
  String ssn;
  String bankName;

  Account(
      {required this.id,
      required this.accountName,
      required this.currencyCode,
      required this.holderName,
      required this.iban,
      required this.parties,
      required this.balance,
      required this.ssn,
      required this.bankName});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'holderName': holderName,
      'accountName': accountName,
      'iban': iban,
      'currencyCode': currencyCode,
      'balance': balance.toString(),
      'ssn': ssn,
      'bankName': bankName
    };
  }
}
