import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_utils/hive/storage/test-model-json.dart';
import 'package:flutter_utils/hive/storage/test-respository-json.dart';
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
  TestRepositoryJson db_json = TestRepositoryJson();
  ValueNotifier<List<TestModel>> listView = ValueNotifier<List<TestModel>>([]);
  ValueNotifier<List<TestModelJson>> listViewJson =
      ValueNotifier<List<TestModelJson>>([]);

  void init() async {
    Directory dir = await getApplicationDocumentsDirectory();

    String path = "${dir.path}/db/";
    dir = await Directory(path).create(recursive: true);
    Hive
      ..init(dir.path)
      ..registerAdapter(TestModelAdapter(), override: true)
      ..registerAdapter(TestObjectAdapter(), override: true)
      ..registerAdapter(TestModelJsonAdapter(), override: true);
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

  void showDataJson() async {
    Box box = await db_json.openBox();
    List<TestModelJson> tickets = db_json.getList(box);
    listViewJson.value = tickets;
  }

  void addDataJson() async {
    Box box = await db_json.openBox();
    TestModelJson obj = TestModelJson();
    obj.logID = "$_counter";
    obj.data = {"id": "test Hive Json", "value": 123123}.toString();

    db_json.add(box, obj);
  }

  void deleteDataJson() async {
    Box box = await db_json.openBox();
    List<TestModelJson> tickets = db_json.getList(box);
    if (tickets.isEmpty) return;
    TestModelJson model = tickets.first;
    db_json.remove(box, model);
  }

  void updateDataJson() async {
    Box box = await db_json.openBox();
    TestModelJson obj = TestModelJson();
    obj.logID = "0";
    obj.data = {"id": "123123", "value": "update"}.toString();
    db_json.add(box, obj);
  }

  void clearDataJson() async {
    Box box = await db_json.openBox();
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
                    showDataJson();
                  },
                  child: Text("Show data")),
              ElevatedButton(
                  onPressed: () {
                    addDataJson();
                    _counter++;
                  },
                  child: Text("add data")),
              ElevatedButton(
                  onPressed: () {
                    deleteDataJson();
                  },
                  child: Text("delete data")),
              ElevatedButton(
                  onPressed: () {
                    updateDataJson();
                  },
                  child: Text("update data")),
              ElevatedButton(
                  onPressed: () {
                    clearDataJson();
                  },
                  child: Text("Clear data")),
            ],
          ),
          Expanded(
              child: ValueListenableBuilder(
            valueListenable: listViewJson,
            builder: (BuildContext context, List<TestModelJson> value,
                Widget? child) {
              return ListView.builder(
                  itemCount: listViewJson.value.length,
                  itemBuilder: (BuildContext context, int index) {
                    TestModelJson model = listViewJson.value.elementAt(index);
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

// flutter packages pub run build_runner build
