import 'dart:io';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/helpers/unified_db.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/screens/results_screen.dart';
import 'package:economicalc_client/screens/home_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final dbConnector = UnifiedDb.instance;
  late String? dropdownValue;
  late Future<List<TransactionCategory>> categoriesFutureBuilder;
  late List<TransactionCategory> categories;
  late Receipt receipt;
  late Future<Receipt>? receiptFutureBuilder;
  final apiCaller = ApiCaller();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

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

  showReceiptImage(context) async {
    Receipt receipt =
        await dbConnector.getReceiptfromID(widget.transaction.receiptID!);
    if (apiCaller.cookie != null) {
      XFile image = await apiCaller.fetchImage(widget.transaction.receiptID!);
      receipt.imagePath = image.path;
      await dbConnector.updateReceipt(receipt);
    }
    return showImageViewer(context, FileImage(File(receipt.imagePath!)));
  }

  @override
  Widget build(BuildContext context) {
    Future<List<dynamic>> list;
    bool isReceipt = false;
    if (receiptFutureBuilder != null) {
      list = Future.wait([categoriesFutureBuilder, receiptFutureBuilder!]);
      isReceipt = true;
    } else {
      list = Future.wait([categoriesFutureBuilder]);
    }
    return FutureBuilder(
        future: list,
        builder: (context, snapshot) {
          if (snapshot.hasData && isReceipt == false) {
            categories = snapshot.data![0];
            return SafeArea(
                child: Scaffold(
              appBar: appbar(context, isReceipt),
              body: Container(
                child:
                    Center(child: Text("No receipt data for this transaction")),
              ),
            ));
          } else if (snapshot.hasData) {
            if (isReceipt) {
              receipt = snapshot.data![1] as Receipt;
            }

            categories = snapshot.data![0] as List<TransactionCategory>;

            return SafeArea(
                child: Scaffold(
                    appBar: appbar(context, isReceipt),
                    body: ListView(children: [
                      buildDataTable(),
                      widget.transaction.bankTransactionID == null
                          ? addButton()
                          : Text(""),
                      deleteButton(context),
                    ])));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  AppBar appbar(BuildContext context, bool isReceipt) {
    return AppBar(
      toolbarHeight: widget.transaction.store!.length > 45 ? 265 : 245,
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
                Navigator.of(context).popUntil((route) => route.isFirst);
              }),
              child: Icon(Icons.arrow_back))),
      actions: [
        Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 10, right: 0),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(0),
                alignment: Alignment.center,
                backgroundColor: Utils.lightColor,
                foregroundColor: Utils.mediumDarkColor,
              ),
              onPressed: (() async {
                widget.transaction.receiptID != null
                    ? await showReceiptImage(context)
                    : receiptBtnAlertDialog(context);
              }),
              child: Icon(Icons.receipt_long_rounded)),
        ),
        if (isReceipt) confirmButton(),
      ],
      flexibleSpace: headerInfo(isReceipt),
    );
  }

  Widget confirmButton() {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 10, right: 5),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(0),
            alignment: Alignment.center,
            backgroundColor: Utils.lightColor,
            foregroundColor: Utils.mediumDarkColor,
          ),
          onPressed: () async {
            await dbConnector.updateReceipt(receipt);
            await dbConnector.updateTransaction(widget.transaction);
            if (apiCaller.cookie != null) {
              await apiCaller.postReceipt(receipt);
            }
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.check)])),
    );
  }

  Widget dropDown() {
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
          widget.transaction.categoryID =
              await dbConnector.getCategoryIDfromDescription(dropdownValue!);
          await dbConnector.updateTransaction(widget.transaction);
          List<Transaction> transToUpdate =
              await dbConnector.numOfCategoriesWithSameName(widget.transaction);
          if (transToUpdate.length > 1) {
            showAlertDialog(context, transToUpdate, dropdownValue!);
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
        items: categories
            .map<DropdownMenuItem<String>>((TransactionCategory category) {
          return DropdownMenuItem<String>(
            value: category.description,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(Icons.label_rounded, color: category.color)),
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
  }

  showAlertDialog(BuildContext context, List<Transaction> transToUpdate,
      String dropdownValue) {
    int n = transToUpdate.length - 1;
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
        for (Transaction tran in transToUpdate) {
          dbConnector.updateTransaction(tran);
        }
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

  Widget headerInfo(bool isReceipt) {
    return Container(
        padding: EdgeInsets.only(top: 10, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(top: 15, bottom: 5),
              alignment: Alignment.center,
              child: Text(
                  widget.transaction.receiptID != null
                      ? "Receipt"
                      : "Bank transaction",
                  style: GoogleFonts.roboto(fontSize: fontSize * 1.6)),
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 0),
              child: widget.transaction.bankTransactionID == null
                  ? TextFormField(
                      enabled: widget.transaction.bankTransactionID == null,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      ),
                      style: GoogleFonts.roboto(fontSize: fontSize),
                      initialValue: widget.transaction.store,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (value) {
                        setState(() {
                          widget.transaction.store = value;
                          receipt.recipient = value;
                        });
                      })
                  : Text(
                      widget.transaction.store!,
                      style: GoogleFonts.roboto(fontSize: fontSize),
                    ),
            ),
            Container(
                padding: EdgeInsets.only(top: 10),
                child: Row(children: [
                  isReceipt
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(30, 30),
                              padding: EdgeInsets.zero,
                              backgroundColor: Utils.lightColor,
                              foregroundColor: Utils.darkColor,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Icon(Icons.date_range_rounded),
                          onPressed: () {
                            pickDate();
                          },
                        )
                      : Container(
                          alignment: Alignment.center,
                          width: 30,
                          height: 30,
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.date_range_rounded)),
                  Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        formatter.format(widget.transaction.date),
                        style: GoogleFonts.roboto(fontSize: fontSize),
                      ))
                ])),
            Container(
              child: Row(children: [
                Container(
                    alignment: Alignment.center,
                    width: 30,
                    height: 30,
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.payment_rounded)),
                Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                        NumberFormat.currency(locale: 'sv_SE', decimalDigits: 2)
                            .format(isReceipt
                                ? ((getTotal(receipt)))
                                : widget.transaction.totalAmount),
                        style: GoogleFonts.roboto(fontSize: fontSize))),
              ]),
            ),
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
                child: dropDown(),
              )
            ]),
          ],
        ));
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
    //if (receipt.total != null) return receipt.total;
    double? newTotal = 0;
    for (var item in receipt.items) {
      newTotal = newTotal! + item.amount;
    }
    newTotal = newTotal! * -1;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      receipt.total = newTotal!;
      widget.transaction.totalAmount = newTotal;
    });
    return newTotal;
  }

  pickDate() async {
    DateTime startDate = receipt.date;
    DateTime? date = await showDatePicker(
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Utils.mediumDarkColor, // header background color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  primary: Utils.mediumDarkColor, // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
        context: context,
        initialDate: startDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (date != null) {
      setState(() {
        receipt.date = date;
        widget.transaction.date = date;
      });
    }
  }

  Widget buildDataTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: receipt.items.length,
      itemBuilder: (BuildContext context, index) {
        return Dismissible(
            direction: widget.transaction.bankTransactionID == null
                ? DismissDirection.endToStart
                : DismissDirection.none,
            key: UniqueKey(),
            onDismissed: ((direction) {
              setState(() {
                receipt.total = receipt.total! - receipt.items[index].amount;
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
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Flexible(
                    flex: 9,
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
                      enabled: widget.transaction.bankTransactionID == null,
                      initialValue: receipt.items[index].amount.toString(),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (value) {
                        double oldAmount = receipt.items[index].amount;
                        setState(() {
                          double.tryParse(value) == null
                              ? receipt.items[index].amount = 0
                              : receipt.items[index].amount = double.parse(
                                  double.parse(value).toStringAsFixed(2));
                          receipt.total = receipt.total! - oldAmount;
                          receipt.total = receipt.total! + double.parse(value);
                          receipt.total =
                              double.parse((receipt.total)!.toStringAsFixed(2));
                        });
                      },
                    ),
                  )
                ],
              ),
            ));
      },
    );
  }

  Future<List<TransactionCategory>> getCategories(UnifiedDb dbConnector) async {
    return await dbConnector.getAllcategories();
  }

  Future<Receipt> getReceipt(UnifiedDb dbConnector, int id) async {
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
                heightFactor: 1.5,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteAlertDialog();
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

  deleteAlertDialog() {
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
    Widget continueButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Text("Yes"),
      onPressed: () async {
        await dbConnector.deleteReceipt(widget.transaction.receiptID!);
        if (widget.transaction.bankTransactionID == null) {
          await dbConnector.deleteTransaction(widget.transaction.id!);
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          setState(() {
            widget.transaction.receiptID = null;
            receiptFutureBuilder = null;
          });
          await dbConnector.updateTransaction(widget.transaction);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailsScreen(null, widget.transaction)));
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete receipt"),
      content: Text(
          """Are you sure you want to delete the receipt? This action cannot be undone.
          \nCorresponding bank transaction will not be removed if it exists."""),
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
