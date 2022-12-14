import 'dart:convert';

import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/screens/transaction_details_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HistoryList extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Category category;

  HistoryList(Key? key, this.startDate, this.endDate, this.category)
      : super(key: key);

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
  void didUpdateWidget(covariant HistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    dataFuture = dbConnector.getFilteredTransactions(
        widget.startDate, widget.endDate, widget.category);
  }

  @override
  void initState() {
    super.initState();
    initDB();
    fetchBankTransactions();
    dataFuture = dbConnector.getFilteredTransactions(
        widget.startDate, widget.endDate, widget.category);
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
          print(transactions_copy);
          transactions.clear();
          transactions.addAll(transactions_copy);
        });
      }
    });
  }

  void fetchBankTransactions() async {
    categories = await dbConnector.getAllcategories();
    // await load_test_data(); // TODO: Replace with fetching from bank
    await dbConnector.importMissingBankTransactions();
    var updatedDataFuture = dbConnector.getFilteredTransactions(
        widget.startDate, widget.endDate, widget.category);
    setState(() {
      dataFuture = updatedDataFuture;
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
                      backgroundColor: Utils.mediumLightColor,
                      color: Utils.textColor,
                      child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (BuildContext ctx, int index) {
                            return Padding(
                                padding: EdgeInsets.only(top: 0.0),
                                child: ListTile(
                                  style: ListTileStyle.list,
                                  shape: Border(
                                    left: BorderSide(
                                        color: Category.getCategory(
                                                transactions[index].categoryID!,
                                                categories)
                                            .color,
                                        width: 6),
                                    top: BorderSide(
                                        color: Utils.mediumDarkColor,
                                        width: 0.5),
                                  ),
                                  title: Text(
                                    transactions[index].store!,
                                    style: TextStyle(
                                        color: Utils.textColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    NumberFormat.currency(
                                      locale: 'sv_SE',
                                    ).format(transactions[index].totalAmount),
                                    style: TextStyle(
                                        color: Utils.textColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12),
                                  ),
                                  leading: Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(transactions[index].date),
                                    style: TextStyle(
                                        color: Utils.textColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
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
                  heightFactor: 10,
                  child: LoadingAnimationWidget.threeArchedCircle(
                      color: Colors.black, size: 40));
            }
          })
    ]);
  }
}
