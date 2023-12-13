import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'web-socket-handle.dart';

class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({super.key, required this.title});
  final String title;
  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  WebSocketHandle ws =
      WebSocketHandle(url: 'ws://192.168.1.75:8081/product/ws/chat-voice');
  TextEditingController controller = TextEditingController();
  ValueNotifier<List<String>> listView = ValueNotifier<List<String>>([]);
  void sendMes() async {
    ws.sendMessage(jsonEncode({
      "message": controller.text,
      "sender": "An",
      "receiver": "server",
      "type": "public",
      "received": "received"
    }));
  }

  @override
  void initState() {
    super.initState();
    ws.connectToServer();
    // ws.addQueueListener("Driver");
    // ws.bindExchange("Driver", "Server");

    ws.getQueueListener("mes")?.addListener(() {
      listView.value = List.from(listView.value)
        ..add(ws.getQueueListener("mes")!.value);
    });
  }

  @override
  void dispose() {
    ws.diconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            ValueListenableBuilder(
              valueListenable: listView,
              builder:
                  (BuildContext context, List<String> value, Widget? child) {
                return Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: listView.value.length,
                      itemBuilder: (BuildContext context, int index) {
                        String mes = listView.value.elementAt(index);
                        return Container(
                            color: index % 2 == 0 ? Colors.grey : Colors.white,
                            child: Text(mes));
                      }),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      sendMes();
                    },
                    icon: const Icon(Icons.send))
              ],
            )
          ],
        ),
      ),
    );
  }
}
