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
                      title: "LOGIN",
                      clientId: "1a539460199a4e8bb374893752db14e6",
                      redirectUri: "hhttp://127.0.0.1:5000/Oath",
                      selectedUrl:
                          "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=1a539460199a4e8bb374893752db14e6&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fcallback&market=SE&locale=sv_SE&test=true",
                    )));
          },
        ),
      ),
    );
  }
}
