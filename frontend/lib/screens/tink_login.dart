import 'package:economicalc_client/services/open_link.dart';
import 'package:flutter/material.dart';
import '../services/open_link.dart';

class TinkLogin extends StatelessWidget {
  bool test = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login with Tink Api"),
      ),
      body: Center(
        child: FloatingActionButton(
          child: Text("Open login"),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OpenLink(test)));
          },
        ),
      ),
    );
  }
}
