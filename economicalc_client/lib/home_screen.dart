import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  Widget titleSection = Container(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("EconomiCalc",
                style: TextStyle(
                    color: new Color(0xff000000),
                    fontWeight: FontWeight.bold,
                    fontSize: 36.0)))
      ],
    ),
  );

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
              padding: EdgeInsets.all(10.0),
            ),
            Icon(icon, color: color),
          ],
        ));
  }

  Widget iconSection = Container(
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    return Scaffold(
        body: ListView(
      children: <Widget>[
        titleSection,
        iconSection,
      ],
    ));
  }
}
