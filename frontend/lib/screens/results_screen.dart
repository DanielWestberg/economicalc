import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:economicalc_client/helpers/quota_exception.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';

import 'package:flutter/gestures.dart';

import 'package:economicalc_client/services/api_calls.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:month_year_picker/month_year_picker.dart';
import '../services/api_calls.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart';

class ResultsScreen extends StatefulWidget {
  final XFile? image;
  Transaction? existingTransaction;

  ResultsScreen({super.key, required this.image, this.existingTransaction});

  @override
  ResultsScreenState createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  static UniqueKey futurekey = UniqueKey();
  int? sortColumnIndex;
  bool isAscending = false;
  double fontSize = 16;
  double sizedBoxWidth = 150;
  double sizedBoxHeight = 30;
  final columns = ["Items", "Total"];
  bool isLoading = false;
  late Future<Receipt> dataFuture;
  late Receipt receipt;
  late Future<List<TransactionCategory>> categoriesFutureBuilder;
  late List<TransactionCategory> categories;
  final dbConnector = SQFLite.instance;
  final apiCaller = ApiCaller();
  int? categoryID;
  String dropdownValue =
      "Uncategorized"; // TODO: replace with suggested category
  int backupTotal = 0;

  final DateFormat formatter = DateFormat('yyyy-MM-dd');
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
                  foregroundColor: Utils.textColor,
                  title: Text(
                    'Scan result',
                    style: GoogleFonts.roboto(),
                  ),
                  centerTitle: true,
                  elevation: 10,
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
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 250,
        child: Container(
            child: Stack(fit: StackFit.expand, children: [
          Image.file(File(widget.image!.path), fit: BoxFit.cover),
          BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
              )),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 130, vertical: 100),
            child: TextButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Utils.mediumLightColor)),
              onPressed: () {
                showImageViewer(context, FileImage(File(widget.image!.path)));
              },
              child: Text(
                "View receipt",
                style: GoogleFonts.roboto(color: Utils.textColor),
              ),
            ),
          )
        ])));
  }

  Widget confirmButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: ElevatedButton(
          style: ButtonStyle(
              shape: MaterialStateProperty.all(
                CircleBorder(),
              ),
              backgroundColor:
                  MaterialStateProperty.all<Color>(Utils.mediumLightColor),
              foregroundColor:
                  MaterialStateProperty.all<Color>(Utils.textColor)),
          onPressed: () async {
            int receiptID =
                await dbConnector.insertReceipt(receipt, dropdownValue);
            if (apiCaller.cookie != null) {
              await apiCaller.postReceipt(receipt);
              await apiCaller.updateImage(receiptID, widget.image!);
            }
            if (widget.existingTransaction != null) {
              if (widget.existingTransaction!.totalAmount != receipt.total) {
                final snackBar = SnackBar(
                  backgroundColor: Utils.errorColor,
                  content: Text(
                    "Total amount of scanned receipt and existing transaction don't match. Please scan the correct receipt or edit the results.",
                    style: GoogleFonts.roboto(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } else {
                widget.existingTransaction!.receiptID = receiptID;
                widget.existingTransaction!.categoryDesc = receipt.categoryDesc;
                widget.existingTransaction!.categoryID = receipt.categoryID;
                await dbConnector
                    .updateTransaction(widget.existingTransaction!);
                Navigator.pop(context);
                final snackBar = SnackBar(
                  backgroundColor: Utils.darkColor,
                  content: Text(
                    "Receipt was successfully attached to transaction.",
                    style: GoogleFonts.roboto(color: Utils.lightColor),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            } else {
              Transaction transaction = Transaction(
                date: receipt.date,
                totalAmount: -receipt.total!,
                store: receipt.recipient,
                receiptID: receiptID,
                categoryID: await dbConnector
                    .getCategoryIDfromDescription(dropdownValue),
                categoryDesc: dropdownValue,
              );
              Transaction? alreadyExists =
                  await dbConnector.checkForExistingTransaction(transaction);
              if (alreadyExists != null) {
                await showMergeTransactionDialog(
                    context, alreadyExists, transaction);
              } else {
                await dbConnector.insertTransaction(transaction);
              }
              int? n =
                  await dbConnector.numOfCategoriesWithSameName(transaction);
              if (n > 0) {
                await showAlertDialog(context, n, transaction);
              }
              showConfirmationButton(context);
            }
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.check)])),
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
                width: 300,
                child: DropdownButton<String>(
                    dropdownColor: Utils.lightColor,
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
                                style: GoogleFonts.roboto(fontSize: fontSize),
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
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Center(child: Text("Ok")),
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

  showAlertDialog(BuildContext context, int n, transaction) async {
    // set up the buttons
    Widget cancelButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Text("No"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
    Widget continueButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Text("Yes"),
      onPressed: () async {
        await dbConnector.assignCategories(transaction);
        Navigator.of(context, rootNavigator: true).pop('dialog');
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
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showMergeTransactionDialog(BuildContext context, Transaction alreadyExists,
      Transaction transaction) async {
    // set up the buttons
    Widget cancelButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Text("No"),
      onPressed: () async {
        await dbConnector.insertTransaction(transaction);
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
    Widget continueButton = TextButton(
      style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(Utils.mediumDarkColor)),
      child: Text("Yes"),
      onPressed: () async {
        alreadyExists.receiptID = transaction.receiptID;
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
        Navigator.of(context, rootNavigator: true).pop('dialog');
        // showConfirmationButton(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("An existing bank transaction for this receipt was found."),
      content: Text(
          "Would you like to attach this receipt to that bank transaction?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    await showDialog(
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
                padding: EdgeInsets.only(top: 20, left: 20, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  child: TextFormField(
                                      initialValue: receipt.recipient,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          receipt.recipient = value;
                                        });
                                      }),
                                ))
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.date_range),
                            RichText(
                                text: TextSpan(
                                    style:
                                        GoogleFonts.roboto(fontSize: fontSize),
                                    children: <TextSpan>[
                                  TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    text: "${formatter.format(receipt.date)}",
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => pickDate(),
                                  )
                                ])),
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
/*
                    Container(
                        child: Text(
                      receipt.recipient,
                      style: GoogleFonts.roboto(fontSize: fontSize),
                    )),
                    Container(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          DateFormat("yyyy-MM-dd")
                              .format(receipt.date)
                              .toString(),
                          style: GoogleFonts.roboto(fontSize: fontSize),
                        )),
                    Container(
                        padding: EdgeInsets.only(top: 5, bottom: 10),
                        child: Text(
                            NumberFormat.currency(locale: 'sv_SE')
                                .format(receipt.total),
                            style: GoogleFonts.roboto(fontSize: fontSize))),
                    Container(
                      padding: EdgeInsets.only(top: 15),
                      child: Text(
                        'Set category for transaction:',
                        style: GoogleFonts.roboto(
                            color: Utils.textColor, fontSize: fontSize),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 5, right: 10),
                      child: dropDown(),
                    )
*/
                  ],
                ));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  pickDate() async {
    DateTime startDate = receipt.date;
    DateTime? date = await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (date != null) {
      setState(() {
        receipt.date = date;
      });
    }
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
                  key: futurekey,
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

  Future<Receipt> getTransactionFromImage(image) async {
    final imageFile = File(image.path);
    try {
      var response = await apiCaller.processImageWithAsprise(imageFile);
      Receipt receipt = Receipt.fromJson(response);
      receipt.imagePath = image.path;
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
          style: GoogleFonts.roboto(color: Colors.white),
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
          style: GoogleFonts.roboto(color: Colors.white),
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
    //if (receipt.total != null) return receipt.total;
    double? newTotal = 0;
    for (var item in receipt.items) {
      newTotal = newTotal! + item.amount;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      receipt.total = newTotal;
    });
    return newTotal;
  }
}
