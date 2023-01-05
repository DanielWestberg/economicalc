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
  late Future<List<TransactionCategory>> categoryFuture;
  late List<TransactionCategory> categories;
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
                backgroundColor: Utils.lightColor.withOpacity(0.95),
                appBar: AppBar(
                  backgroundColor: Utils.mediumLightColor,
                  foregroundColor: Utils.textColor,
                  title: Text("Categories", style: TextStyle(fontSize: 30)),
                  centerTitle: true,
                ),
                body: SafeArea(
                    child: Column(children: [
                  Padding(
                      padding: EdgeInsets.only(top: 10, right: 10, left: 10),
                      child: Card(
                        color: Utils.lightColor,
                        child: ListTile(
                            title: Text("Add category"),
                            trailing: IconButton(
                                icon: Icon(Icons.add, color: Colors.green),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        List<TransactionCategory>
                                            categoriesPopUpCategory =
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
                                  color: Utils.lightColor,
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
                                                    child: Text("Delete"),
                                                    onTap: () async {
                                                      await dbConnector
                                                          .deleteCategoryByID(
                                                              categories[index]
                                                                  .id!);
                                                      final snackBar = SnackBar(
                                                        backgroundColor: Utils
                                                            .mediumDarkColor,
                                                        content: Text(
                                                          "Category '${categories[index].description}' was deleted",
                                                          style: TextStyle(
                                                              color: Utils
                                                                  .lightColor),
                                                        ),
                                                      );
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              snackBar);
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
      title: Center(child: Text("Add new category")),
      content: SingleChildScrollView(
          child: Column(children: [
        Text("Enter description:"),
        TextField(onChanged: (value) => setState(() => description = value)),
        Container(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Text("Pick a color:")),
        ColorPicker(
            pickerAreaHeightPercent: 0.4,
            pickerAreaBorderRadius: BorderRadius.circular(10),
            pickerColor: pickerColor,
            onColorChanged: ((pickedColor) => setState(() {
                  pickerColor = pickedColor;
                })))
      ])),
      actions: [
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () async {
            if (description.length == 0) {
              final snackBar = SnackBar(
                backgroundColor: Utils.errorColor,
                content: Text(
                  "Description is empty. Please try again.",
                  style: TextStyle(color: Utils.lightColor),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            } else if (await dbConnector
                    .doesCategoryAlreadyExist(description) ||
                description.toLowerCase() == 'none') {
              final snackBar = SnackBar(
                backgroundColor: Utils.errorColor,
                content: Text(
                  "Category already exist. Please choose a different description.",
                  style: TextStyle(color: Utils.lightColor),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            } else {
              TransactionCategory newCategory = new TransactionCategory(
                  description: description, color: pickerColor);
              await dbConnector.insertCategory(newCategory);
              await updateCategories();
              Navigator.of(context).pop();
              setState(() {});
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
      content: Column(
        children: [
        ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: ((pickerColor) =>
              setState(() => categories[index].color = pickerColor))),
        
        TextField(
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'New category name'
            ),
          onChanged: (value) {
            setState(() => categories[index].description = value);
          },
        )],),
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
