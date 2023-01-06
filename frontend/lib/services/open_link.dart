import 'dart:async';
import 'dart:core';

import 'package:economicalc_client/helpers/unified_db.dart';
import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/LoginData.dart';
import 'package:economicalc_client/models/response.dart';
import 'package:economicalc_client/models/bank_transaction.dart';
import 'package:economicalc_client/models/transaction.dart';
import 'package:economicalc_client/screens/home_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent/android_intent.dart';
import 'dart:convert' as convert;

class OpenLink extends StatefulWidget {
  final bool test;
  const OpenLink(this.test, {super.key});

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
  late String selectedUrl =
      "https://link.tink.com/1.0/reports/create-report?client_id=1a539460199a4e8bb374893752db14e6&redirect_uri=https://console.tink.com/callback&market=SE&report_types=TRANSACTION_REPORT,ACCOUNT_VERIFICATION_REPORT&refreshable_items=IDENTITY_DATA,CHECKING_ACCOUNTS,SAVING_ACCOUNTS,CHECKING_TRANSACTIONS,SAVING_TRANSACTIONS";

  late final Response response;
  late final List<BankTransaction> transactions;
  final UnifiedDb dbConnector = UnifiedDb.instance;
  final apiCaller = ApiCaller();

  @override
  void initState() {
    if (widget.test == false) {
      selectedUrl =
          "https://link.tink.com/1.0/reports/create-report?client_id=1e48aa066d3f46bcb31bf2acb949a6ca&redirect_uri=https://console.tink.com/callback&market=SE&report_types=TRANSACTION_REPORT,ACCOUNT_VERIFICATION_REPORT&refreshable_items=IDENTITY_DATA,CHECKING_ACCOUNTS,SAVING_ACCOUNTS,CHECKING_TRANSACTIONS,SAVING_TRANSACTIONS";
    }
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Utils.textColor,
          backgroundColor: Utils.mediumLightColor,
          title: Text(title),
        ),
        body: WebView(
          initialUrl: selectedUrl,
          navigationDelegate: (action) async {
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

              response = await apiCaller.CodeToAccessToken(code, widget.test);
              transactions =
                  await apiCaller.fetchTransactions(response.accessToken);

              await dbConnector.postMissingBankTransactions(transactions);

              if (!mounted) return NavigationDecision.prevent;
              Navigator.of(context).popUntil((route) => route.isFirst);
              return NavigationDecision.prevent;
            } else if (action.url.contains("console.tink.com/callback") &&
                action.url.contains("account_verification_report_id") &&
                action.url.contains("transaction_report_id")) {
              Map<String, String> params = Uri.splitQueryString(action.url);

              String transaction_report_id = params["transaction_report_id"]!;
              String account_report_id = params[
                  "https://console.tink.com/callback?account_verification_report_id"]!;
              LoginData data;
              try {
                data = await apiCaller.fetchLoginData(
                    account_report_id, transaction_report_id, widget.test);
              } catch (e) {
                Navigator.of(context).pop(false);
                final snackBar = SnackBar(
                  backgroundColor: Utils.errorColor,
                  content: Text(
                    e.toString(),
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                rethrow;
              }

              List<BankTransaction> resTrans = [];
              data.transactionReport["transactions"].forEach((transaction) {
                resTrans.add(BankTransaction.fromJson(transaction));
              });

              await dbConnector.postMissingBankTransactions(resTrans);

              List<int> addedUpdated = await dbConnector.updateTransactions();
              await dbConnector.syncWithBackend();

              final snackBar = SnackBar(
                backgroundColor: Utils.mediumDarkColor,
                content: Text(
                  "${addedUpdated[0]} transactions were added. ${addedUpdated[1]} transactions were updated.",
                  style: TextStyle(color: Utils.lightColor),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              if (!mounted) return NavigationDecision.prevent;
              Navigator.of(context).popUntil((route) => route.isFirst);
              return NavigationDecision.prevent;
            } else if (action.url
                    .contains("http%3A%2F%2Flocalhost%3A5000%2Fcallback") &&
                !action.url.contains("code")) {
              //NO CODE REETURNED == SOMETHING WENT WRONG
              return NavigationDecision.navigate;
            } else if (action.url.contains("bankid")) {
              Map<String, String> params = Uri.splitQueryString(action.url);
              String autostarttoken = params["bankid:///?autostarttoken"]!;

              String redirect = "null";

              String bankIdUrl =
                  "https://app.bankid.com/?autostarttoken=$autostarttoken&redirect=$redirect";

              AndroidIntent intent =
                  AndroidIntent(data: bankIdUrl, action: "action_view");
              await intent.launch();

              return NavigationDecision.prevent;
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
