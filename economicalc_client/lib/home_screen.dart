import 'package:flutter/material.dart';

late BuildContext _context;

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

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
        body: ListView(
      children: <Widget>[
        titleSection,
        iconSection,
      ],
    ));
  }
}
