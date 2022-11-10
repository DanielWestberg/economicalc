import 'package:flutter/material.dart';
import 'package:economicalc_client/camera_screen.dart';
import 'package:google_fonts/google_fonts.dart';

late BuildContext _context;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  late String appName = "EconomiCalc";

  Widget titleSection(GlobalKey<ScaffoldState> _globalKey) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 20, 0, 0),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          IconButton(
              onPressed: () {
                _globalKey.currentState?.openDrawer();
              },
              icon: Icon(Icons.menu, size: 32),
              color: Colors.black),
          Container(
              alignment: Alignment.topCenter,
              child: Text(appName,
                  style: TextStyle(
                      color: new Color(0xff000000),
                      fontWeight: FontWeight.bold,
                      fontSize: 36.0)))
        ],
      ),
    );
  }

  Widget iconSection = Container(
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.camera_alt_outlined),
            onPressed: (() {
              Navigator.push(_context,
                  MaterialPageRoute(builder: (_context) => CameraScreen()));
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
              print("auto_graph");
            }),
          ),
          IconButton(
            icon: Icon(Icons.filter),
            onPressed: (() {
              print("filter");
            }),
          ),
          //TODO replace with figma svgs
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
            key: _globalKey,
            drawer: drawer,
            body: Wrap(
              runSpacing: 50,
              children: [titleSection(_globalKey), iconSection],
            )));
  }
}
