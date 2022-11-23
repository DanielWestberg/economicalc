import 'package:economicalc_client/services/open_link.dart';
import 'package:flutter/material.dart';
import '../services/open_link.dart';

class TinkLogin extends StatelessWidget {
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
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => OpenLink(
                      title: "DigitalOcean",
                      clientId: "1a539460199a4e8bb374893752db14e6",
                      redirectUri: "hhttp://127.0.0.1:5000/Oath",
                      selectedUrl:
                          "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=1a539460199a4e8bb374893752db14e6&redirect_uri=http://127.0.0.1:5000/Oath&market=GB&locale=en_US&test=true",
                    )));
          },
        ),
      ),
    );
  }
}
