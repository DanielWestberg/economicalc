// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  Widget titleSection=Container(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Padding(padding: const EdgeInsets.all(8.0),
        child:Text(
          "EconomiCalc",
          style: TextStyle(
            color: new Color(0xff000000),
            fontWeight: FontWeight.bold,
            fontSize: 36.0
          )))
      ],
    ),
  );


  static GestureDetector buildButtonColumn(IconData icon) {
  
  Color color = Colors.black;
  return GestureDetector(
    onTap: (){print("hej");},
    child: Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.all(10.0),
      ),
      Icon(icon, color: color),
    ],
  )
  );
}
  Widget iconSection=Container(
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    return MaterialApp(
      title: 'EconomiCalc',
      theme: new ThemeData(scaffoldBackgroundColor: const Color(0xFFB8D8D8)),
      home: Scaffold (
        body: ListView(
          children: <Widget>[
            titleSection,
            iconSection,
          ],
          )
        ),
    );
  }
}