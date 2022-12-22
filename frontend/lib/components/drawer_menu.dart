import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/receipt.dart';
import 'package:economicalc_client/screens/home_screen.dart';
import 'package:economicalc_client/screens/settings_screen.dart';
import 'package:economicalc_client/screens/statistics_screen.dart';
import 'package:economicalc_client/services/api_calls.dart';
import 'package:economicalc_client/services/open_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:image_picker/image_picker.dart';

class DrawerMenu extends StatelessWidget {
  int selectedIndex;
  DrawerMenu(this.selectedIndex);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: Utils.lightColor.withOpacity(1),
      child: ListView(
        padding: EdgeInsets.fromLTRB(10, 50, 10, 0),
        itemExtent: 60.0,
        children: [
          ListTile(
            iconColor: Utils.mediumDarkColor,
            textColor: Utils.mediumDarkColor,
            selected: selectedIndex == 0,
            selectedColor: Utils.darkColor,
            selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
            style: ListTileStyle.drawer,
            minLeadingWidth: 10,
            leading: Icon(Icons.home_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            title:
                Text('Home', style: TextStyle(fontSize: Utils.drawerFontsize)),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => HomeScreen()));
            },
          ),
          ListTile(
            iconColor: Utils.mediumDarkColor,
            textColor: Utils.mediumDarkColor,
            selected: selectedIndex == 1,
            selectedColor: Utils.darkColor,
            selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
            style: ListTileStyle.drawer,
            minLeadingWidth: 10,
            leading: Icon(Icons.line_axis_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            title: Text('Statistics',
                style: TextStyle(fontSize: Utils.drawerFontsize)),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => StatisticsScreen()))
                  .then((value) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              });
            },
          ),
          // ListTile(
          //   iconColor: Utils.mediumDarkColor,
          //   textColor: Utils.mediumDarkColor,
          //   selected: selectedIndex == 2,
          //   selectedColor: Utils.darkColor,
          //   selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
          //   style: ListTileStyle.drawer,
          //   minLeadingWidth: 10,
          //   leading: Icon(Icons.science_rounded),
          //   tileColor: Utils.lightColor.withOpacity(0.5),
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.all(Radius.circular(10)),
          //   ),
          //   title: Text('Run tests',
          //       style: TextStyle(fontSize: Utils.drawerFontsize)),
          //   onTap: () async {
          //     print("Running tests");
          //     String userId = "bruh";
          //     List<ReceiptItem> items = [
          //       ReceiptItem(
          //         itemName: "Snusk",
          //         amount: 9001,
          //       ),
          //     ];
          //     Receipt receipt = Receipt(
          //       recipient: "ica",
          //       date: DateTime.now(),
          //       items: items,
          //       total: 100.0,
          //       categoryID: 1,
          //     );
          //     await postReceipt(userId, receipt);

          //     List<Receipt> responseReceipts = await fetchReceipts(userId);
          //     print(responseReceipts);

          //     print("Take a picture to proceed");
          //     final XFile? image =
          //         await ImagePicker().pickImage(source: ImageSource.camera);
          //     if (image == null) {
          //       return;
          //     }

          //     String backendId = responseReceipts[0].backendId!;
          //     await updateImage(userId, backendId, image);
          //     final responseImage = await fetchImage(userId, backendId);
          //     print("Original image size: ${await image.length()}");
          //     print("Response image size: ${await responseImage.length()}");

          //     final responseBytes = await responseImage.readAsBytes();
          //     print("Displaying response image...");
          //     Navigator.of(context)
          //         .push(MaterialPageRoute(
          //             builder: (context) => Image.memory(responseBytes)))
          //         .then((value) {
          //       Phoenix.rebirth(context);
          //     });

          //     print("Updating a receipt...");
          //     receipt.items[0].itemName = "Snus";
          //     await updateReceipt(userId, backendId, receipt);
          //     responseReceipts = await fetchReceipts(userId);
          //     print(responseReceipts);

          //     print("Tests finished");
          //   },
          // ),
          ListTile(
            iconColor: Utils.mediumDarkColor,
            textColor: Utils.mediumDarkColor,
            selected: false,
            selectedColor: Utils.darkColor,
            selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
            style: ListTileStyle.drawer,
            minLeadingWidth: 10,
            leading: Icon(Icons.science_rounded),
            tileColor: Utils.lightColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            title: Text('Login TEST',
                style: TextStyle(fontSize: Utils.drawerFontsize)),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => OpenLink(true)))
                  .then((value) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              });
            },
          ),
          ListTile(
            iconColor: Utils.mediumDarkColor,
            textColor: Utils.mediumDarkColor,
            selected: selectedIndex == 3,
            selectedColor: Utils.darkColor,
            selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
            style: ListTileStyle.drawer,
            minLeadingWidth: 10,
            leading: Icon(Icons.account_balance_rounded),
            tileColor: Utils.lightColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            title: Text('Connect to bank',
                style: TextStyle(fontSize: Utils.drawerFontsize)),
            onTap: () {
              Navigator.of(context)
                  .push(
                      MaterialPageRoute(builder: (context) => OpenLink(false)))
                  .then((value) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              });
            },
          ),
          ListTile(
            iconColor: Utils.mediumDarkColor,
            textColor: Utils.mediumDarkColor,
            selected: selectedIndex == 4,
            selectedColor: Utils.darkColor,
            selectedTileColor: Utils.mediumLightColor.withOpacity(0.7),
            style: ListTileStyle.drawer,
            minLeadingWidth: 10,
            leading: Icon(Icons.settings_rounded),
            tileColor: Utils.lightColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            title: Text('Settings',
                style: TextStyle(fontSize: Utils.drawerFontsize)),
            onTap: () {
              Navigator.of(context)
                  .push(
                      MaterialPageRoute(builder: (context) => SettingsScreen()))
                  .then((value) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              });
            },
          ),
        ],
      ),
    );
  }
}
