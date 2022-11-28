import 'dart:developer';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:economicalc_client/screens/transaction_details_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HistoryList extends StatefulWidget {
  @override
  HistoryListState createState() => HistoryListState();
}

class HistoryListState extends State<HistoryList> {
  late Future<List<Receipt>> dataFuture;
  late List<Receipt> transactions;
  final SQFLite dbConnector = SQFLite.instance;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  void fetchTransactions() {
    dbConnector.initDatabase();
    dataFuture = dbConnector.transactions();
  }

  void sortByDate() {
    transactions.sort((t1, t2) => t2.date.compareTo(t1.date));
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
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("${snapshot.error}");
            } else if (snapshot.hasData) {
              transactions = snapshot.data!;
              sortByDate();
              return Expanded(
                  child: RefreshIndicator(
                      onRefresh: () => fetchMockedTransactions(),
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
                                    transactions[index].recipient,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    "${transactions[index].total} kr",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                  leading: Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(transactions[index].date),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_right_alt_sharp,
                                    size: 50,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: ((context) =>
                                                TransactionDetailsScreen(null,
                                                    transactions[index]))));
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
