import 'package:economicalc_client/helpers/sqlite.dart';
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
  late Future<List<Category>> categoryFuture;
  late List<Category> categories;
  Color pickerColor = Utils.mediumLightColor;
  String description = "";
  final SQFLite dbConnector = SQFLite.instance;

  @override
  void initState() {
    super.initState();
    categoryFuture = dbConnector.getAllcategories();
  }

  updateCategories() async {
    var updatedCategories = await dbConnector.getAllcategories();
    var updatedCategoryFuture = dbConnector.getAllcategories();
    setState(() {
      categories = updatedCategories;
      categoryFuture = updatedCategoryFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: categoryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else if (snapshot.hasData) {
            categories = snapshot.data!;
            return Scaffold(
                appBar: AppBar(
                  foregroundColor: Colors.black,
                  backgroundColor: Utils.mediumLightColor,
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
                                        List<Category> categoriesPopUpCategory =
                                            categories;
                                        return popUpAddCategory(
                                            context, categoriesPopUpCategory);
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
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return popUpEditCategoryColor(
                                                context, index);
                                          });
                                    }),
                                title: Text(categories[index].description),
                                trailing: categories[index].description !=
                                        'Uncategorized'
                                    ? PopupMenuButton(
                                        icon: Icon(Icons.delete),
                                        itemBuilder: (context) => [
                                              PopupMenuItem(
                                                child: Text("Remove"),
                                                onTap: () async {
                                                  await dbConnector
                                                      .deleteCategoryByID(
                                                          categories[index]
                                                              .id!);
                                                  await updateCategories();
                                                },
                                              )
                                            ])
                                    : Text(""),
                              ));
                            }),
                          )))
                ])));
          } else {
            return Text("Unexpected error");
          }
        });
  }

  Widget popUpAddCategory(context, categoriesPopUpCategory) {
    return AlertDialog(
      title: Text("Add new category"),
      icon: Icon(Icons.category),
      content: SingleChildScrollView(
          child: Column(children: [
        Text("Enter description:"),
        TextField(onChanged: (value) => setState(() => description = value)),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("Pick a color:")),
        ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: ((pickedColor) => setState(() {
                  pickerColor = pickedColor;
                })))
      ])),
      actions: [
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () async {
            if (description.length > 0) {
              Category newCategory =
                  new Category(description: description, color: pickerColor);
              await dbConnector.insertCategory(newCategory);
              await updateCategories();
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
  }

  Widget popUpEditCategoryColor(context, index) {
    return AlertDialog(
      title: Text("Pick a color"),
      content: ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: ((pickerColor) =>
              setState(() => categories[index].color = pickerColor))),
      actions: [
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () async {
            await dbConnector.updateCategory(categories[index]);
            await updateCategories();
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Cancel'),
          onPressed: () async {
            await updateCategories();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
