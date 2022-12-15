import 'dart:io';
import 'package:camera/camera.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
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
  double sizedBoxWidth = 150;
  double sizedBoxHeight = 30;
  final columns = ["Items", "Total"];
  bool isLoading = false;
  late Future<Receipt> dataFuture;
  late Receipt receipt;
  late Future<List<ReceiptCategory>> categoriesFutureBuilder;
  late List<ReceiptCategory> categories;
  final dbConnector = SQFLite.instance;
  int? categoryID;
  String dropdownValue =
      "Uncategorized"; // TODO: replace with suggested category

  @override
  void initState() {
    super.initState();
    isLoading = true;
    dataFuture = getTransactionFromImage(widget.image);
    dbConnector.initDatabase();
    categoriesFutureBuilder = getCategories(dbConnector);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: isLoading
            ? Scaffold(
                backgroundColor: Utils.backgroundColor,
                body: Center(
                    child: LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.black, size: 40)))
            : Scaffold(
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
            int receiptID =
                await dbConnector.insertReceipt(receipt, dropdownValue);
            Transaction transaction = Transaction(
              date: receipt.date,
              totalAmount: -receipt.total!,
              store: receipt.recipient,
              bankTransactionID: null,
              receiptID: receiptID,
              categoryID:
                  await SQFLite.getCategoryIDfromDescription(dropdownValue),
              categoryDesc: dropdownValue,
            );
            await dbConnector.insertTransaction(transaction);
            int? n = await dbConnector.numOfCategoriesWithSameName(transaction);
            if (n > 0) {
              showAlertDialog(context, n, transaction);
            }
          },
          child: Icon(Icons.check)),
    );
  }

  Widget dropDown() {
    return FutureBuilder(
        future: categoriesFutureBuilder,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            categories = snapshot.data!;

            return SizedBox(
                width: sizedBoxWidth,
                height: sizedBoxHeight,
                child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: dropdownValue,
                    onChanged: (
                      String? value,
                    ) {
                      setState(() {
                        dropdownValue = value!;
                        receipt.categoryDesc = dropdownValue;
                      });
                    },
                    items: categories
                        .map<DropdownMenuItem<String>>((ReceiptCategory category) {
                      return DropdownMenuItem<String>(
                        value: category.description,
                        child: Text(category.description,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: category.color)),
                      );
                    }).toList()));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  showAlertDialog(BuildContext context, int n, transaction) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No"),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Yes"),
      onPressed: () {
        dbConnector.assignCategories(transaction);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: n == 1
          ? Text("$n transaction with the same store name found")
          : Text("$n transactions with the same store name found"),
      content: n == 1
          ? Text(
              "Would you like to update the category for that transaction as well?")
          : Text(
              "Would you like to update the category for those transactions as well?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget headerInfo() {
    return FutureBuilder(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            receipt = snapshot.data!;
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
                            child: dropDown(),
                          ),
                        ]),
                        Row(
                          children: [
                            Icon(Icons.store),
                            Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: SizedBox(
                                    width: sizedBoxWidth,
                                    height: sizedBoxHeight,
                                    child: Text(
                                      receipt.recipient,
                                      style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w600),
                                    ))),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.date_range),
                            Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  DateFormat("yyyy-MM-dd")
                                      .format(receipt.date)
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
                        padding: EdgeInsets.only(left: 10),
                        child: Column(children: [
                          Icon(Icons.payment),
                          Text("${receipt.total} kr",
                              style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600))
                        ])),
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
            receipt = snapshot.data!;
            return DataTable(
                columnSpacing: 30,
                sortAscending: isAscending,
                sortColumnIndex: sortColumnIndex,
                columns: getColumns(columns),
                rows: getRows(receipt.items as List<ReceiptItem>));
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
      cells.map((data) => DataCell(
    TextFormField(
     initialValue: '$data',  
     onChanged: (value){
        print(receipt);
        if(data == cells[0]) {
          int index = receipt.items.indexWhere((element) => element.itemName == data);
          setState(() {
            receipt.items[index].itemName = value;
          });
        } else {
          int index = receipt.items.indexWhere((element) => element.amount == data && element.itemName == cells[0]);
          double newValue = 0;
          double.tryParse(value) == null ? newValue = 0 : newValue = double.parse(value);
        
          setState(() {
            receipt.items[index].amount = newValue;
            receipt.total = receipt.total! - data;
            receipt.total = receipt.total! + newValue;
            receipt.total = double.parse((receipt.total)!.toStringAsFixed(2));
          });
        }
        
     },
   ),
  
)).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      receipt.items.sort((row1, row2) =>
          Utils.compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      receipt.items.sort((row1, row2) =>
          Utils.compareNumber(ascending, row1.amount, row2.amount));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  Future<Receipt> getTransactionFromImage(image) async {
    final imageFile = File(image.path);
    var response = await processImageWithAsprise(imageFile);
    Receipt receipt = Receipt.fromJson(response);

    setState(() {
      isLoading = false;
    });

    return receipt;
  }

  Future<List<ReceiptCategory>> getCategories(SQFLite dbConnector) async {
    return await dbConnector.getAllcategories();
  }
}
