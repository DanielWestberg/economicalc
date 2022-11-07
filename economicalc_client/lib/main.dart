// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EconomiCalc',
      theme: new ThemeData(scaffoldBackgroundColor: const Color(0xFFB8D8D8)),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  late String appName = "EconomiCalc";

  static GestureDetector buildButtonColumn(IconData icon) {
    Color color = Colors.black;
    return GestureDetector(
        onTap: () {
          print("hej");
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
            ),
            Icon(icon, color: color, size: 32),
          ],
        ));
  }

  final Widget iconSection = Container(
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          buildButtonColumn(Icons.scanner),
          buildButtonColumn(Icons.search),
          buildButtonColumn(Icons.auto_graph),
          buildButtonColumn(Icons.filter)
          //TODO replace with figma svgs
        ]),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            key: _globalKey,
            drawer: Drawer(
              backgroundColor: new Color(0xff69A3A7),
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('History'),
                    onTap: () {
                      // Update the state of the app.
                      // ...
                    },
                  ),
                  ListTile(
                    title: const Text('Scan'),
                    onTap: () {
                      // Update the state of the app.
                      // ...
                    },
                  ),
                  ListTile(
                    title: const Text('Settings'),
                    onTap: () {
                      // Update the state of the app.
                      // ...
                    },
                  ),
                ],
              ),
            ),
            body: Wrap(
              runSpacing: 50,
              children: [
                Padding(
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
                ),
                iconSection
              ],
            )));
  }
}
