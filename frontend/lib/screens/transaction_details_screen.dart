import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

var dropDownItems = Utils.categories;

class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;

  TransactionDetailsScreen(Key? key, this.transaction) : super(key: key);

  @override
  TransactionDetailsScreenState createState() =>
      TransactionDetailsScreenState();
}

class TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;
  double fontSize = 14;
  double sizedBoxWidth = 140;
  double sizedBoxHeight = 30;
  final columns = ["Items", "Sum"];
  final dbConnector = SQFLite.instance;
  late String? dropdownValue;
  late Future<List<Category>> categoriesFutureBuilder;
  late List<Category> categories;
  late Receipt receipt;
  late Future<Receipt>? receiptFutureBuilder;

  @override
  void initState() {
    super.initState();
    dbConnector.initDatabase();
    dropdownValue = widget.transaction.categoryDesc;
    categoriesFutureBuilder = getCategories(dbConnector);
    if (widget.transaction.receiptID != null) {
      receiptFutureBuilder =
          getReceipt(dbConnector, widget.transaction.receiptID!);
    } else {
      receiptFutureBuilder = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(right: 20, top: 30),
                    onPressed: (() {
                      print("receipt");
                    }),
                    icon: Icon(Icons.receipt_long))
              ],
              toolbarHeight: 180,
              backgroundColor: Utils.mediumLightColor,
              foregroundColor: Colors.black,
              leading: new IconButton(
                  onPressed: (() {
                    Navigator.pop(context);
                  }),
                  icon: Icon(Icons.arrow_back)),
              title: headerInfo(),
              centerTitle: false,
              elevation: 0,
            ),
            body:
                ListView(children: [buildDataTable(), deleteButton(context)])));
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
                    onChanged: (value) async {
                      setState(() {
                        dropdownValue = value;
                      });
                      widget.transaction.categoryDesc = dropdownValue;
                      widget.transaction.categoryID =
                          await SQFLite.getCategoryIDfromDescription(
                              dropdownValue!);
                      await dbConnector.updateTransaction(widget.transaction);
                      int? n = await dbConnector
                          .numOfCategoriesWithSameName(widget.transaction);
                      if (n > 0) {
                        showAlertDialog(context, n);
                      }
                    },
                    items: categories
                        .map<DropdownMenuItem<String>>((Category category) {
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

  showAlertDialog(BuildContext context, int n) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Yes"),
      onPressed: () {
        dbConnector.assignCategories(widget.transaction);
        Navigator.of(context).pop();
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
                  Padding(padding: EdgeInsets.only(left: 5), child: dropDown()),
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
                              widget.transaction.store!,
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
                padding: EdgeInsets.only(left: 10),
                child: Column(children: [
                  Icon(Icons.payment),
                  Text("${widget.transaction.totalAmount} kr",
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w600))
                ])),
          ],
        ));
  }

  Widget buildDataTable() {
    return FutureBuilder(
        future: receiptFutureBuilder,
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
                rows: getRows(receipt.items));
          } else {
            return Center(heightFactor: 20, child: Text("No receipt data"));
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

  Future<List<Category>> getCategories(SQFLite dbConnector) async {
    return await dbConnector.getAllcategories();
  }

  Future<Receipt> getReceipt(SQFLite dbConnector, int id) async {
    return await dbConnector.getReceiptfromID(id);
  }

  Widget deleteButton(BuildContext context) {
    return FutureBuilder(
        future: receiptFutureBuilder,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            receipt = snapshot.data!;
            return Center(
                heightFactor: 2,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteAlertDialog(context);
                  },
                ));
          } else {
            return Center(
                heightFactor: 2,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.black26,
                  onPressed: () {},
                ));
          }
        });
  }

  deleteAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Yes"),
      onPressed: () {
        dbConnector.deleteReceipt(widget.transaction.receiptID!);
        dbConnector.deleteTransaction(widget.transaction.id!);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete receipt"),
      content: Text(
          "Are you sure you want to delete this receipt? This action cannot be undone."),
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
}
