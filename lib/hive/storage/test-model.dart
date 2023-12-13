import 'package:hive/hive.dart';
import 'test-object.dart';

part 'test-model.g.dart';

@HiveType(typeId: 0)
class TestModel {
  @HiveField(0)
  String logID = "";
  @HiveField(1)
  String plateNo = "";
  @HiveField(2)
  bool pending = false;
  @HiveField(3)
  List<TestObject> listObject = [];

  TestModel();

  factory TestModel.fromJson(Map<String, dynamic> json) {
    TestModel response = TestModel();
    response.logID = json["logId"];
    response.plateNo = json["plateNo"];
    response.pending = json["pending"];

    List<TestObject> tempList = [];
    for (var element in json["listObject"]) {
      tempList.add(TestObject.fromJson(element));
    }

    response.listObject = tempList;
    return response;
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> tempList = [];
    for (var element in listObject) {
      tempList.add(element.toJson());
    }
    Map<String, dynamic> map = {
      "logId": logID,
      "plateNo": plateNo,
      "pending": pending,
      "listObject": tempList,
    };

    return map;
  }
}
