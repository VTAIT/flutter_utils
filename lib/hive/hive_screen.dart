import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'storage/test-model.dart';
import 'storage/test-object.dart';
import 'package:path_provider/path_provider.dart';
import 'storage/test-respository.dart';
import 'package:hive/hive.dart';

class HiveScreen extends StatefulWidget {
  const HiveScreen({super.key, required this.title});
  final String title;
  @override
  State<HiveScreen> createState() => _HiveScreenState();
}

class _HiveScreenState extends State<HiveScreen> {
  int _counter = 0;
  TestRepository db = TestRepository();
  ValueNotifier<List<TestModel>> listView = ValueNotifier<List<TestModel>>([]);

  void init() async {
    Directory dir = await getApplicationDocumentsDirectory();

    String path = "${dir.path}/db/";
    dir = await Directory(path).create(recursive: true);
    Hive
      ..init(dir.path)
      ..registerAdapter(TestModelAdapter(), override: true)
      ..registerAdapter(TestObjectAdapter(), override: true);
  }

  void showData() async {
    Box box = await db.openBox();
    List<TestModel> tickets = db.getList(box);
    listView.value = tickets;
  }

  void addData() async {
    Box box = await db.openBox();

    TestObject obj = TestObject();
    obj.logID = _counter;
    obj.pending = false;
    obj.listInt = [4, 5, 7, 3, 2, 234782347832478];

    TestModel model = TestModel();
    model.logID = "${_counter}_$_counter";
    model.plateNo = "019132";
    model.pending = true;
    model.listObject = [obj, obj];

    db.add(box, model);
  }

  void deleteData() async {
    Box box = await db.openBox();
    List<TestModel> tickets = db.getList(box);
    if (tickets.isEmpty) return;
    TestModel model = tickets.first;
    db.remove(box, model);
  }

  void updateData() async {
    Box box = await db.openBox();
    TestObject obj = TestObject();
    obj.logID = 0;
    obj.pending = false;
    obj.listInt = [4, 5, 7, 3, 2, 3920];

    TestModel? model = db.getId(box, 0);
    if (model == null) return;
    log(model.toJson().toString());
    model.pending = true;
    model.listObject.add(obj);
    db.add(box, model);
  }

  void clearData() async {
    Box box = await db.openBox();
    box.clear();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                  onPressed: () {
                    showData();
                  },
                  child: Text("Show data")),
              ElevatedButton(
                  onPressed: () {
                    addData();
                    _counter++;
                  },
                  child: Text("add data")),
              ElevatedButton(
                  onPressed: () {
                    deleteData();
                  },
                  child: Text("delete data")),
              ElevatedButton(
                  onPressed: () {
                    updateData();
                  },
                  child: Text("update data")),
              ElevatedButton(
                  onPressed: () {
                    clearData();
                  },
                  child: Text("Clear data")),
            ],
          ),
          Expanded(
              child: ValueListenableBuilder(
            valueListenable: listView,
            builder:
                (BuildContext context, List<TestModel> value, Widget? child) {
              return ListView.builder(
                  itemCount: listView.value.length,
                  itemBuilder: (BuildContext context, int index) {
                    TestModel model = listView.value.elementAt(index);
                    return Container(
                        color: index % 2 == 0 ? Colors.grey : Colors.white,
                        child: Text(model.toJson().toString()));
                  });
            },
          ))
        ],
      ),
    );
  }
}
