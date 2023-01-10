import 'package:economicalc_client/components/drawer_menu.dart';
import 'package:economicalc_client/helpers/unified_db.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/screens/results_screen.dart';
import 'package:economicalc_client/screens/settings_screen.dart';

import 'package:economicalc_client/screens/statistics_screen.dart';
import 'package:economicalc_client/components/history_list.dart';
import 'package:economicalc_client/screens/tink_login.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:economicalc_client/services/open_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:month_year_picker/month_year_picker.dart';

late BuildContext _context;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  GlobalKey<HistoryListState> historyListStateKey =
      GlobalKey<HistoryListState>();
  late String appName = "EconomiCalc";
  final UnifiedDb dbConnector = UnifiedDb.instance;
  bool showSearchBar = false;
  TextEditingController editingController = TextEditingController();
  bool onlyReceipts = false;

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
    "selected": TransactionCategory.allCategory,
    "previous": TransactionCategory.allCategory,
    "dialog": TransactionCategory.allCategory,
  };

  String dropdownValueCategory = 'All';
  late List<TransactionCategory> categories;
  late Future<List<TransactionCategory>> categoriesFutureBuilder;

  @override
  void initState() {
    super.initState();
    categoriesFutureBuilder = dbConnector.getAllcategories();
  }

  static void goToResults(XFile? image) {
    Navigator.of(_context)
        .push(MaterialPageRoute(
            builder: (context) => ResultsScreen(image: image)))
        .then((value) {
      if (value != false) {
        Navigator.push(
            _context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    });
  }

  Widget renderSearchField() {
    return Container(
        color: Utils.lightColor,
        padding: EdgeInsets.only(top: 20, right: 20, left: 20),
        child: TextField(
          onChanged: (value) {
            historyListStateKey.currentState!.search(value);
          },
          controller: editingController,
          decoration: InputDecoration(
              labelStyle: TextStyle(color: Utils.mediumDarkColor),
              hintStyle: TextStyle(color: Utils.textColor),
              labelText: "Search",
              hintText: "Search",
              focusColor: Utils.mediumDarkColor,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Utils.mediumDarkColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: Utils.mediumDarkColor,
                ),
                onPressed: (() {
                  setState(() {
                    showSearchBar = false;
                    editingController.clear();
                  });
                }),
              ),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Utils.darkColor),
                  borderRadius: BorderRadius.all(Radius.circular(25.0))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Utils.mediumDarkColor),
                  borderRadius: BorderRadius.all(Radius.circular(25.0)))),
        ));
  }

  Widget iconSection() {
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      color: Utils.mediumLightColor,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
                color: Utils.textColor,
                iconSize: 30,
                icon: Icon(Icons.camera_alt_outlined),
                onPressed: (() async {
                  final XFile? image =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (image == null) return;
                  ImageGallerySaver.saveFile(image.path);
                  goToResults(image);
                })),
            IconButton(
              color: Utils.textColor,
              iconSize: 30,
              icon: Icon(Icons.filter_rounded),
              onPressed: (() async {
                final XFile? image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image == null) return;
                goToResults(image);
              }),
            ),
            IconButton(
              color: Utils.textColor,
              iconSize: 30,
              icon: Icon(Icons.search_rounded),
              onPressed: (() async {
                setState(() {
                  showSearchBar = true;
                });
              }),
            ),
            IconButton(
              color: Utils.textColor,
              iconSize: 30,
              icon: Icon(Icons.filter_alt_rounded),
              onPressed: (() async {
                startDate['previous'] =
                    startDate['dialog'] = startDate['selected'];
                endDate['previous'] = endDate['dialog'] = endDate['selected'];
                category['previous'] =
                    category['dialog'] = category['selected'];
                dropdownValueCategory = category['selected'].description;
                await showDialog(
                    context: _context,
                    builder: (context) {
                      return StatefulBuilder(builder: (context, setState) {
                        return filterPopup(context, setState);
                      });
                    });
              }),
            ),
          ]),
    );
  }

  updateSelected(newStartDate, newEndDate, newCategory) {
    setState(() {
      startDate['selected'] = newStartDate;
      endDate['selected'] = newEndDate;
      category['selected'] = newCategory;
    });
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
                  Container(
                      padding: EdgeInsets.only(right: 5),
                      child: Text("Category:")),
                  Expanded(child: dropDownCategory(context, setState)),
                ],
              )),
          Container(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text("Only receipts:"),
                  Switch(
                    value: onlyReceipts,
                    onChanged: (bool newValue) {
                      setState(() {
                        onlyReceipts = newValue;
                      });
                    },
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
            if (endDate['dialog'].compareTo(startDate['dialog']) < 0) {
              final snackBar = SnackBar(
                backgroundColor: Utils.errorColor,
                content: Text(
                  "Start date cannot be later than the end date",
                  style: TextStyle(color: Colors.white),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            } else {
              updateSelected(
                  startDate['dialog'], endDate['dialog'], category['dialog']);
              Navigator.of(context).pop();
            }
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
            updateSelected(startDate['previous'], endDate['previous'],
                category['previous']);
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
            if (!categories.contains(TransactionCategory.allCategory)) {
              categories.insert(0, TransactionCategory.allCategory);
            }
            return SizedBox(
                width: 130,
                height: 30,
                child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: dropdownValueCategory,
                    onChanged: (value) {
                      TransactionCategory newCategory =
                          TransactionCategory.getCategoryByDesc(
                              value!, categories);
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
                    }).toList()));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 80,
              toolbarOpacity: 1,
              backgroundColor: Utils.mediumLightColor,
              foregroundColor: Utils.textColor,
              title: Text("EconomiCalc", style: TextStyle(fontSize: 36.0)),
              centerTitle: true,
              elevation: 5,
            ),
            key: _globalKey,
            drawer: DrawerMenu(0),
            resizeToAvoidBottomInset: false,
            bottomNavigationBar: iconSection(),
            body: Column(
              children: [
                showSearchBar ? renderSearchField() : Container(),
                Expanded(
                    child: HistoryList(
                        historyListStateKey,
                        startDate['selected'],
                        endDate['selected'],
                        category['selected'],
                        onlyReceipts)),
              ],
            )));
  }
}
