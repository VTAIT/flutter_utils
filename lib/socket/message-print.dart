import 'dart:convert';

class MessagePrint {
  String tableNo;
  List<int> data;

  MessagePrint(this.tableNo, this.data);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "table": tableNo,
      "data": data,
    };

    return map;
  }

  String encodeJson() {
    return jsonEncode(toJson());
  }
}
