int compareString(bool ascending, String value1, String value2) =>
    ascending ? value1.compareTo(value2) : value2.compareTo(value1);

int compareNumber(bool ascending, num value1, num value2) =>
    ascending ? value1.compareTo(value2) : value2.compareTo(value1);
