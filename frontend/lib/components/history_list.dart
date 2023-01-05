import 'dart:convert';

import 'package:dart_numerics/dart_numerics.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/screens/transaction_details_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HistoryList extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final TransactionCategory category;
  final bool onlyReceipts;

  HistoryList(
      Key? key, this.startDate, this.endDate, this.category, this.onlyReceipts)
      : super(key: key);

  @override
  HistoryListState createState() => HistoryListState();
}

class HistoryListState extends State<HistoryList> {
  late Future<List<Transaction>> dataFuture;
  late List<Transaction> transactions = [];
  late List<Transaction> transactions_copy;
  bool initialized = false;
  bool isLoading = false;
  final SQFLite dbConnector = SQFLite.instance;

  late List<TransactionCategory> categories = [];

  @override
  void didUpdateWidget(covariant HistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    dataFuture = dbConnector.getFilteredTransactions(
        widget.startDate, widget.endDate, widget.category, widget.onlyReceipts);
  }

  @override
  void initState() {
    super.initState();
    initDB();
    updateData();
    dataFuture = dbConnector.getFilteredTransactions(
        widget.startDate, widget.endDate, widget.category, widget.onlyReceipts);
    print(dataFuture);
  }

  void initDB() async {
    await dbConnector.initDatabase();
  }

