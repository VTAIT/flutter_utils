import 'package:hive/hive.dart';
import 'test-model.dart';

class TestRepository {
  String boxName = 'test_db';

  TestRepository();

  Future<Box> openBox() async {
    Box box = await Hive.openBox<TestModel>(boxName);
    return box;
  }

  Future<void> add(Box box, TestModel data) async {
    box.put(data.logID, data);
  }

  Future<void> clear(Box box) async {
    await box.clear();
  }

  List<TestModel> getList(Box box) {
    return box.values.toList() as List<TestModel>;
  }

  TestModel? getId(Box box, dynamic key) {
    return box.get(key);
  }

  Future<void> remove(Box box, TestModel data) async {
    await box.delete(data.logID);
  }
}
