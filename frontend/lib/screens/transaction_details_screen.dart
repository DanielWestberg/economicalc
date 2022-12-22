import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/screens/results_screen.dart';
import 'package:economicalc_client/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
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
  double fontSize = 16;
  double sizedBoxWidth = 240;
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

  void goToResults(XFile? image, BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => ResultsScreen(
                  image: image,
                  existingTransaction: widget.transaction,
                )))
        .then((value) {
      if (value != false) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    TransactionDetailsScreen(null, widget.transaction)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 230,
              backgroundColor: Utils.mediumLightColor,
              foregroundColor: Utils.lightColor,
              leading: Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(top: 10, left: 10),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(0),
                          alignment: Alignment.center,
                          backgroundColor: Utils.lightColor,
                          foregroundColor: Utils.mediumDarkColor),
                      onPressed: (() {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()));
                      }),
                      child: Icon(Icons.arrow_back))),
              actions: [
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(top: 10, right: 10),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(0),
                        alignment: Alignment.center,
                        backgroundColor: Utils.lightColor,
                        foregroundColor: Utils.mediumDarkColor,
                      ),
                      onPressed: (() {
                        widget.transaction.receiptID != null
                            ? Text("TODO: Show image")
                            : receiptBtnAlertDialog(context);
                      }),
                      child: Icon(Icons.receipt_long_rounded)),
                )
              ],
              flexibleSpace: headerInfo(),
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

            return DropdownButton<String>(
                dropdownColor: Utils.lightColor,
                isDense: true,
                itemHeight: null,
                isExpanded: true,
                elevation: 0,
                underline: SizedBox(),
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
                      backgroundColor: Utils.darkColor,
                      content: Text(
                        'Category was updated to $dropdownValue.',
                        style: GoogleFonts.roboto(color: Utils.lightColor),
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
                          SizedBox(
                              width: 250,
                              child: Text(
                                category.description,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(fontSize: fontSize),
                              ))
                        ]),
                  );
                }).toList());
          } else {
            return Text("Unexpected error");
          }
        });
  }

  showAlertDialog(BuildContext context, int n, String dropdownValue) {
    // set up the buttons
    Widget cancelButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
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
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
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

  receiptBtnAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueCameraButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      onPressed: (() async {
        final XFile? image =
            await ImagePicker().pickImage(source: ImageSource.camera);
        if (image == null) return;
        ImageGallerySaver.saveFile(image.path);
        goToResults(image, context);
      }),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text("Yes "), Icon(Icons.camera_alt_outlined)]),
    );
    Widget continuePickerButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      onPressed: (() async {
        final XFile? image =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image == null) return;
        goToResults(image, context);
      }),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text("Yes "), Icon(Icons.filter_rounded)]),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("No receipt found"),
      content: Text(
          "Would you like to attach a receipt to the current transaction?"),
      actions: [cancelButton, continueCameraButton, continuePickerButton],
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
        padding: EdgeInsets.only(top: 10, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(top: 20),
              alignment: Alignment.center,
              child: Text(
                  widget.transaction.receiptID != null
                      ? "Receipt"
                      : "Bank transaction",
                  style: GoogleFonts.roboto(fontSize: fontSize * 1.6)),
            ),
            Container(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  widget.transaction.store!,
                  style: GoogleFonts.roboto(fontSize: fontSize),
                )),
            Container(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  DateFormat("yyyy-MM-dd").format(widget.transaction.date),
                  style: GoogleFonts.roboto(fontSize: fontSize),
                )),
            Container(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                    NumberFormat.currency(
                      locale: 'sv_SE',
                    ).format(widget.transaction.totalAmount),
                    style: GoogleFonts.roboto(fontSize: fontSize))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: EdgeInsets.only(top: 15, bottom: 5),
                child: Text(
                  'Set category for transaction:',
                  style: GoogleFonts.roboto(fontSize: fontSize),
                ),
              ),
              Container(
                alignment: Alignment.center,
                height: 40,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Utils.lightColor),
                padding: EdgeInsets.only(left: 5, right: 10),
                child: Expanded(child: dropDown()),
              )
            ]),
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
