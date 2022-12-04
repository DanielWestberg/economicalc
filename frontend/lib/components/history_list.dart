import 'dart:convert';
import 'dart:developer';

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
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HistoryList extends StatefulWidget {
  HistoryList({Key? key}) : super(key: key);
  @override
  HistoryListState createState() => HistoryListState();
}

class HistoryListState extends State<HistoryList> {
  late Future<List<Transaction>> dataFuture;
  late List<Transaction> transactions = [];
  late List<Transaction> transactions_copy;
  bool initialized = false;
  final SQFLite dbConnector = SQFLite.instance;

  late List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    initDB();
    fetchBankTransactions();
    dataFuture = dbConnector.getAllTransactions();
  }

  void initDB() async {
    await dbConnector.initDatabase();
  }

  void search(String query) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      List<Transaction> dummySearchList = <Transaction>[];
      dummySearchList.addAll(transactions);
      if (query.isNotEmpty) {
        List<Transaction> dummyListData = <Transaction>[];
        dummySearchList.forEach((item) {
          print(item.store);
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
          print(transactions_copy);
          transactions.clear();
          transactions.addAll(transactions_copy);
        });
      }
    });
  }

  void fetchBankTransactions() async {
    categories = await dbConnector.getAllcategories();
    await load_test_data(); // TODO: Replace with fetching from bank
    await dbConnector.importMissingBankTransactions();
    setState(() {
      dataFuture = dbConnector.getAllTransactions();
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        color: Utils.backgroundColor,
        padding: const EdgeInsets.all(20),
        child: Text(
          "History",
          textAlign: TextAlign.left,
          style: TextStyle(
              color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      FutureBuilder(
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
                      onRefresh: () async => fetchBankTransactions(),
                      backgroundColor: Color(0xFFB8D8D8),
                      color: Colors.black,
                      child: ListView.builder(
                          padding: EdgeInsets.all(20.0),
                          itemCount: transactions.length,
                          itemBuilder: (BuildContext ctx, int index) {
                            return Padding(
                                padding: EdgeInsets.only(top: 5.0),
                                child: ListTile(
                                  tileColor: Color(0xffD4E6F3),
                                  shape: ContinuousRectangleBorder(
                                      side: BorderSide(
                                    width: 1.0,
                                    color: Colors.transparent,
                                  )),
                                  title: Text(
                                    transactions[index].store!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    "${transactions[index].totalAmount} kr",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                  leading: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          DateFormat('yyyy-MM-dd')
                                              .format(transactions[index].date),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                        Icon(
                                          Icons.category,
                                          color: Category.getCategory(
                                                  transactions[index]
                                                      .categoryID!,
                                                  categories)
                                              .color,
                                        )
                                      ]),
                                  trailing: const Icon(
                                    Icons.arrow_right_alt_sharp,
                                    size: 50,
                                  ),
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (context) =>
                                                TransactionDetailsScreen(
                                                    null, transactions[index])))
                                        .then((value) {
                                      Phoenix.rebirth(context);
                                    });
                                  },
                                ));
                          })));
            } else {
              return Center(
                  child: LoadingAnimationWidget.threeArchedCircle(
                      color: Colors.black, size: 40));
            }
          })
    ]);
  }
}
