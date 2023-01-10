import 'package:economicalc_client/components/drawer_menu.dart';
import 'package:economicalc_client/helpers/unified_db.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/screens/home_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:month_year_picker/month_year_picker.dart';

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
    "selected": DateTime(DateTime.now().year - 1, DateTime.now().month, 1),
    "previous": DateTime(DateTime.now().year - 1, DateTime.now().month, 1),
    "dialog": DateTime(DateTime.now().year - 1, DateTime.now().month, 1),
  };

  Map<String, dynamic> endDate = {
    "selected":
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    "previous":
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    "dialog":
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  };

  Map<String, dynamic> category = {
    "selected":
        TransactionCategory(description: "All", color: Colors.black, id: 0),
    "previous":
        TransactionCategory(description: "All", color: Colors.black, id: 0),
    "dialog":
        TransactionCategory(description: "All", color: Colors.black, id: 0),
  };

  TransactionCategory allCategory =
      TransactionCategory(description: "All", color: Colors.black, id: 0);
  Map<String, dynamic> contentSelection = {
    "selected": [true, false],
    "previous": [true, false],
    "dialog": [true, false],
  };

  Map<String, dynamic> expIncSelection = {
    "selected": [true, false],
    "previous": [true, false],
    "dialog": [true, false],
  };

  String dropdownValue = dropdownList.first;
  String dropdownValueCategory = 'All';

  final UnifiedDb dbConnector = UnifiedDb.instance;
  late List<TransactionCategory> categories;
  late Future<List<TransactionCategory>> categoriesFutureBuilder;

  final columns = ["Items", "Sum"];
  late Future<List<Map<String, Object>>> dataFutureItems;
  late Future<List<Map<String, Object>>> dataFutureCategorySums;
  List<ReceiptItem> rowsItemsTable = [];
  List<ItemsChartData> rowsItemsChart = [];
  List<CategoryChartData> rowsTotals = [];

  @override
  void initState() {
    super.initState();
    categoriesFutureBuilder = dbConnector.getAllcategories();

    dataFutureItems = dbConnector.getFilteredReceiptItems(
        startDate['selected'], endDate['selected'], category['selected']);

    dataFutureCategorySums = dbConnector.getFilteredCategoryTotals(
        startDate['selected'],
        endDate['selected'],
        expIncSelection['selected'][0]);
  }

  updateData() async {
    if (contentSelection['selected'][0]) {
      var updatedDataFutureItems = dbConnector.getFilteredReceiptItems(
          startDate['selected'], endDate['selected'], category['selected']);

      setState(() {
        dataFutureItems = updatedDataFutureItems;
      });
    }

    if (contentSelection['selected'][1]) {
      var updatedDataFutureCategorySums = dbConnector.getFilteredCategoryTotals(
          startDate['selected'],
          endDate['selected'],
          expIncSelection['selected'][0]);

      setState(() {
        dataFutureCategorySums = updatedDataFutureCategorySums;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: DefaultTabController(
            length: contentSelection['selected'][0] ? 2 : 1,
            child: Scaffold(
                // drawer: DrawerMenu(1),
                appBar: AppBar(
                  leading: Container(
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.only(top: 10, left: 10),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(0),
                              alignment: Alignment.center,
                              backgroundColor: Utils.lightColor,
                              foregroundColor: Utils.mediumDarkColor),
                          onPressed: (() {
                            Navigator.pop(context);
                          }),
                          child: Icon(Icons.arrow_back))),
                  toolbarHeight: 100,
                  backgroundColor: Utils.mediumLightColor,
                  foregroundColor: Utils.textColor,
                  title: Column(children: [
                    Container(
                        padding: EdgeInsets.all(5),
                        child: Text("Statistics",
                            style: TextStyle(
                                color: Utils.textColor, fontSize: 25.0))),
                    headerInfo(context)
                  ]),
                  centerTitle: true,
                  elevation: 0,
                  actions: [
                    Container(
                        alignment: Alignment.topCenter,
                        padding: EdgeInsets.only(top: 10, right: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(0),
                            alignment: Alignment.center,
                            backgroundColor: Utils.lightColor,
                            foregroundColor: Utils.mediumDarkColor,
                          ),
                          child: Icon(Icons.filter_alt),
                          onPressed: () {
                            startDate['previous'] =
                                startDate['dialog'] = startDate['selected'];
                            endDate['previous'] =
                                endDate['dialog'] = endDate['selected'];
                            category['previous'] =
                                category['dialog'] = category['selected'];
                            dropdownValueCategory =
                                category['selected'].description;
                            contentSelection['previous'] =
                                contentSelection['dialog'] =
                                    contentSelection['selected'];
                            expIncSelection['previous'] =
                                expIncSelection['dialog'] =
                                    expIncSelection['selected'];
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    return filterPopup(context, setState);
                                  });
                                });
                          },
                        )),
                  ],
                  bottom: TabBar(
                    labelColor: Utils.textColor,
                    indicatorColor: Utils.mediumDarkColor,
                    tabs: contentSelection['selected'][0]
                        ? [
                            Tab(
                              text: "Table",
                            ),
                            Tab(
                              text: "Chart",
                            ),
                          ]
                        : [
                            Tab(
                              text: "Chart",
                            ),
                          ],
                  ),
                ),
                body: contentSelection['selected'][0]
                    ? TabBarView(children: [
                        ListView(children: [buildDataTable()]),
                        itemsChart(),
                      ])
                    : TabBarView(children: [
                        totalsChart(),
                      ]))));
  }

  Widget headerInfo(context) {
    return Container(
        child: Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.date_range),
            Container(
              padding: EdgeInsets.only(left: 5),
              child: Flexible(
                  child: Text(
                "${DateFormat.yMMMd('sv_SE').format(startDate['selected'])} - ${DateFormat.yMMMd('sv_SE').format(endDate['selected'])}",
                style: TextStyle(color: Utils.textColor, fontSize: 14),
              )),
            ),
          ]),
          contentSelection['selected'][0]
              ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Container(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.label_rounded,
                          color: category['selected'].color)),
                  Text(category['selected'].description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Utils.textColor))
                ])
              : Text(""),
        ],
      ),
    ));
  }

  Widget filterPopup(context, setState) {
    return AlertDialog(
      title: Text("Filter"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Text("Start date:"),
            TextButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Utils.textColor),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Utils.mediumLightColor),
              ),
              child: Text(DateFormat.yMMM().format(startDate['dialog'])),
              onPressed: () async {
                DateTime? newStartDate = await showMonthYearPicker(
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                              primary: Utils
                                  .mediumDarkColor, // header background color
                              secondary: Utils.mediumDarkColor,
                              onSecondary: Colors.white),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              primary:
                                  Utils.mediumDarkColor, // button text color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
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
                      MaterialStateProperty.all<Color>(Utils.textColor),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Utils.mediumLightColor),
                ),
                child: Text(DateFormat.yMMM().format(endDate['dialog'])),
                onPressed: () async {
                  DateTime? newEndDate = await showMonthYearPicker(
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                                primary: Utils
                                    .mediumDarkColor, // header background color
                                secondary: Utils.mediumDarkColor,
                                onSecondary: Colors.white),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                primary:
                                    Utils.mediumDarkColor, // button text color
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                      context: context,
                      initialDate: endDate['dialog'],
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100));
                  if (newEndDate != null) {
                    newEndDate =
                        DateTime(newEndDate.year, newEndDate.month + 1, 0);
                  }
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
                  Text("Content:"),
                  ToggleButtons(
                    color: Utils.textColor,
                    selectedColor: Utils.textColor,
                    fillColor: Utils.mediumLightColor,
                    children: [Text("Items"), Text("Totals")],
                    onPressed: (int index) {
                      List<bool> contentSelectionTemp = [];
                      for (int i = 0;
                          i < contentSelection['dialog'].length;
                          i++) {
                        contentSelectionTemp.add(i == index);
                      }
                      setState(() {
                        contentSelection['dialog'] = contentSelectionTemp;
                      });
                    },
                    isSelected: contentSelection['dialog'],
                  )
                ],
              )),
          contentSelection['dialog'][0]
              ? Container(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                          padding: EdgeInsets.only(right: 5),
                          child: Text("Category:")),
                      Flexible(child: dropDownCategory(context, setState)),
                    ],
                  ))
              : Container(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Exp/Inc:"),
                      ToggleButtons(
                        color: Utils.textColor,
                        selectedColor: Utils.textColor,
                        fillColor: Utils.mediumLightColor,
                        children: [Text("Expenses"), Text("Income")],
                        onPressed: (int index) {
                          setState(() {
                            for (int i = 0;
                                i < expIncSelection['dialog'].length;
                                i++) {
                              expIncSelection['dialog'][i] = (i == index);
                            }
                          });
                        },
                        isSelected: expIncSelection['dialog'],
                      )
                    ],
                  )),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Utils.textColor),
            backgroundColor:
                MaterialStateProperty.all<Color>(Utils.mediumLightColor),
          ),
          child: const Text('Apply'),
          onPressed: () async {
            setState(() {
              category['selected'] = category['dialog'];
              startDate['selected'] = startDate['dialog'];
              endDate['selected'] = endDate['dialog'];
              contentSelection['selected'] = contentSelection['dialog'];
              expIncSelection['selected'] = expIncSelection['dialog'];
            });
            await updateData();
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Utils.textColor),
            backgroundColor:
                MaterialStateProperty.all<Color>(Utils.mediumLightColor),
          ),
          child: const Text('Cancel'),
          onPressed: () async {
            setState(() {
              category['selected'] = category['previous'];
              startDate['selected'] = startDate['previous'];
              endDate['selected'] = endDate['previous'];
              contentSelection['selected'] = contentSelection['previous'];
              expIncSelection['selected'] = expIncSelection['previous'];
            });
            await updateData();
            Navigator.of(context).pop();
          },
        ),
      ],
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
            if (!categories.contains(allCategory)) {
              categories.insert(0, allCategory);
            }
            return DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                value: dropdownValueCategory,
                onChanged: (value) {
                  TransactionCategory newCategory =
                      TransactionCategory.getCategoryByDesc(value!, categories);
                  setState(() {
                    dropdownValueCategory = value;
                    category['dialog'] = newCategory;
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
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(Icons.label_rounded,
                                  color: category.color)),
                          SizedBox(
                              width: 100,
                              child: Text(
                                category.description,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12),
                              ))
                        ]),
                  );
                }).toList());
          } else {
            return Text("Unexpected error");
          }
        });
  }

  Widget buildDataTable() {
    return FutureBuilder(
        future: dataFutureItems,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            rowsItemsTable = [];
            for (var item in snapshot.data!) {
              rowsItemsTable.add(item['receiptItem'] as ReceiptItem);
            }
            return DataTable(
                columnSpacing: 30,
                sortAscending: isAscending,
                sortColumnIndex: sortColumnIndex,
                columns: getColumns(columns),
                rows: getRows(rowsItemsTable));
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
      rowsItemsTable.sort((row1, row2) =>
          Utils.compareString(ascending, row1.itemName, row2.itemName));
    } else if (columnIndex == 1) {
      rowsItemsTable.sort((row1, row2) =>
          Utils.compareNumber(ascending, row1.amount, row2.amount));
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  double getMaxItemsSum(List<ItemsChartData> items) {
    if (items.isEmpty) return 0;
    var max = items.first;
    items.forEach((e) {
      if (e.receiptItem.amount > max.receiptItem.amount) {
        max = e;
      }
    });
    return max.receiptItem.amount;
  }

  double getMaxCategorySum(List<CategoryChartData> categorySums) {
    if (categorySums.isEmpty) return 0;
    double max = categorySums.first.totalSum as double;
    categorySums.forEach((e) {
      double elementSum = e.totalSum;
      if (elementSum > max) {
        max = e.totalSum;
      }
    });
    return max;
  }

  @override
  Widget itemsChart() {
    return FutureBuilder(
        future: dataFutureItems,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            rowsItemsChart = [];
            for (var trans in snapshot.data!) {
              ItemsChartData icd = ItemsChartData(
                  trans['receiptItem'] as ReceiptItem,
                  trans['category'] as TransactionCategory);
              rowsItemsChart.add(icd);
            }
            rowsItemsChart.sort((a, b) => Utils.compareNumber(
                true, a.receiptItem.amount, b.receiptItem.amount));
            return Container(
                child: SfCartesianChart(
                    backgroundColor: Utils.lightColor,
                    primaryXAxis: CategoryAxis(
                        labelsExtent: 100, labelStyle: TextStyle(fontSize: 10)),
                    primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: getMaxItemsSum(rowsItemsChart),
                        interval: 100,
                        visibleMinimum: 0,
                        decimalPlaces: 2),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePanning: true,
                      enablePinching: true,
                      zoomMode: ZoomMode.y,
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <BarSeries<ItemsChartData, String>>[
                  BarSeries<ItemsChartData, String>(
                      dataSource: rowsItemsChart,
                      xValueMapper: (ItemsChartData item, _) =>
                          item.receiptItem.itemName,
                      yValueMapper: (ItemsChartData item, _) =>
                          item.receiptItem.amount,
                      name: '',
                      pointColorMapper: (ItemsChartData item, _) =>
                          item.category.color,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Utils.darkColor)
                ]));
          } else {
            return Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                    color: Colors.black, size: 40));
          }
        });
  }

  @override
  Widget totalsChart() {
    return FutureBuilder(
        future: dataFutureCategorySums,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            rowsTotals = [];
            for (var trans in snapshot.data!) {
              CategoryChartData ccd = CategoryChartData(
                  trans['totalSum'] as double,
                  trans['category'] as TransactionCategory);
              rowsTotals.add(ccd);
            }

            rowsTotals.sort(
                (a, b) => Utils.compareNumber(true, a.totalSum, b.totalSum));
            return Container(
                child: SfCartesianChart(
                    plotAreaBackgroundColor: Utils.lightColor,
                    primaryXAxis: CategoryAxis(
                        labelPosition: ChartDataLabelPosition.outside,
                        labelsExtent: 100,
                        labelStyle: TextStyle(fontSize: 14)),
                    primaryYAxis: NumericAxis(
                        labelPosition: ChartDataLabelPosition.outside,
                        minimum: 0,
                        maximum: getMaxCategorySum(rowsTotals),
                        interval: getMaxCategorySum(rowsTotals) == 0
                            ? 100
                            : (getMaxCategorySum(rowsTotals) / 10),
                        numberFormat: NumberFormat.currency(
                            locale: "sv_SE", decimalDigits: 0),
                        visibleMinimum: 0,
                        decimalPlaces: 2),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePanning: true,
                      enablePinching: true,
                      zoomMode: ZoomMode.y,
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <BarSeries<CategoryChartData, String>>[
                  BarSeries<CategoryChartData, String>(
                    sortingOrder: SortingOrder.ascending,
                    dataSource: rowsTotals,
                    xValueMapper: (CategoryChartData object, _) =>
                        object.category.description,
                    yValueMapper: (CategoryChartData object, _) =>
                        object.totalSum,
                    name: '',
                    pointColorMapper: (CategoryChartData object, _) =>
                        object.category.color,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ]));
          } else {
            return Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                    color: Colors.black, size: 40));
          }
        });
  }
}

class ItemsChartData {
  ItemsChartData(this.receiptItem, this.category);
  final ReceiptItem receiptItem;
  final TransactionCategory category;
}

class CategoryChartData {
  CategoryChartData(this.totalSum, this.category);
  final double totalSum;
  final TransactionCategory category;
}
