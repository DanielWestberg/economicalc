import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const List<String> dropdownList = <String>['Table', 'Chart'];

class StatisticsScreen extends StatefulWidget {
  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  int? sortColumnIndex;
  bool isAscending = false;
  double fontSize = 14;
  double sizedBoxWidth = 140;
  double sizedBoxHeight = 30;
  Map<String, dynamic> startDate = {
    "selected": DateTime(2022, 01, 01),
    "previous": DateTime(2022, 01, 01),
    "dialog": DateTime(2022, 01, 01),
  };

  Map<String, dynamic> endDate = {
    "selected": DateTime(2022, 12, 31),
    "previous": DateTime(2022, 12, 31),
    "dialog": DateTime(2022, 12, 31),
  };

  Map<String, dynamic> category = {
    "selected": Category(description: "None", color: Colors.black, id: 0),
    "previous": Category(description: "None", color: Colors.black, id: 0),
    "dialog": Category(description: "None", color: Colors.black, id: 0),
  };

  Category noneCategory =
      Category(description: "None", color: Colors.black, id: 0);
  String dropdownValue = dropdownList.first;
  String dropdownValueCategory = 'None';

  final SQFLite dbConnector = SQFLite.instance;
  late List<Category> categories;
  late Future<List<Category>> categoriesFutureBuilder;

  final columns = ["Items", "Sum"];
  late Future<List<ReceiptItem>> dataFuture;
  List<ReceiptItem> rows = [];

  @override
  void initState() {
    super.initState();
    categoriesFutureBuilder = dbConnector.getAllcategories();

    dataFuture = dbConnector.getFilteredReceiptItems(
        startDate['selected'], endDate['selected'], category['selected'].id);
  }

  updateData() async {
    var updatedDataFuture = dbConnector.getFilteredReceiptItems(
        startDate['selected'], endDate['selected'], category['selected'].id);

    // Category? cat = noneCategory;
    // if (categoryID['selected'] != 0) {
    //   cat = await dbConnector.getCategoryFromID(categoryID['selected']);
    // }

    setState(() {
      dataFuture = updatedDataFuture;
      // selectedCategory = cat!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 180,
              backgroundColor: Utils.backgroundColor,
              foregroundColor: Colors.black,
              title: Column(children: [
                const Text("Statistics",
                    style: TextStyle(
                        color: Color(0xff000000),
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0)),
                headerInfo(context)
              ]),
              leading: IconButton(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(left: 10, top: 50),
                  onPressed: (() {
                    Navigator.pop(context);
                  }),
                  icon: Icon(Icons.arrow_back)),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(right: 20, top: 50),
                  onPressed: () {
                    startDate['previous'] =
                        startDate['dialog'] = startDate['selected'];
                    endDate['previous'] =
                        endDate['dialog'] = endDate['selected'];
                    category['previous'] =
                        category['dialog'] = category['selected'];
                    dropdownValueCategory = category['selected'].description;
                    showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(builder: (context, setState) {
                            return filterPopup(context, setState);
                          });
                        });
                  },
                )
              ],
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

  Widget headerInfo(context) {
    return Container(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.date_range),
                  Container(
                    padding: EdgeInsets.only(left: 5),
                    child: Flexible(
                        child: Text(
                      "${DateFormat('yyyy/MM/dd').format(startDate['selected'])}-${DateFormat('yyyy/MM/dd').format(endDate['selected'])}",
                      style: TextStyle(fontSize: 12),
                    )),
                  ),
                ]),
                Row(
                  children: [
                    Icon(Icons.category),
                    Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(category['selected'].description,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: category['selected'].color))),
                  ],
                ),
              ],
            )),
            Padding(padding: EdgeInsets.only(right: 20), child: dropDown()),
          ],
        ));
  }

  Widget filterPopup(context, setState) {
    return AlertDialog(
      title: Text("Filter"),
      content: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Text("Start date:"),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.black12),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(startDate['dialog'])),
              onPressed: () async {
                DateTime? newStartDate = await showDatePicker(
                    context: context,
                    initialDate: startDate['dialog'],
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100));
                setState(() {
                  startDate['dialog'] = newStartDate ?? startDate['dialog'];
                });
              },
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("End date:"),
              TextButton(
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.black),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.black12),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(endDate['dialog'])),
                onPressed: () async {
                  DateTime? newEndDate = await showDatePicker(
                      context: context,
                      initialDate: endDate['dialog'],
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100));
                  setState(() {
                    endDate['dialog'] = newEndDate ?? endDate['dialog'];
                  });
                },
              ),
            ],
          ),
          Container(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("Category:"),
                  dropDownCategory(context, setState),
                ],
              ))
        ],
      ),
      actions: [
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Utils.backgroundColor)),
          child: const Text('Apply'),
          onPressed: () async {
            setState(() {
              category['selected'] = category['dialog'];
              startDate['selected'] = startDate['dialog'];
              endDate['selected'] = endDate['dialog'];
            });
            await updateData();
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Utils.backgroundColor)),
          child: const Text('Cancel'),
          onPressed: () async {
            setState(() {
              category['selected'] = category['previous'];
              startDate['selected'] = startDate['previous'];
              endDate['selected'] = endDate['previous'];
            });
            await updateData();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget dropDown() {
    return DropdownButton<String>(
      value: dropdownValue,
      elevation: 16,
      underline: Container(
        height: 2,
        color: Colors.black,
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

  Widget dropDownCategory(context, setState) {
    return FutureBuilder(
        future: categoriesFutureBuilder,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            categories = snapshot.data!;
            if (!categories.contains(noneCategory)) {
              categories.insert(0, noneCategory);
            }
            return SizedBox(
                width: 130,
                height: 30,
                child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: dropdownValueCategory,
                    onChanged: (value) {
                      Category newCategory =
                          Category.getCategoryByDesc(value!, categories);
                      setState(() {
                        dropdownValueCategory = value;
                        category['dialog'] = newCategory;
                      });
                    },
                    items: categories
                        .map<DropdownMenuItem<String>>((Category category) {
                      return DropdownMenuItem<String>(
                        value: category.description,
                        child: Text(category.description,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: category.color)),
                      );
                    }).toList()));
          } else {
            return Text("Unexpected error");
          }
        });
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
        final cells = [item.itemName, item.amount];
        return DataRow(cells: getCells(cells));
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) =>
      cells.map((data) => DataCell(Text('$data'))).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      rows.sort((row1, row2) =>
          Utils.compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      rows.sort((row1, row2) =>
          Utils.compareNumber(ascending, row1.amount, row2.amount));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  double getMaxSum(List<ReceiptItem> items) {
    var max = items.first;
    items.forEach((e) {
      if (e.amount > max.amount) {
        max = e;
      }
    });
    return max.amount.toDouble();
  }

  @override
  Widget itemsChart() {
    return FutureBuilder(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            rows = snapshot.data!;
            rows.sort((a, b) => Utils.compareNumber(true, a.amount, b.amount));
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
                          yValueMapper: (ReceiptItem rows, _) => rows.amount,
                          name: '',
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                          color: Color.fromARGB(255, 68, 104, 107))
                    ]));
          } else {
            return Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                    color: Colors.black, size: 40));
          }
        });
  }
}
