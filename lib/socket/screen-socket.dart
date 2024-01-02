import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/widget-printer.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:image/image.dart';
import 'package:tcp_socket_connection/tcp_socket_connection.dart';

class SocketIO extends StatefulWidget {
  const SocketIO({super.key, required this.title});
  final String title;
  @override
  State<SocketIO> createState() => _SocketIOState();
}

class _SocketIOState extends State<SocketIO> {
  TcpSocketConnection socketConnection =
      TcpSocketConnection("192.168.1.253", 9100);
  String message = "";
  StreamSocket streamSocket = StreamSocket();
  int countBill = 1;

  void startConnection() async {
    socketConnection.enableConsolePrint(
        true); //use this to see in the console what's happening
    await socketConnection.connect(5000, messageReceived, attempts: 3);
  }

  void messageReceived(String msg) {
    log(msg);
    // setState(() {
    //   message = msg;
    // });
    // socketConnection.sendMessageEOM("MessageIsReceived :D ", "Haha");
  }

  ScreenshotController controller = ScreenshotController();
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
              children: [
                ElevatedButton(
                  onPressed: () {
                    startConnection();
                    log("Connect");
                  },
                  child: Text("Connect"),
                ),
                ElevatedButton(
                  onPressed: () {
                    socketConnection.disconnect();
                  },
                  child: Text("Disconnect"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Uint8List buf = await controller.captureFromWidget(
                        buildCaptainOrder(countBill: countBill),
                        pixelRatio: 1);
                    final Image image = decodeImage(buf)!;
                    final profile = await CapabilityProfile.load();
                    final generator = Generator(PaperSize.mm80, profile);

                    List<int> bytes = [];
                    bytes += generator.image(image);

                    // bytes += generator.feed(1);
                    bytes += generator.cut();

                    await socketConnection.connect(5000, messageReceived,
                        attempts: 3);

                    if (socketConnection.isConnected()) {
                      socketConnection.sendMessageEOM(
                          bytes.toList().toString(), "\n\r");
                      socketConnection.disconnect();
                      countBill++;
                    }
                  },
                  child: Text("Send"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (socketConnection.isConnected()) {
                      List<int> bytes = [29, 97, 255];
                      socketConnection.sendMessageEOM(
                          bytes.toList().toString(), "\n\r");
                    }
                  },
                  child: Text("Check Status"),
                ),
              ],
            )));
  }
}

class StreamSocket {
  final _socketResponse = StreamController<String>();

  void Function(String) get addResponse => _socketResponse.sink.add;

  Stream<String> get getResponse => _socketResponse.stream;

  void dispose() {
    _socketResponse.close();
  }
}
