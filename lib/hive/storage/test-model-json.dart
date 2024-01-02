import 'package:hive/hive.dart';

part 'test-model-json.g.dart';

@HiveType(typeId: 1)
class TestModelJson {
  @HiveField(0)
  String logID = "";
  @HiveField(1)
  String data = "";

  TestModelJson();

  factory TestModelJson.fromJson(Map<String, dynamic> json) {
    TestModelJson response = TestModelJson();
    response.logID = json["logId"];
    response.data = json["data"];
    return response;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "logId": logID,
      "data": data,
    };

    return map;
  }
}
