import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

const String SENDER = "sender";
const String MESSAGE = "message";
const String NAMEDEFAULT = "serverWs";

class WebSocketHandle {
  String url;
  IOWebSocketChannel? webSocket;
  String content = "";

  Map<String, ValueNotifier<String>> queue = {"mes": ValueNotifier<String>("")};

  final Map<String, String> _bindExchange = {};

  WebSocketHandle({required this.url});

  void connectToServer() {
    if (webSocket != null) {
      return;
    }
    try {
      webSocket = IOWebSocketChannel.connect(url);
      startListener();
    } catch (e) {
      print(e);
    }
  }

  void startListener() {
    if (webSocket == null) {
      print("Web socket not init");
      return;
    }

    webSocket?.stream.listen((message) {
      final Map<String, dynamic> messageData = jsonDecode(message);
      queue["mes"]?.value = message;

      String sender = messageData[SENDER];
      content = messageData[MESSAGE];
      queue[_bindExchange[sender]]?.value = content;
    });
  }

  void bindExchangeDefautl() {
    bindExchange("mes", NAMEDEFAULT);
  }

  void bindExchange(String nameQueue, String nameExchange) {
    _bindExchange[nameExchange] = nameQueue;
  }

  void sendMessage(String mes) {
    webSocket!.sink.add(mes);
  }

  Map<String, ValueNotifier<String>> addQueueListener(String nameQueue) {
    if (!queue.containsKey(nameQueue)) {
      queue[nameQueue] = ValueNotifier<String>("");
    }
    return queue;
  }

  ValueNotifier<String>? getQueueListener(String nameQueue) {
    if (!queue.containsKey(nameQueue)) throw Exception("Not found Queue");
    return queue[nameQueue];
  }

  void diconnect() {
    if (webSocket != null) {
      return;
    }
    webSocket?.sink.add(WebSocketStatus.goingAway);
  }
}
