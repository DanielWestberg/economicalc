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
                      redirectUri: "https%3A%2F%2Fconsole.tink.com",
                      selectedUrl:
                          "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=1a539460199a4e8bb374893752db14e6&redirect_uri=https%3A%2F%2Fconsole.tink.com%2Fcallback&market=GB&locale=en_US&test=true",
                    )));
          },
        ),
      ),
    );
  }
}
