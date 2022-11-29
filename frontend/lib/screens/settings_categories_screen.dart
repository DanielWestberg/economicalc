import 'package:economicalc_client/helpers/utils.dart';
import 'package:economicalc_client/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoriesScreen extends StatefulWidget {
  // const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late List<Category> categories;
  Color pickerColor = Utils.backgroundColor;
  Color previousColor = Utils.backgroundColor;
  String description = "";

  @override
  void initState() {
    super.initState();
    categories = getCategories(); //TODO: replace with fetching from db
  }

  List<Category> getCategories() {
    return Utils.categories;
  }

  void changeColor(Color color, index) {
    setState(() => categories[index].color = color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.black,
          backgroundColor: Utils.backgroundColor,
          title: Text("Categories", style: TextStyle(fontSize: 30)),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: EdgeInsets.only(top: 10, right: 10, left: 10),
              child: Card(
                child: ListTile(
                    title: Text("Add category"),
                    trailing: IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Add new category"),
                                  icon: Icon(Icons.category),
                                  content: SingleChildScrollView(
                                      child: Column(children: [
                                    Text("Enter description:"),
                                    TextField(
                                        onChanged: (value) => setState(
                                            () => description = value)),
                                    Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text("Pick a color:")),
                                    ColorPicker(
                                        pickerColor: pickerColor,
                                        onColorChanged: ((pickedColor) =>
                                            setState(() {
                                              pickerColor = pickedColor;
                                            })))
                                  ])),
                                  actions: [
                                    ElevatedButton(
                                      child: const Text('Save'),
                                      onPressed: () {
                                        if (description.length > 0) {
                                          categories.add(new Category(
                                              description: description,
                                              color: pickerColor));
                                          Navigator.of(context).pop();
                                          setState(() {});
                                        } else {
                                          print("Description is empty");
                                        }
                                      },
                                    ),
                                    ElevatedButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              });
                        })),
              )),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: ((context, index) {
                      return Card(
                          child: ListTile(
                        leading: IconButton(
                            icon: Icon(Icons.circle,
                                color: categories[index].color),
                            onPressed: () {
                              pickerColor = categories[index].color;
                              previousColor = categories[index].color;
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Pick a color"),
                                      content: ColorPicker(
                                          pickerColor: pickerColor,
                                          onColorChanged: ((pickerColor) =>
                                              setState(() => categories[index]
                                                  .color = pickerColor))),
                                      actions: [
                                        ElevatedButton(
                                          child: const Text('Save'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ElevatedButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            setState(() {
                                              categories[index].color =
                                                  previousColor;
                                            });
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            }),
                        title: Text(categories[index].description),
                        trailing: PopupMenuButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Text("Remove"),
                                    onTap: () {
                                      categories.removeAt(index);
                                      setState(() {});
                                    },
                                  )
                                ]),
                      ));
                    }),
                  )))
        ])));
  }
}
