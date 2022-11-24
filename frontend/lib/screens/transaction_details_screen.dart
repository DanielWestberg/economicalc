import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Receipt transaction;

  TransactionDetailsScreen(Key? key, this.transaction) : super(key: key);

  @override
  TransactionDetailsScreenState createState() =>
      TransactionDetailsScreenState();
}

class TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;
  double fontSize = 14;
  final columns = ["Items", "Sum"];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 180,
              backgroundColor: Utils.backgroundColor,
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
                          widget.transaction.recipient,
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
                          DateFormat("yyyy-MM-dd")
                              .format(widget.transaction.date)
                              .toString(),
                          style: TextStyle(
                              fontSize: fontSize, fontWeight: FontWeight.w600),
                        )),
                  ],
                )
              ],
            ),
            Padding(
                padding: EdgeInsets.all(10),
                child: Column(children: [
                  Icon(Icons.payment),
                  Text("${widget.transaction.total} kr",
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w600))
                ])),
            IconButton(
                padding: EdgeInsets.all(10),
                onPressed: (() {
                  print("receipt");
                }),
                icon: Icon(Icons.receipt_long))
          ],
        ));
  }

  Widget buildDataTable() {
    return DataTable(
        columnSpacing: 30,
        sortAscending: isAscending,
        sortColumnIndex: sortColumnIndex,
        columns: getColumns(columns),
        rows: getRows(widget.transaction.items as List<ReceiptItem>));
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
          label: Text(column,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          onSort: onSort))
      .toList();

  List<DataRow> getRows(List<ReceiptItem> items) =>
      items.map((ReceiptItem item) {
        final cells = [item.itemName, item.amount];
        return DataRow(cells: getCells(cells));
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) =>
      cells.map((data) => DataCell(Text('$data'))).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      widget.transaction.items.sort((row1, row2) =>
          Utils.compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      widget.transaction.items.sort((row1, row2) =>
          Utils.compareNumber(ascending, row1.amount, row2.amount));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }
}
