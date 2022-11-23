import 'dart:async';

import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OpenLink extends StatelessWidget {
  final String title;
  final String clientId;
  final String redirectUri;
  final String selectedUrl;

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  OpenLink(
      {required this.title,
      required this.selectedUrl,
      required this.clientId,
      required this.redirectUri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: WebView(
          initialUrl: selectedUrl,
          navigationDelegate: (action) {
            if (action.url.contains("http://127.0.0.1:5000/Oath") &&
                action.url.contains("code")) {
              //{YOUR_CALLBACK_URI}?code={YOUR_CODE}&credentials_id={YOUR_CREDENTIALS_ID}
              print(action.url);
              var redirectUrl = action.url;
              redirectUrl.split("?");
              var code_and_credentials = redirectUrl[1];
              code_and_credentials.split("&");
              var code = code_and_credentials[0];
              var credential_id = code_and_credentials[1];
              code = code.split("=")[1];
              credential_id = credential_id.split("=")[1];
              var access_token = CodeToAccessToken(code);
              print(access_token);
              FutureBuilder(
                future: CodeToAccessToken(code),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var transactions = fetchTransactions(snapshot.data!);
                    print(transactions);
                    //This is the list of transactions
                  }
                },
              );

              return NavigationDecision.prevent;
            } else if (action.url.contains("http://127.0.0.1:5000/Oath") &&
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
