import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatefulWidget {
  @override
  TransactionDetailsScreenState createState() =>
      TransactionDetailsScreenState();
}

class TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;
  double fontSize = 16;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 180,
              backgroundColor: Color(0xFFB8D8D8),
              foregroundColor: Colors.black,
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text("EconomiCalc",
                            style: TextStyle(
                                color: Color(0xff000000),
                                fontWeight: FontWeight.bold,
                                fontSize: 36.0))),
                    headerInfo()
                  ]),
              centerTitle: false,
              elevation: 0,
            ),
            body: ListView(children: [buildDataTable()])));
  }

  Widget headerInfo() {
    return Container(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.category),
                  Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(
                        "Mat & Dryck",
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.w600),
                      )),
                ]),
                Row(
                  children: [
                    Icon(Icons.store),
                    Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          "Ica",
                          style: TextStyle(
                              fontSize: fontSize, fontWeight: FontWeight.w600),
                        )),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.date_range),
                    Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          "2022-10-01",
                          style: TextStyle(
                              fontSize: fontSize, fontWeight: FontWeight.w600),
                        )),
                  ],
                )
              ],
            ),
            Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.payment),
                  Text("210.99 kr",
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w600))
                ])),
            IconButton(
                padding: EdgeInsets.all(20),
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
        final cells = [
          item.itemName,
          item.price,
          item.quantity,
          double.parse((item.sum).toStringAsFixed(2))
        ];
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
