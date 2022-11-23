import 'dart:async';

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
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
        ));
  }
}