  void search(String query) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      List<Transaction> dummySearchList = <Transaction>[];
      dummySearchList.addAll(transactions_copy);
      if (query.isNotEmpty) {
        List<Transaction> dummyListData = <Transaction>[];
        dummySearchList.forEach((item) {
          if (item.store!.toLowerCase().contains(query.toLowerCase())) {
            dummyListData.add(item);
          }
        });
        setState(() {
          transactions.clear();
          transactions.addAll(dummyListData);
        });
        return;
      } else {
        setState(() {
          transactions.clear();
          transactions.addAll(transactions_copy);
        });
      }
    });
  }

  void updateData() async {
    setState(() {
      isLoading = true;
    });
    categories = await dbConnector.getAllcategories();
    var updatedDataFuture = dbConnector.getFilteredTransactions(
        widget.startDate, widget.endDate, widget.category, widget.onlyReceipts);
    setState(() {
      dataFuture = updatedDataFuture;
      isLoading = false;
    });
  }

  load_test_data() async {
    final String jsondata =
        await rootBundle.loadString('assets/test_data.json');

    final data = await json.decode(jsondata);

    final List<BankTransaction> testTransactions = [];
    BankTransaction trans = BankTransaction.fromJson(data["transactions"][0]);
    data["transactions"].forEach((transaction) {
      testTransactions.add(BankTransaction.fromJson(transaction));
    });

    for (var transaction in testTransactions) {
      await dbConnector.postBankTransaction(transaction);
    }
  }

  void sortByDate() {
    transactions.sort((t1, t2) => t2.date.compareTo(t1.date));
    transactions_copy.sort((t1, t2) => t2.date.compareTo(t1.date));
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('sv_SE');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          color: Utils.lightColor,
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "History",
                style: TextStyle(color: Utils.textColor, fontSize: 32),
              ),
              Flexible(
                  child: Text(
                "${DateFormat.yMMMd('sv_SE').format(widget.startDate)} - ${DateFormat.yMMMd('sv_SE').format(widget.endDate)}",
                style: TextStyle(color: Utils.textColor, fontSize: 18),
              )),
            ],
          )),
      isLoading
          ? Center(
              heightFactor: 10,
              child: LoadingAnimationWidget.threeArchedCircle(
                  color: Colors.black, size: 40))
          : FutureBuilder(
              future: dataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else if (snapshot.hasData) {
                  transactions = snapshot.data!;
                  if (!initialized) {
                    transactions_copy = snapshot.data!;
                  }
                  initialized = true;
                  sortByDate();
                  return Expanded(
                      child: RefreshIndicator(
                          onRefresh: () async => updateData(),
                          backgroundColor: Utils.mediumLightColor,
                          color: Utils.textColor,
                          child: ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (BuildContext ctx, int index) {
                                print(transactions[index].receiptID == null);
                                if (transactions[index].receiptID == null) {
                                  print("INSIDE NYLL RECEIPT ID");
                                  return DragTarget<int>(builder: (context,
                                      List<int?> candidateData, rejectedData) {
                                    return buildListItem(
                                        context, transactions[index]);
                                  }, onAccept: (data) {
                                    updateTransaction(data, index, 1);
                                  }, onWillAccept: (data) {
                                    return true;
                                    /*print("Accepted!!");
                                      if (almostEqualNumbersBetween(
                                              transactions[data!].totalAmount!,
                                              transactions[index].totalAmount!,
                                              1) ==
                                          false) {
                                        print("Firstcase");
                                        final snackbar = SnackBar(
                                          backgroundColor: Utils.errorColor,
                                          content: Text(
                                            "Total amount of scanned receipt and existing transaction don't match. Please scan the correct receipt or edit the results. Amount on transaction: ${transactions[index].totalAmount}",
                                            style: GoogleFonts.roboto(),
                                          ),
                                        );
                                        return false;
                                      } else {
                                        print("ELSE");
                                        askMergeQuestions(data, index);

                                        return true;
                                      }
                                    },*/
                                  });
                                } else {
                                  if (transactions[index].bankTransactionID ==
                                      null) {
                                    print("Draggable");

                                    return Draggable<int>(
                                        data: index,
                                        feedback: Material(
                                          child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width),
                                              child: Opacity(
                                                  opacity: 0.4,
                                                  child: buildListItem(context,
                                                      transactions[index]))),
                                        ),
                                        childWhenDragging: Container(
                                          foregroundDecoration:
                                              const BoxDecoration(
                                            color: Colors.grey,
                                            backgroundBlendMode:
                                                BlendMode.saturation,
                                          ),
                                          child: buildListItem(
                                              context, transactions[index]),
                                        ),
                                        child: dissmiss(context, index));
                                  }

                                  return dissmiss(context, index);
                                }
                              })));
                } else {
                  return Center(
                      heightFactor: 10,
                      child: LoadingAnimationWidget.threeArchedCircle(
                          color: Colors.black, size: 40));
                }
              })
    ]);
  }

  AlertDialog askMergeQuestions(data, index) {
    return AlertDialog(
      title: const Text('Merge transactions?'),
      content: Text(
          "Do you want to merge ${transactions[data].store} with ${transactions[index].store}?"),
      actions: <Widget>[
        TextButton(
          onPressed: () {},
          child: const Text("Cancel"),
        ),
        TextButton(
            onPressed: () {
              AlertDialog(
                title: const Text("Keep category?"),
                content: Text(
                    "Do you want to keep category: ${transactions[data].categoryDesc} or use: ${transactions[index].categoryDesc}?"),
                actions: <Widget>[
                  TextButton(
                    child: const Text("Keep"),
                    onPressed: () {
                      updateTransaction(data, index, 2);
                    },
                  ),
                  TextButton(
                      onPressed: () {
                        updateTransaction(data, index, 1);
                      },
                      child: const Text("Switch"))
                ],
              );
            },
            child: const Text("OK"))
      ],
    );
  }

  updateTransaction(int data, int index, int catToBeUsed) {
    Transaction receiptToMerge = transactions[data];
    if (catToBeUsed == 1) {
      transactions[index].categoryDesc = receiptToMerge.categoryDesc;
      transactions[index].categoryID = receiptToMerge.categoryID;
    }
    transactions[index].receiptID = receiptToMerge.receiptID;
    setState(() {
      dbConnector.deleteTransaction(receiptToMerge.id!);
      dbConnector.updateTransaction(transactions[index]);
    });
  }

  Dismissible dissmiss(BuildContext context, int index) {
    return Dismissible(
        direction: DismissDirection.endToStart,
        key: UniqueKey(),
        onDismissed: ((direction) {
          setState(() {
            if (transactions[index].bankTransactionID == null) {
              dbConnector.deleteTransaction(transactions[index].id!);
              dbConnector.deleteReceipt(transactions[index].receiptID!);
              transactions.removeAt(index);
            } else {
              int id = transactions[index].receiptID!;
              transactions[index].receiptID = null;
              dbConnector.updateTransaction(transactions[index]);
              dbConnector.deleteReceipt(id);
            }
          });
        }),
        background: Container(
          color: Colors.green,
        ),
        // ignore: unnecessary_null_comparison
        secondaryBackground: transactions[index].bankTransactionID != null
            ? buildListItem(context, transactions[index])
            : redTrash(),
        child: buildListItem(context, transactions[index]));
  }

  ColoredBox redTrash() {
    return const ColoredBox(
      color: Colors.red,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
    );
  }

  Widget buildListItem(BuildContext context, Transaction transaction) {
    return Padding(
        padding: EdgeInsets.only(top: 0.0),
        child: ListTile(
          style: ListTileStyle.list,
          shape: Border(
            left: BorderSide(
                color: TransactionCategory.getCategory(
                        transaction.categoryID!, categories)
                    .color,
                width: 20),
            top: BorderSide(color: Utils.mediumDarkColor, width: 0.5),
          ),
          leading: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  DateFormat('yyyy-MM-dd').format(transaction.date),
                  style: TextStyle(
                      color: Utils.textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
                transaction.receiptID != null
                    ? Icon(
                        Icons.receipt_long_rounded,
                        size: 15,
                      )
                    : Text("")
              ]),
          title: Text(
            transaction.store!,
            style: TextStyle(
                color: Utils.textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14),
          ),
          subtitle: Text(
            NumberFormat.currency(
              locale: 'sv_SE',
            ).format(transaction.totalAmount),
            style: TextStyle(
                color: Utils.textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12),
          ),
          trailing: Icon(
            Icons.arrow_right_rounded,
            size: 40,
            color: Utils.textColor,
          ),
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) =>
                        TransactionDetailsScreen(null, transaction)))
                .then((value) {
              updateData();
            });
          },
        ));
  }
}
