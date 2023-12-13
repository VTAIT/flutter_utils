import 'package:hive/hive.dart';
part 'test-object.g.dart';

@HiveType(typeId: 1)
class TestObject {
  @HiveField(0)
  int logID = 0;
  @HiveField(1)
  String plateNo = "";
  @HiveField(2)
  bool pending = false;
  @HiveField(3)
  List<int> listInt = [];

  TestObject();

  factory TestObject.fromJson(Map<String, dynamic> json) {
    TestObject response = TestObject();
    response.logID = json["logId"];
    response.plateNo = json["plateNo"];
    response.pending = json["pending"];

    List<int> tempList = [];
    for (var element in json["listInt"]) {
      tempList.add(element);
    }

    response.listInt = tempList;
    return response;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "logId": logID,
      "plateNo": plateNo,
      "pending": pending,
      "listInt": listInt,
    };

    return map;
  }
}
