// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:economicalc_client/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() {
  runApp(Phoenix(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'EconomiCalc',
        theme: new ThemeData(scaffoldBackgroundColor: const Color(0xFFB8D8D8)),
        home: HomeScreen());
  }
}
