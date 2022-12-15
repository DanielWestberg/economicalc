import 'package:economicalc_client/components/drawer.dart';
import 'package:economicalc_client/helpers/sqlite.dart';
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
  final SQFLite dbConnector = SQFLite.instance;
  bool showSearchBar = false;
  TextEditingController editingController = TextEditingController();

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
    "selected": ReceiptCategory.noneCategory,
    "previous": ReceiptCategory.noneCategory,
    "dialog": ReceiptCategory.noneCategory,
  };

  String dropdownValueCategory = 'None';
  late List<ReceiptCategory> categories;
  late Future<List<ReceiptCategory>> categoriesFutureBuilder;

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
        Phoenix.rebirth(_context);
      }
    });
  }

  Widget renderSearchField() {
    return Container(
        color: Utils.mediumLightColor,
        padding: EdgeInsets.all(25),
        child: TextField(
          onChanged: (value) {
            historyListStateKey.currentState!.search(value);
          },
          controller: editingController,
          decoration: InputDecoration(
              focusColor: Utils.lightColor,
              hoverColor: Utils.lightColor,
              labelText: "Search",
              hintText: "Search",
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear_rounded),
                onPressed: (() {
                  setState(() {
                    showSearchBar = false;
                  });
                }),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)))),
        ));
  }

  Widget iconSection() {
    return Container(
      color: Utils.mediumLightColor,
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
                iconSize: 30,
                icon: Icon(Icons.camera_alt_outlined),
                onPressed: (() async {
                  final XFile? image =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  //process()
                  if (image == null) return;
                  ImageGallerySaver.saveFile(image.path);
                  goToResults(image);
                })),
            IconButton(
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
              iconSize: 30,
              icon: Icon(Icons.search_rounded),
              onPressed: (() async {
                setState(() {
                  showSearchBar = true;
                });
              }),
            ),
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.filter_alt_rounded),
              onPressed: (() {
                startDate['previous'] =
                    startDate['dialog'] = startDate['selected'];
                endDate['previous'] = endDate['dialog'] = endDate['selected'];
                category['previous'] =
                    category['dialog'] = category['selected'];
                dropdownValueCategory = category['selected'].description;
                showDialog(
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

  bool test = true;
  Widget drawer = Drawer(
    width: 250,
    backgroundColor: Utils.lightColor.withOpacity(1),
    child: ListView(
      padding: EdgeInsets.fromLTRB(10, 50, 10, 0),
      itemExtent: 60.0,
      children: [
        ListTile(
          iconColor: Utils.mediumDarkColor,
          textColor: Utils.mediumDarkColor,
          selected: true,
          selectedColor: Utils.darkColor,
          selectedTileColor: Utils.mediumDarkColor.withOpacity(0.7),
          style: ListTileStyle.drawer,
          minLeadingWidth: 10,
          leading: Icon(Icons.history_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title:
              Text('History', style: TextStyle(fontSize: Utils.drawerFontsize)),
          onTap: () {
            Navigator.push(_context,
                MaterialPageRoute(builder: (_context) => HomeScreen()));
          },
        ),
        ListTile(
          iconColor: Utils.mediumDarkColor,
          textColor: Utils.mediumDarkColor,
          selected: false,
          selectedColor: Utils.darkColor,
          selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
          style: ListTileStyle.drawer,
          minLeadingWidth: 10,
          leading: Icon(Icons.auto_graph_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title: Text('Statistics',
              style: TextStyle(fontSize: Utils.drawerFontsize)),
          onTap: () {
            Navigator.push(_context,
                MaterialPageRoute(builder: (_context) => StatisticsScreen()));
          },
        ),
        ListTile(
          iconColor: Utils.mediumDarkColor,
          textColor: Utils.mediumDarkColor,
          selected: false,
          selectedColor: Utils.darkColor,
          selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
          style: ListTileStyle.drawer,
          minLeadingWidth: 10,
          leading: Icon(Icons.science_rounded),
          tileColor: Utils.lightColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title: Text('Login TEST',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.of(_context)
                .push(MaterialPageRoute(builder: (_context) => OpenLink(true)))
                .then((value) {
              Phoenix.rebirth(_context);
            });
          },
        ),
        ListTile(
          iconColor: Utils.mediumDarkColor,
          textColor: Utils.mediumDarkColor,
          selected: false,
          selectedColor: Utils.darkColor,
          selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
          style: ListTileStyle.drawer,
          minLeadingWidth: 10,
          leading: Icon(Icons.account_balance_rounded),
          tileColor: Utils.lightColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title: Text('Connect to bank',
              style: TextStyle(fontSize: Utils.drawerFontsize)),
          onTap: () {
            Navigator.of(_context)
                .push(MaterialPageRoute(builder: (_context) => OpenLink(false)))
                .then((value) {
              Phoenix.rebirth(_context);
            });
          },
        ),
        ListTile(
          iconColor: Utils.mediumDarkColor,
          textColor: Utils.mediumDarkColor,
          selected: false,
          selectedColor: Utils.darkColor,
          selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
          style: ListTileStyle.drawer,
          minLeadingWidth: 10,
          leading: Icon(Icons.settings_rounded),
          tileColor: Utils.lightColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title: Text('Settings',
              style: TextStyle(fontSize: Utils.drawerFontsize)),
          onTap: () {
            Navigator.of(_context)
                .push(
                    MaterialPageRoute(builder: (_context) => SettingsScreen()))
                .then((value) {
              Phoenix.rebirth(_context);
            });
          },
        ),
      ],
    ),
  );

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
                      MaterialStateProperty.all<Color>(Utils.textColor),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Utils.mediumLightColor),
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
                  const Text("Category:"),
                  dropDownCategory(context, setState),
                ],
              ))
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
            updateSelected(
                startDate['dialog'], endDate['dialog'], category['dialog']);
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
            if (!categories.contains(ReceiptCategory.noneCategory)) {
              categories.insert(0, ReceiptCategory.noneCategory);
            }
            return SizedBox(
                width: 130,
                height: 30,
                child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: dropdownValueCategory,
                    onChanged: (value) {
                      ReceiptCategory newCategory =
                          ReceiptCategory.getCategoryByDesc(value!, categories);
                      setState(() {
                        dropdownValueCategory = value;
                        category['dialog'] = newCategory;
                      });
                    },
                    items: categories.map<DropdownMenuItem<String>>(
                        (ReceiptCategory category) {
                      return DropdownMenuItem<String>(
                        value: category.description,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(Icons.circle_rounded,
                                      color: category.color)),
                              Text(category.description,
                                  overflow: TextOverflow.ellipsis)
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
    List<Widget> children = [
      Expanded(
          child: HistoryList(historyListStateKey, startDate['selected'],
              endDate['selected'], category['selected'])),
      iconSection(),
    ];
    if (showSearchBar) {
      children = [
        Expanded(
            child: HistoryList(historyListStateKey, startDate['selected'],
                endDate['selected'], category['selected'])),
        renderSearchField(),
      ];
    }
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
            body: Column(
              children: children,
            )));
  }
}
