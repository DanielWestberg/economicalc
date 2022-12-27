class Account {
  String accountNr;
  String holderName;
  String accountName;
  List<String> parties;
  String iban;
  String currencyCode;
  String id;

  Account(
    this.accountNr,
    this.accountName,
    this.currencyCode,
    this.holderName,
    this.iban,
    this.id,
    this.parties,
  );
}
