import 'package:frontend/helpers/utils.dart';
import 'package:frontend/models/transaction_event.dart';
import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatefulWidget {
  @override
  TransactionDetailsScreenState createState() =>
      TransactionDetailsScreenState();
}

class TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFB8D8D8),
          foregroundColor: Colors.black,
          title: const Text("EconomiCalc",
              style: TextStyle(
                  color: Color(0xff000000),
                  fontWeight: FontWeight.bold,
                  fontSize: 36.0)),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
            children: [headerInfo(), Expanded(child: buildDataTable())]));
  }

  Widget headerInfo() {
    return Container(
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                child: Column(children: [
              Text(
                "Mat & Dryck",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                "Ica Väst",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text("2022-10-01",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400))
            ])),
            Text("Total: 210.99 kr",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(
                onPressed: (() {
                  print("receipt");
                }),
                icon: Icon(Icons.receipt_long))
          ],
        ));
  }

  final columns = ["Items", "Price", "Qty", "Sum"];
  final rows = Utils.getMockedReceiptItems();

  Widget buildDataTable() {
    return DataTable(
        columnSpacing: 30,
        sortAscending: isAscending,
        sortColumnIndex: sortColumnIndex,
        columns: getColumns(columns),
        rows: getRows(rows));
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
          label: Text(column,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          onSort: onSort))
      .toList();

  List<DataRow> getRows(List<ReceiptItem> items) =>
      items.map((ReceiptItem item) {
        final cells = [item.itemName, item.price, item.quantity, item.sum];
        return DataRow(cells: getCells(cells));
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) =>
      cells.map((data) => DataCell(Text('$data'))).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      rows.sort((row1, row2) =>
          compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      rows.sort(
          (row1, row2) => compareNumber(ascending, row1.price, row2.price));
    } else if (columnIndex == 2) {
      rows.sort((row1, row2) =>
          compareNumber(ascending, row1.quantity, row2.quantity));
    } else if (columnIndex == 3) {
      rows.sort((row1, row2) => compareNumber(ascending, row1.sum, row2.sum));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  int compareNumber(bool ascending, num value1, num value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);
}
