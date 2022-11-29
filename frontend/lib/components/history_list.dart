import 'dart:convert';
import 'dart:developer';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:economicalc_client/screens/transaction_details_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HistoryList extends StatefulWidget {
  @override
  HistoryListState createState() => HistoryListState();
}

class HistoryListState extends State<HistoryList> {
  late Future<List<Receipt>> dataFuture;
  //late List<Receipt> transactions;
  final SQFLite dbConnector = SQFLite.instance;

  late Future<List<Transaction>> bankTransactions;
  late List<Transaction> transactions_bank;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
    load_test_data();
  }

  void fetchTransactions() {
    dbConnector.initDatabase();
    dataFuture = dbConnector.transactions();
    bankTransactions = dbConnector.getBankTransactions();

    print(bankTransactions);
  }

  void load_test_data() async {
    final String jsondata =
        await rootBundle.loadString('assets/test_data.json');

    final data = await json.decode(await jsondata);

    final List<Transaction> testTransactions = [];
    print("DATASTASTA");
    print(data["transactions"][1]);
    Transaction trans = Transaction.fromJson(data["transactions"][0]);
    print("TRANS");
    print(trans);
    data["transactions"].forEach((transaction) {
      testTransactions.add(Transaction.fromJson(transaction));
    });

    print(testTransactions);
    for (var transaction in testTransactions) {
      dbConnector.postBankTransaction(transaction);
    }
  }

  void sortByDate() {
    transactions_bank
        .sort((t1, t2) => t2.dates.booked.compareTo(t1.dates.booked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        color: Color(0xFFB8D8D8),
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
                      onRefresh: () => fetchMockedTransactions(),
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
                                    transactions_bank[index]
                                        .descriptions
                                        .display,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    "${NumberFormat("##0.##", "sv_SE").format(double.parse(transactions_bank[index].amount.value.unscaledValue) / 10)} kr",
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
                      color: Colors.black, size: 20));
            }
          })
    ]);
  }
}
