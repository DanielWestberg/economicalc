import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/screens/settings_categories_screen.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatefulWidget {
  // const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Utils.backgroundColor,
        foregroundColor: Colors.black,
        title: Text("Settings"),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Column(
        children: [settings(context)],
      )),
    );
  }

  Widget settings(context) {
    return Expanded(
        child: SettingsList(
      lightTheme:
          SettingsThemeData(settingsListBackground: Utils.backgroundColor),
      sections: [
        SettingsSection(
          title: Text('Common'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: Icon(Icons.category),
              title: Text('Categories'),
              onPressed: ((context) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CategoriesScreen()));
              }),
            ),
            SettingsTile(leading: Icon(Icons.info), title: Text("About"))
          ],
        ),
      ],
    ));
  }
}