import 'dart:io';
import 'package:camera/camera.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/api_calls.dart';

class ResultsScreen extends StatefulWidget {
  final XFile? image;

  const ResultsScreen({super.key, required this.image});

  @override
  ResultsScreenState createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;
  double fontSize = 14;
  final columns = ["Items", "Total"];
  bool isLoading = false;
  late Future<Receipt> dataFuture;
  late Receipt transaction;
  final dbConnector = SQFLite.instance;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    dataFuture = getTransactionFromImage(widget.image);
    dbConnector.initDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: isLoading
            ? Scaffold(
                backgroundColor: Color(0xFFB8D8D8),
                body: Center(
                    child: LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.black, size: 20)))
            : Scaffold(
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
                      ]),
                  centerTitle: false,
                  elevation: 0,
                ),
                body: ListView(children: [
                  photoArea(),
                  buttonArea(),
                  headerInfo(),
                  buildDataTable()
                ])));
  }

  Widget photoArea() {
    return Container(
        height: 250,
        width: 300,
        padding: EdgeInsets.only(top: 10, bottom: 30),
        child: GestureDetector(
          onTap: () {
            showImageViewer(context, FileImage(File(widget.image!.path)));
          },
          child: Image.file(File(widget.image!.path), fit: BoxFit.contain),
        ));
  }

  Widget buttonArea() {
    return Container(
      padding: EdgeInsets.only(bottom: 30),
      child: GestureDetector(
          onTap: () async {
            await dbConnector.inserttransaction(transaction);
            Navigator.pop(context);
          },
          child: Icon(Icons.check)),
    );
  }

  Widget headerInfo() {
    return FutureBuilder(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            transaction = snapshot.data!;
            return Container(
                padding: EdgeInsets.only(top: 10, left: 50, bottom: 20),
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
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600),
                              )),
                        ]),
                        Row(
                          children: [
                            Icon(Icons.store),
                            Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  transaction.recipient,
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600),
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
                                      .format(transaction.date)
                                      .toString(),
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600),
                                )),
                          ],
                        )
                      ],
                    ),
                    Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(children: [
                          Icon(Icons.payment),
                          Text("${transaction.total} kr",
                              style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600))
                        ])),
                    IconButton(
                        padding: EdgeInsets.all(10),
                        onPressed: (() {
                          print("receipt");
                        }),
                        icon: Icon(Icons.receipt_long))
                  ],
                ));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  Widget buildDataTable() {
    return FutureBuilder(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            transaction = snapshot.data!;
            return DataTable(
                columnSpacing: 30,
                sortAscending: isAscending,
                sortColumnIndex: sortColumnIndex,
                columns: getColumns(columns),
                rows: getRows(transaction.items as List<ReceiptItem>));
          } else {
            return Text("Unexpected error");
          }
        });
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
      transaction.items.sort((row1, row2) =>
          compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      transaction.items.sort(
          (row1, row2) => compareNumber(ascending, row1.amount, row2.amount));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  Future<Receipt> getTransactionFromImage(image) async {
    final imageFile = File(image.path);
    var response = await processImageWithAsprise(imageFile);
    Receipt transaction = Receipt.fromJson(response);

    setState(() {
      isLoading = false;
    });

    return transaction;
  }
}
