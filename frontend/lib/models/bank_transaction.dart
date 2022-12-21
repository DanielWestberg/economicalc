import 'package:intl/intl.dart';

class BankTransaction {
  late String? id;
  late DateTime date;
  late double amount;
  late String description;

  BankTransaction(
      {this.id,
      required this.amount,
      required this.description,
      required this.date});

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    double amount = 0;
    if (json['amount']['value']['unscaledValue'] != null &&
        json['amount']['value']['scale'] != null) {
      amount = double.parse(json['amount']['value']['unscaledValue']);
      int scale = int.parse(json['amount']['value']['scale']);
      if (scale == 1) amount = amount / 10;
      if (scale == 2) amount = amount / 100;
      if (scale == 3) amount = amount / 1000;
    }
    return BankTransaction(
        id: json['id'],
        amount: amount,
        description: json['descriptions']['display'] != null
            ? json['descriptions']['display']
            : null,
        date: (json['dates']['booked'] != null
            ? DateFormat('yyyy-MM-dd').parse(json['dates']['booked'])
            : null)!);
  }

  factory BankTransaction.fromDB(Map<String, dynamic> json) {
    return BankTransaction(
        id: json['id'],
        amount: double.parse(json['amountvalueunscaledValue']),
        description: json['descriptionsdisplay'],
        date: DateFormat('yyyy-MM-dd').parse(json['datesbooked']));
  }

  Map<String, dynamic> toDbFormat() {
    final Map<String, dynamic> data = Map<String, dynamic>();

    data['id'] = id;
    data['amountvalueunscaledValue'] = amount;
    data['descriptionsdisplay'] = description;
    data['datesbooked'] = date.toIso8601String();
    return data;
  }
}
