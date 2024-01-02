import 'package:flutter_utils/hive/storage/test-model-json.dart';
import 'package:hive/hive.dart';

class TestRepositoryJson {
  String boxName = 'test_db_json';

  TestRepositoryJson();

  Future<Box> openBox() async {
    Box box = await Hive.openBox<TestModelJson>(boxName);
    return box;
  }

  Future<void> add(Box box, TestModelJson data) async {
    box.put(data.logID, data);
  }

  Future<void> clear(Box box) async {
    await box.clear();
  }

  List<TestModelJson> getList(Box box) {
    return box.values.toList() as List<TestModelJson>;
  }

  TestModelJson? getId(Box box, dynamic key) {
    return box.get(key);
  }

  Future<void> remove(Box box, TestModelJson data) async {
    await box.delete(data.logID);
  }
}
