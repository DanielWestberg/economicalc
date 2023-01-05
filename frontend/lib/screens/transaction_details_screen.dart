import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/screens/home_screen.dart';
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
  late Future<List<TransactionCategory>> categoriesFutureBuilder;
  late List<TransactionCategory> categories;
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
                    alignment: Alignment.center,
                    onPressed: (() {
                      print("receipt");
                    }),
                    icon: Icon(Icons.receipt_long))
              ],
              toolbarHeight: 120,
              backgroundColor: Utils.mediumLightColor,
              foregroundColor: Colors.black,
              leading: IconButton(
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
                      if (widget.transaction.receiptID != null) {
                        Receipt receipt = await dbConnector
                            .getReceiptfromID(widget.transaction.receiptID!);
                        receipt.categoryDesc = dropdownValue;
                        await dbConnector.updateReceipt(receipt);
                      }
                      widget.transaction.categoryDesc = dropdownValue;
                      widget.transaction.categoryID = await dbConnector
                          .getCategoryIDfromDescription(dropdownValue!);
                      await dbConnector.updateTransaction(widget.transaction);
                      int? n = await dbConnector
                          .numOfCategoriesWithSameName(widget.transaction);
                      if (n > 0) {
                        showAlertDialog(context, n, dropdownValue!);
                      } else {
                        final snackBar = SnackBar(
                          backgroundColor: Utils.mediumDarkColor,
                          content: Text(
                            'Category was updated to $dropdownValue.',
                            style: TextStyle(color: Utils.lightColor),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    items: categories.map<DropdownMenuItem<String>>(
                        (TransactionCategory category) {
                      return DropdownMenuItem<String>(
                        value: category.description,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                  padding: EdgeInsets.only(right: 5),
                                  child: Icon(Icons.label_rounded,
                                      color: category.color)),
                              Text(
                                category.description,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: fontSize),
                              )
                            ]),
                      );
                    }).toList()));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  showAlertDialog(BuildContext context, int n, String dropdownValue) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
        final snackBar = SnackBar(
          backgroundColor: Utils.mediumDarkColor,
          content: Text(
            'Category was updated to $dropdownValue.',
            style: TextStyle(color: Utils.lightColor),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Yes"),
      onPressed: () {
        dbConnector.assignCategories(widget.transaction);
        Navigator.of(context).pop();
        final snackBar = SnackBar(
          backgroundColor: Utils.mediumDarkColor,
          content: Text(
            'Categories were updated to $dropdownValue.',
            style: TextStyle(color: Utils.lightColor),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                dropDown(),
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
                                  color: Utils.textColor, fontSize: fontSize),
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
                              color: Utils.textColor, fontSize: fontSize),
                        )),
                  ],
                )
              ],
            ),
            Expanded(
              child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(children: [
                    Icon(Icons.payment),
                    Text("${widget.transaction.totalAmount} kr",
                        style: TextStyle(fontSize: fontSize))
                  ])),
            )
          ],
        ));
  }

  Widget buildDataTable() {
    return FutureBuilder(
        future: receiptFutureBuilder,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("No data to show: ${snapshot.error}");
          } else if (snapshot.hasData) {
            receipt = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: receipt.items.length,
              itemBuilder: (BuildContext context, index) {
                return Dismissible(
                  direction: DismissDirection.endToStart,
                  key: UniqueKey(),
                  onDismissed: ((direction) {
                    setState(() {
                      receipt.total =
                          receipt.total! - receipt.items[index].amount;
                      receipt.total =
                          double.parse((receipt.total)!.toStringAsFixed(2));
                      receipt.items.removeAt(index);
                    });
                  }),
                  background: Container(
                    color: Colors.green,
                  ),
                  secondaryBackground: const ColoredBox(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 6,
                        child: TextFormField(
                          initialValue: receipt.items[index].itemName,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onFieldSubmitted: (value) {
                            setState(() {
                              receipt.items[index].itemName = value;
                            });
                          },
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: TextFormField(
                          initialValue: receipt.items[index].amount.toString(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onFieldSubmitted: (value) {
                            double oldAmount = receipt.items[index].amount;
                            setState(() {
                              double.tryParse(value) == null
                                  ? receipt.items[index].amount = 0
                                  : receipt.items[index].amount =
                                      double.parse(value);
                              receipt.total = receipt.total! - oldAmount;
                              receipt.total =
                                  receipt.total! + double.parse(value);
                              receipt.total = double.parse(
                                  (receipt.total)!.toStringAsFixed(2));
                            });
                          },
                        ),
                      )
                    ],
                  ),
                );
              },
            );
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

  Future<List<TransactionCategory>> getCategories(SQFLite dbConnector) async {
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
      onPressed: () async {
        await dbConnector.deleteReceipt(widget.transaction.receiptID!);
        if (widget.transaction.bankTransactionID == null) {
          await dbConnector.deleteTransaction(widget.transaction.id!);
        } else {
          widget.transaction.receiptID = null;
          await dbConnector.updateTransaction(widget.transaction);
        }
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => HomeScreen()));
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
