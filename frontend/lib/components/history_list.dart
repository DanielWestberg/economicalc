import 'dart:convert';
import 'dart:developer';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:flutter/services.dart';
import 'package:economicalc_client/helpers/utils.dart';
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
  @override
  HistoryListState createState() => HistoryListState();
}

class HistoryListState extends State<HistoryList> {
  late Future<List<Transaction>> dataFuture;
  late List<Transaction> transactions;
  final SQFLite dbConnector = SQFLite.instance;

  late Future<List<BankTransaction>> bankTransactions;
  late List<Transaction> transactions_bank;

  @override
  void initState() {
    super.initState();
    load_test_data();
    fetchTransactions();
    load_test_data();
  }

  void fetchTransactions() {
    dbConnector.initDatabase();
    dataFuture = dbConnector.getAllTransactions();
    bankTransactions = dbConnector.getBankTransactions();
  }

  void load_test_data() async {
    final String jsondata =
        await rootBundle.loadString('assets/test_data.json');


    final data = await json.decode(jsondata);

    final List<BankTransaction> testTransactions = [];
    BankTransaction trans = BankTransaction.fromJson(data["transactions"][0]);
    data["transactions"].forEach((transaction) {
      testTransactions.add(BankTransaction.fromJson(transaction));
    });

    for (var transaction in testTransactions) {
      dbConnector.postBankTransaction(transaction);
    }
    dbConnector.importMissingBankTransactions();
  }

  void sortByDate() {
    transactions_bank
        .sort((t1, t2) => t2.dates.booked.compareTo(t1.dates.booked));
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
          future: bankTransactions,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("${snapshot.error}");
            } else if (snapshot.hasData) {
              transactions_bank = snapshot.data!;
              sortByDate();
              return Expanded(
                  child: RefreshIndicator(
                      onRefresh: () async => fetchTransactions(),
                      backgroundColor: Color(0xFFB8D8D8),
                      color: Colors.black,
                      child: ListView.builder(
                          padding: EdgeInsets.all(20.0),
                          itemCount: transactions_bank.length,
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
                                  leading: Text(
                                    (transactions_bank[index].dates.booked),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_right_alt_sharp,
                                    size: 50,
                                  ),
                                  onTap: () {
                                    /*Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: ((context) =>
                                                TransactionDetailsScreen(null,
                                                    transactions[index]))));*/
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
