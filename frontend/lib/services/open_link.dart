import 'dart:async';
import 'dart:core';

import 'package:economicalc_client/models/response.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OpenLink extends StatefulWidget {
  const OpenLink({super.key});

  //final String title;
  //final String clientId;
  //final String redirectUri;
  //final String selectedUrl;

  //const OpenLink(
  //    Key? key, this.title, this.clientId, this.redirectUri, this.selectedUrl)
  //    : super(key: key);

  @override
  OpenLinkState createState() => OpenLinkState();
}

class OpenLinkState extends State<OpenLink> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  late final String title = "Login";
  late final String clientId;
  late final String redirectUri;
  late final String selectedUrl =
      "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=1a539460199a4e8bb374893752db14e6&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fcallback&market=SE&locale=sv_SE&test=true";

  late final Response response;
  late final Future<List<BankTransaction>> transactions;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: WebView(
          initialUrl: selectedUrl,
          navigationDelegate: (action) {
            print(action.url);
            if (action.url.contains("http://localhost:3000/callback") &&
                action.url.contains("code")) {
              //{YOUR_CALLBACK_URI}?code={YOUR_CODE}&credentials_id={YOUR_CREDENTIALS_ID}
              var redirectUrl = action.url;
              List<String> redirect = redirectUrl.split("?");
              var code_and_credentials = redirect[1];
              List<String> code_and_cred = code_and_credentials.split("&");
              var code = code_and_cred[0];
              var credential_id = code_and_cred[1];
              code = code.split("=")[1];
              credential_id = credential_id.split("=")[1];

              setState(() async {
                // flutter klagar på detta, Varför??? Måste kanske fixas?
                response = await CodeToAccessToken(code);
                transactions = fetchTransactions(response.accessToken);
              });

              return NavigationDecision.prevent;
            } else if (action.url
                    .contains("http%3A%2F%2Flocalhost%3A5000%2Fcallback") &&
                !action.url.contains("code")) {
              //NO CODE REETURNED == SOMETHING WENT WRONG
              return NavigationDecision.navigate;
            } else {
              //NORMAL CASE - just redirecting to next link.
              return NavigationDecision.navigate;
            }
          },
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
        ));
  }
}
