import 'package:economicalc_client/screens/results_screen.dart';
import 'dart:io';

import 'package:economicalc_client/screens/statistics_screen.dart';
import 'package:economicalc_client/components/history_list.dart';
import 'package:economicalc_client/screens/tink_login.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/transaction_event.dart';

late BuildContext _context;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  late String appName = "EconomiCalc";

  static void goToResults(XFile? image) {
    //process stuff

    Navigator.push(_context,
        MaterialPageRoute(builder: (_context) => ResultsScreen(image: image)));
  }

  Widget iconSection = Container(
    color: Color(0xFFB8D8D8),
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
              Navigator.push(_context,
                  MaterialPageRoute(builder: (_context) => StatisticsScreen()));
            }),
          ),
          IconButton(
            icon: Icon(Icons.abc),
            onPressed: (() {
              Navigator.push(_context,
                  MaterialPageRoute(builder: (_context) => TinkLogin()));
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
    backgroundColor: new Color(0xff69A3A7),
    child: ListView(
      padding: EdgeInsets.fromLTRB(0, 80, 0, 0),
      itemExtent: 70.0,
      children: [
        ListTile(
          tileColor: new Color(0xffD4E6F3),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: new Color(0xff69A3A7), width: 10),
          ),
          title: Text('History',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            // Update the state of the app.
            // ...
          },
        ),
        ListTile(
          tileColor: new Color(0xffD4E6F3),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: new Color(0xff69A3A7), width: 10),
          ),
          title: Text('Scan',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            print("scan in hamburger");
          },
        ),
        ListTile(
          tileColor: new Color(0xffD4E6F3),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: new Color(0xff69A3A7), width: 10),
          ),
          title: Text('Settings',
              style:
                  GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold)),
          onTap: () {
            // Update the state of the app.
            // ...
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
              backgroundColor: Color(0xFFB8D8D8),
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
            ),
            key: _globalKey,
            drawer: drawer,
            body: Column(
              children: [iconSection, Expanded(child: HistoryList())],
            )));
  }
}
