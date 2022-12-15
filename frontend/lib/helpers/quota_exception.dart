class QuotaException implements Exception {
  String cause;
  QuotaException(this.cause);
}

void main() {
  try {
    throwException();
  } on QuotaException {
    print(
        'Hourly quota exceeded. Try again in a few hours or contact us to increase the quota: ocr@asprise.com');
  }
}

throwException() {
  throw QuotaException(
      'Hourly quota exceeded. Try again in a few hours or contact us to increase the quota: ocr@asprise.com');
}
