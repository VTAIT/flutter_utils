const String F_SENDER = 'sender';
const String F_MESSAGE = "message";
const String F_RECEIVER = "receiver";
const String F_TYPE = "type";
const String F_RECEIVED = "received";

class Message {
  String? content;
  String? sender;
  String? receiver;
  String? type;
  DateTime? received;

  Message();

  factory Message.fromJson(Map<String, dynamic> json) {
    Message mes = Message();
    mes.content = json[F_MESSAGE];
    mes.sender = json[F_SENDER];
    return mes;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> mes = {};
    mes[F_SENDER] = sender ?? "";
    mes[F_MESSAGE] = content ?? "";
    mes[F_RECEIVER] = receiver ?? "";
    mes[F_TYPE] = type ?? "";
    mes[F_RECEIVED] = received ?? "";
    return mes;
  }
}
