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
    "selected": Category.noneCategory,
    "previous": Category.noneCategory,
    "dialog": Category.noneCategory,
  };

  String dropdownValueCategory = 'None';
  late List<Category> categories;
  late Future<List<Category>> categoriesFutureBuilder;

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
      Phoenix.rebirth(_context);
    });
  }

  Widget renderSearchField() {
    return Container(
        color: Utils.backgroundColor,
        padding: EdgeInsets.all(25),
        child: TextField(
          onChanged: (value) {
            historyListStateKey.currentState!.search(value);
          },
          controller: editingController,
          decoration: InputDecoration(
              labelText: "Search",
              hintText: "Search",
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
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
      color: Utils.backgroundColor,
      padding: EdgeInsets.only(top: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <
          Widget>[
        IconButton(
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
          icon: Icon(Icons.filter),
          onPressed: (() async {
            final XFile? image =
                await ImagePicker().pickImage(source: ImageSource.gallery);
            if (image == null) return;
            goToResults(image);
          }),
        ),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: (() async {
            setState(() {
              showSearchBar = true;
            });
          }),
        ),
        IconButton(
          icon: Icon(Icons.auto_graph),
          onPressed: (() {
            Navigator.push(_context,
                MaterialPageRoute(builder: (_context) => StatisticsScreen()));
          }),
        ),
        IconButton(
          icon: Icon(Icons.filter_alt),
          onPressed: (() {
            startDate['previous'] = startDate['dialog'] = startDate['selected'];
            endDate['previous'] = endDate['dialog'] = endDate['selected'];
            category['previous'] = category['dialog'] = category['selected'];
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

  Widget drawer = Drawer(
    backgroundColor: Utils.drawerColor,
    child: ListView(
      padding: EdgeInsets.fromLTRB(0, 80, 0, 0),
      itemExtent: 70.0,
      children: [
        ListTile(
          tileColor: Utils.tileColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Utils.drawerColor, width: 10),
          ),
          title: Text('History',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.push(_context,
                MaterialPageRoute(builder: (_context) => HomeScreen()));
          },
        ),
        ListTile(
          tileColor: Utils.tileColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Utils.drawerColor, width: 10),
          ),
          title: Text('Scan',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            print("scan in hamburger");
          },
        ),
        ListTile(
          tileColor: Utils.tileColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Utils.drawerColor, width: 10),
          ),
          title: Text('Settings',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.of(_context)
                .push(
                    MaterialPageRoute(builder: (_context) => SettingsScreen()))
                .then((value) {
              Phoenix.rebirth(_context);
            });
          },
        ),
        ListTile(
          tileColor: Utils.tileColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Utils.drawerColor, width: 10),
          ),
          title: Text('Run tests',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () async {
            print("Running tests");
            String userId = "bruh";
            List<ReceiptItem> items = [
              ReceiptItem(
                itemName: "Snusk",
                amount: 9001,
              ),
            ];
            Receipt receipt = Receipt(
              recipient: "ica",
              date: DateTime.now(),
              items: items,
              total: 100.0,
              categoryID: 1,
            );
            await postReceipt(userId, receipt);

            List<Receipt> responseReceipts = await fetchReceipts(userId);
            print(responseReceipts);

            print("Take a picture to proceed");
            final XFile? image =
                await ImagePicker().pickImage(source: ImageSource.camera);
            if (image == null) {
              return;
            }

            String backendId = responseReceipts[0].backendId!;
            await updateImage(userId, backendId, image);
            final responseImage = await fetchImage(userId, backendId);
            print("Original image size: ${await image.length()}");
            print("Response image size: ${await responseImage.length()}");

            final responseBytes = await responseImage.readAsBytes();
            print("Displaying response image...");
            Navigator.of(_context)
                .push(MaterialPageRoute(
                    builder: (_context) => Image.memory(responseBytes)))
                .then((value) {
              Phoenix.rebirth(_context);
            });

            print("Updating a receipt...");
            receipt.items[0].itemName = "Snus";
            await updateReceipt(userId, backendId, receipt);
            responseReceipts = await fetchReceipts(userId);
            print(responseReceipts);

            print("Tests finished");
          },
        ),
        ListTile(
          tileColor: Utils.tileColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Utils.drawerColor, width: 10),
          ),
          title: Text('Login',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.of(_context)
                .push(MaterialPageRoute(builder: (_context) => OpenLink()))
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
                  const Text("Category:"),
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
            updateSelected(
                startDate['dialog'], endDate['dialog'], category['dialog']);
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Utils.backgroundColor)),
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
            if (!categories.contains(Category.noneCategory)) {
              categories.insert(0, Category.noneCategory);
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

  @override
  Widget build(BuildContext context) {
    _context = context;
    List<Widget> children = [
      iconSection(),
      Expanded(
          child: HistoryList(historyListStateKey, startDate['selected'],
              endDate['selected'], category['selected']))
    ];
    if (showSearchBar) {
      children = [
        renderSearchField(),
        Expanded(
            child: HistoryList(historyListStateKey, startDate['selected'],
                endDate['selected'], category['selected']))
      ];
    }
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 80,
              toolbarOpacity: 1,
              backgroundColor: Utils.backgroundColor,
              foregroundColor: Colors.black,
              title: Column(children: const [
                Text("EconomiCalc",
                    style: TextStyle(
                        color: Color(0xff000000),
                        fontWeight: FontWeight.bold,
                        fontSize: 36.0)),
              ]),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.of(_context)
                          .push(MaterialPageRoute(
                              builder: (_context) => SettingsScreen()))
                          .then((value) {
                        Phoenix.rebirth(_context);
                      });
                    },
                    icon: Icon(Icons.settings))
              ],
            ),
            key: _globalKey,
            drawer: drawer,
            body: Column(
              children: children,
            )));
  }
}
