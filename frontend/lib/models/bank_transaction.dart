class BankTransaction {
  late String? id;
  late String? accountId;
  late Amount amount;
  late Descriptions descriptions;
  late Dates dates;
  late Types? types;
  late String? status;
  late String? providerMutability;

  BankTransaction(
      {this.id,
      this.accountId,
      required this.amount,
      required this.descriptions,
      required this.dates,
      this.types,
      this.status,
      this.providerMutability});

  BankTransaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountId = json['accountId'];
    amount = (json['amount'] != null ? Amount.fromJson(json['amount']) : null)!;
    descriptions = (json['descriptions'] != null
        ? Descriptions.fromJson(json['descriptions'])
        : null)!;
    dates = (json['dates'] != null ? Dates.fromJson(json['dates']) : null)!;
    types = (json['types'] != null ? Types.fromJson(json['types']) : null)!;
    status = json['status'];
    providerMutability = json['providerMutability'];
  }

  Map<String, dynamic> toDbFormat() {
    final Map<String, dynamic> data = Map<String, dynamic>();

    data['id'] = id;
    data['accountId'] = accountId;
    data['amountvalueunscaledValue'] = amount.value.unscaledValue;
    data['amountvaluescale'] = amount.value.scale;
    data['amountcurrencyCode'] = amount.currencyCode;
    data['descriptionsoriginal'] = descriptions.original;
    data['descriptionsdisplay'] = descriptions.display;
    data['datesbooked'] = dates.booked;
    data['typestype'] = types!.type;
    data['status'] = status;
    data['providerMutability'] = providerMutability;
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['accountId'] = this.accountId;
    if (this.amount != null) {
      data['amount'] = this.amount.toJson();
    }
    if (this.descriptions != null) {
      data['descriptions'] = this.descriptions.toJson();
    }
    if (this.dates != null) {
      data['dates'] = this.dates.toJson();
    }
    if (this.types != null) {
      data['types'] = this.types!.toJson();
    }
    data['status'] = this.status;
    data['providerMutability'] = this.providerMutability;
    return data;
  }
}

class Amount {
  late Value value;
  late String currencyCode;

  Amount({required this.value, required this.currencyCode});

  Amount.fromJson(Map<String, dynamic> json) {
    value = (json['value'] != null ? Value.fromJson(json['value']) : null)!;
    currencyCode = json['currencyCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (value != null) {
      data['value'] = value.toJson();
    }
    data['currencyCode'] = currencyCode;
    return data;
  }
}

class Value {
  late String unscaledValue;
  late String scale;

  Value({required this.unscaledValue, required this.scale});

  Value.fromJson(Map<String, dynamic> json) {
    unscaledValue = json['unscaledValue'];
    scale = json['scale'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['unscaledValue'] = unscaledValue;
    data['scale'] = scale;
    return data;
  }
}

class Descriptions {
  late String original;
  late String display;

  Descriptions({required this.original, required this.display});

  Descriptions.fromJson(Map<String, dynamic> json) {
    original = json['original'];
    display = json['display'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['original'] = original;
    data['display'] = display;
    return data;
  }
}

class Dates {
  late String booked;

  Dates({required this.booked});

  Dates.fromJson(Map<String, dynamic> json) {
    booked = json['booked'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['booked'] = booked;
    return data;
  }
}

class Types {
  late String type;

  Types({required this.type});

  Types.fromJson(Map<String, dynamic> json) {
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['type'] = type;
    return data;
  }
}
