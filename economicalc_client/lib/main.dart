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


//   Column buildButtonColumn(IconData icon) {
  
//   Color color = Colors.black;
//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: <Widget>[
//       Padding(
//         padding: EdgeInsets.all(10.0),
//       ),
//       Icon(icon, color: color),
//     ],
//   );
// }
//   Widget iconSection=Container(
//     child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: <Widget>[
//       buildButtonColumn(Icons.search)
//     ]),
//   )

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EconomiCalc',
      home: Scaffold (
        body: ListView(
          children: <Widget>[
            titleSection
          ],
          )
        ),
    );
  }
}