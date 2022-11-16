import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/screens/transaction_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryList extends StatelessWidget {
  HistoryList({
    Key? key,
  }) : super(key: key);

  final transactions = Utils.getMockedTransactions(); // TODO: fetch from db

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.only(left: 20),
        child: Text(
          "History",
          textAlign: TextAlign.left,
          style: TextStyle(
              color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      Expanded(
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
                            fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      subtitle: Text(
                        transactions[index].amount.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      leading: Text(
                        DateFormat('yyyy-MM-dd')
                            .format(transactions[index].date),
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
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
                                    TransactionDetailsScreen())));
                      },
                    ));
              }))
    ]);
  }
}
