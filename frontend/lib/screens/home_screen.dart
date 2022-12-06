import 'package:economicalc_client/helpers/sqlite.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/screens/results_screen.dart';
import 'package:economicalc_client/screens/settings_screen.dart';
import 'dart:io';

import 'package:economicalc_client/screens/statistics_screen.dart';
import 'package:economicalc_client/components/history_list.dart';
import 'package:economicalc_client/screens/tink_login.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:economicalc_client/services/open_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/receipt.dart';

late BuildContext _context;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  late String appName = "EconomiCalc";
  final SQFLite dbConnector = SQFLite.instance;

  static void goToResults(XFile? image) {
    //process stuff

    Navigator.of(_context)
        .push(MaterialPageRoute(
            builder: (context) => ResultsScreen(image: image)))
        .then((value) {
      Phoenix.rebirth(_context);
    });

    /*Navigator.push(_context,
        MaterialPageRoute(builder: (_context) => ResultsScreen(image: image))
        .then() {
          dbConnector.transactions
        });*/
  }

  Widget iconSection = Container(
    color: Utils.backgroundColor,
    padding: EdgeInsets.only(top: 10),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
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
            onPressed: (() {
              print("search");
            }),
          ),
          IconButton(
            icon: Icon(Icons.auto_graph),
            onPressed: (() {
              Navigator.of(_context).push(
                  MaterialPageRoute(builder: (_context) => StatisticsScreen()));
            }),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: (() {
              print("filter");
            }),
          ),
        ]),
  );

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

  @override
  Widget build(BuildContext context) {
    _context = context;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 80,
              toolbarOpacity: 1,
              backgroundColor: Utils.backgroundColor,
              foregroundColor: Colors.black,
              title: Column(children: [
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
              children: [iconSection, Expanded(child: HistoryList())],
            )));
  }
}
