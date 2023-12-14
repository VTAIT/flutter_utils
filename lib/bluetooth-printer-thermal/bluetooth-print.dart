import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import 'widget-printer.dart';

class BlueToothPrint extends StatefulWidget {
  const BlueToothPrint({super.key, required this.title});
  final String title;
  @override
  State<BlueToothPrint> createState() => _BlueToothPrintState();
}

class _BlueToothPrintState extends State<BlueToothPrint> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';
  Uint8List? bytes;
  ScreenshotController controller = ScreenshotController();

  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected ?? false;

    bluetoothPrint.state.listen((state) {
      print('******************* cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            bluetoothPrint.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(tips),
                  ),
                ],
              ),
              Divider(),
              StreamBuilder<List<BluetoothDevice>>(
                stream: bluetoothPrint.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                            title: Text(d.name ?? ''),
                            subtitle: Text(d.address ?? ''),
                            onTap: () async {
                              setState(() {
                                _device = d;
                              });
                            },
                            trailing:
                                _device != null && _device!.address == d.address
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                          ))
                      .toList(),
                ),
              ),
              Divider(),
              Container(
                padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlinedButton(
                          child: Text('connect'),
                          onPressed: _connected
                              ? null
                              : () async {
                                  if (_device != null &&
                                      _device!.address != null) {
                                    setState(() {
                                      tips = 'connecting...';
                                    });
                                    await bluetoothPrint.connect(_device!);
                                  } else {
                                    setState(() {
                                      tips = 'please select device';
                                    });
                                    print('please select device');
                                  }
                                },
                        ),
                        SizedBox(width: 10.0),
                        OutlinedButton(
                          child: Text('disconnect'),
                          onPressed: _connected
                              ? () async {
                                  setState(() {
                                    tips = 'disconnecting...';
                                  });
                                  await bluetoothPrint.disconnect();
                                }
                              : null,
                        ),
                      ],
                    ),
                    Divider(),
                    Screenshot(
                      controller: controller,
                      child: buildTicketKitchen(),
                    ),
                    OutlinedButton(
                      child: Text('print receipt(esc)'),
                      onPressed: _connected
                          ? () async {
                              Map<String, dynamic> config = Map();

                              List<LineText> list = [];

                              final data = await controller.capture();
                              String base64String = base64Encode(data!);
                              String base64Image = base64String;
                              list.add(LineText(
                                  type: LineText.TYPE_IMAGE,
                                  content: base64Image,
                                  align: LineText.ALIGN_CENTER,
                                  width: 380,
                                  // height: 200,
                                  linefeed: 1));
                              await bluetoothPrint.printReceipt(config, list);
                            }
                          : null,
                    ),
                    OutlinedButton(
                      child: Text('print receipt(esc) no render'),
                      onPressed: _connected
                          ? () async {
                              controller
                                  .captureFromWidget(Container(
                                      padding: const EdgeInsets.all(30.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blueAccent,
                                            width: 5.0),
                                        color: Colors.redAccent,
                                      ),
                                      child:
                                          Text("This is an invisible widget")))
                                  .then((capturedImage) async {
                                Map<String, dynamic> config = Map();

                                List<LineText> list = [];

                                final data = await controller.capture();
                                String base64String = base64Encode(data!);
                                String base64Image = base64String;
                                list.add(LineText(
                                    type: LineText.TYPE_IMAGE,
                                    content: base64Image,
                                    align: LineText.ALIGN_CENTER,
                                    width: 380,
                                    // height: 200,
                                    linefeed: 1));
                                await bluetoothPrint.printReceipt(config, list);
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bluetoothPrint.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data == true) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => bluetoothPrint.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () =>
                    bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}
