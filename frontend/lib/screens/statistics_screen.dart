import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/transaction_event.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const List<String> dropdownList = <String>['Table', 'Chart'];

class StatisticsScreen extends StatefulWidget {
  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;
  DateTime startDate = DateTime(2022, 01, 01);
  DateTime endDate = DateTime(2022, 12, 31);
  String dropdownValue = dropdownList.first;

  final columns = ["Items", "Price", "Qty", "Sum"];
  late Future<List<ReceiptItem>> dataFuture;
  List<ReceiptItem> rows = [];

  @override
  void initState() {
    super.initState();
    dataFuture = fetchMockedReceiptItemsBetweenDates(startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 180,
              backgroundColor: Color(0xFFB8D8D8),
              foregroundColor: Colors.black,
              title: Column(children: [
                const Text("EconomiCalc",
                    style: TextStyle(
                        color: Color(0xff000000),
                        fontWeight: FontWeight.bold,
                        fontSize: 36.0)),
                headerInfo()
              ]),
              centerTitle: true,
              elevation: 0,
            ),
            body: displayStats(dropdownValue)));
  }

  Widget displayStats(String dropdownValue) {
    if (dropdownValue == "Table") {
      return ListView(children: [buildDataTable()]);
    } else if (dropdownValue == "Chart") {
      return itemsChart();
    }
    return Text("Invalid input");
  }

  Widget headerInfo() {
    return Container(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: EdgeInsets.only(right: 20), child: dropDown()),
            Padding(
                padding: EdgeInsets.only(left: 20),
                child: Column(
                  children: [
                    Row(children: [
                      Text("Start:"),
                      TextButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black12),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                        onPressed: () async {
                          DateTime? newStartDate = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100));
                          if (newStartDate == null) return;
                          setState(() {
                            startDate = newStartDate;
                            dataFuture = fetchMockedReceiptItemsBetweenDates(
                                startDate, endDate);
                          });
                        },
                      )
                    ]),
                    Row(children: [
                      Text("End:"),
                      TextButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black12),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                        onPressed: () async {
                          DateTime? newEndDate = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100));
                          if (newEndDate == null) return;
                          setState(() {
                            endDate = newEndDate;
                            dataFuture = fetchMockedReceiptItemsBetweenDates(
                                startDate, endDate);
                          });
                        },
                      )
                    ])
                  ],
                ))
          ],
        ));
  }

  Widget dropDown() {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      underline: Container(
        height: 2,
        color: Colors.black45,
      ),
      onChanged: (String? value) {
        setState(() {
          dropdownValue = value!;
        });
      },
      items: dropdownList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget buildDataTable() {
    return FutureBuilder(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            rows = snapshot.data!;
            return DataTable(
                columnSpacing: 30,
                sortAscending: isAscending,
                sortColumnIndex: sortColumnIndex,
                columns: getColumns(columns),
                rows: getRows(rows));
          } else {
            return Text('Waiting....');
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
        final cells = [
          item.itemName,
          item.priceStr,
          item.quantity,
          item.sumStr
        ];
        return DataRow(cells: getCells(cells));
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) =>
      cells.map((data) => DataCell(Text('$data'))).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      rows.sort((row1, row2) =>
          compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      rows.sort((row1, row2) =>
          compareString(ascending, row1.priceStr, row2.priceStr));
    } else if (columnIndex == 2) {
      rows.sort((row1, row2) =>
          compareNumber(ascending, row1.quantity, row2.quantity));
    } else if (columnIndex == 3) {
      rows.sort(
          (row1, row2) => compareString(ascending, row1.sumStr, row2.sumStr));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  double getMaxSum(List<ReceiptItem> items) {
    var max = items.first;
    items.forEach((e) {
      if (e.sumKr > max.sumKr) {
        max = e;
      }
    });
    return (max.sumKr + max.sumOre.toDouble() / 100);
  }

  @override
  Widget itemsChart() {
    rows.sort((a, b) => compareNumber(true, a.sumKr, b.sumKr));
    return Container(
        padding: EdgeInsets.all(5),
        child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: getMaxSum(rows),
                interval: 100,
                visibleMinimum: 0,
                decimalPlaces: 2),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <ChartSeries<ReceiptItem, String>>[
              BarSeries<ReceiptItem, String>(
                  dataSource: rows,
                  xValueMapper: (ReceiptItem rows, _) => rows.itemName,
                  yValueMapper: (ReceiptItem rows, _) => rows.sumKr,
                  name: '',
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                  color: Color.fromARGB(255, 68, 104, 107))
            ]));
  }
}
