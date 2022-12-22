import 'dart:io';
import 'package:camera/camera.dart';
import 'package:economicalc_client/helpers/quota_exception.dart';
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
  late Future<List<TransactionCategory>> categoriesFutureBuilder;
  late List<TransactionCategory> categories;
  final dbConnector = SQFLite.instance;
  int? categoryID;
  String dropdownValue =
      "Uncategorized"; // TODO: replace with suggested category
  int backupTotal = 0;

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
                backgroundColor: Utils.mediumLightColor,
                body: Center(
                    child: LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.black, size: 40)))
            : Scaffold(
                appBar: AppBar(
                  backgroundColor: Utils.mediumLightColor,
                  foregroundColor: Colors.black,
                  title: Text('Scan result'),
                  centerTitle: true,
                  elevation: 0,
                  actions: [confirmButton()],
                ),
                body: ListView(scrollDirection: Axis.vertical, children: [
                  photoArea(),
                  headerInfo(),
                  buildDataTable(),
                  addButton(),
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

  Widget confirmButton() {
    return IconButton(
      onPressed: () async {
        int receiptID = await dbConnector.insertReceipt(receipt, dropdownValue);
        Transaction transaction = Transaction(
          date: receipt.date,
          totalAmount: -receipt.total!,
          store: receipt.recipient,
          receiptID: receiptID,
          categoryID:
              await dbConnector.getCategoryIDfromDescription(dropdownValue),
          categoryDesc: dropdownValue,
        );
        Transaction? alreadyExists =
            await dbConnector.checkForExistingTransaction(transaction);
        if (alreadyExists != null) {
          alreadyExists.receiptID = receiptID;
          alreadyExists.date = transaction.date;
          alreadyExists.categoryDesc = transaction.categoryDesc;
          alreadyExists.categoryID = transaction.categoryID;
          await dbConnector.updateTransaction(alreadyExists);
          final snackBar = SnackBar(
            backgroundColor: Utils.mediumDarkColor,
            content: Text(
              "Receipt was added to existing identical bank transaction",
              style: TextStyle(color: Utils.lightColor),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          await dbConnector.insertTransaction(transaction);
        }
        int? n = await dbConnector.numOfCategoriesWithSameName(transaction);
        if (n > 0) {
          showAlertDialog(context, n, transaction);
        } else {
          showConfirmationButton(context);
        }
      },
      icon: Icon(Icons.check),
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
                    ) async {
                      int? categoryID = await dbConnector
                          .getCategoryIDfromDescription(dropdownValue);
                      setState(() {
                        dropdownValue = value!;
                        receipt.categoryDesc = dropdownValue;
                        receipt.categoryID = categoryID;
                      });
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

  showConfirmationButton(BuildContext context) {
    Widget confirmationButton = TextButton(
      child: Text("Ok"),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
    AlertDialog alert = AlertDialog(
      content: Text("Receipt successfully added!"),
      actions: [
        confirmationButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    ).then((value) => Navigator.of(context).popUntil((route) => route.isFirst));
  }

  showAlertDialog(BuildContext context, int n, transaction) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("No"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        showConfirmationButton(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Yes"),
      onPressed: () {
        dbConnector.assignCategories(transaction);
        Navigator.of(context, rootNavigator: true).pop('dialog');
        showConfirmationButton(context);
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
                          Text("${getTotal(receipt)} kr",
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

  List<DataCell> getCells(List<dynamic> cells) => cells
      .map((data) => DataCell(
            TextFormField(
              initialValue: '$data',
              onChanged: (value) {
                print(receipt);
                if (data == cells[0]) {
                  int index = receipt.items
                      .indexWhere((element) => element.itemName == data);
                  setState(() {
                    receipt.items[index].itemName = value;
                  });
                } else {
                  int index = receipt.items.indexWhere((element) =>
                      element.amount == data && element.itemName == cells[0]);
                  double newValue = 0;
                  double.tryParse(value) == null
                      ? newValue = 0
                      : newValue = double.parse(value);

                  setState(() {
                    receipt.items[index].amount = newValue;
                    receipt.total = receipt.total! - data;
                    receipt.total = receipt.total! + newValue;
                    receipt.total =
                        double.parse((receipt.total)!.toStringAsFixed(2));
                  });
                }
              },
            ),
          ))
      .toList();

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
    try {
      var response = await processImageWithAsprise(imageFile);
      Receipt receipt = Receipt.fromJson(response);
      receipt = Utils.cleanReceipt(receipt);

      setState(() {
        isLoading = false;
      });

      return receipt;
    } on QuotaException catch (e) {
      Navigator.of(context).pop(false);
      final snackBar = SnackBar(
        backgroundColor: Utils.errorColor,
        content: Text(
          'ERROR: Hourly quota exceeded. Try again in a few hours or use a VPN.',
          style: TextStyle(color: Colors.white),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      rethrow;
    } catch (e) {
      Navigator.of(context).pop(false);
      final snackBar = SnackBar(
        backgroundColor: Utils.errorColor,
        content: Text(
          'ERROR: Image could not be processed.',
          style: TextStyle(color: Colors.white),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      rethrow;
    }
  }

  Future<List<TransactionCategory>> getCategories(SQFLite dbConnector) async {
    return await dbConnector.getAllcategories();
  }

  Widget addButton() {
    return Container(
      padding: EdgeInsets.all(40),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Utils.mediumLightColor,
            foregroundColor: Utils.textColor,
          ),
          onPressed: () async {
            setState(() {
              receipt.items.add(ReceiptItem(itemName: "", amount: 0));
            });
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("Add item "), Icon(Icons.add)])),
    );
  }

  double? getTotal(Receipt receipt) {
    if (receipt.total != null) return receipt.total;
    double? newTotal = 0;
    for (var item in receipt.items) {
      newTotal = newTotal! + item.amount;
    }
    setState(() {
      receipt.total = newTotal;
    });
    return newTotal;
  }
}
