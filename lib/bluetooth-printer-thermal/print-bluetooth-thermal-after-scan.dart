import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_utils/bluetooth-printer-thermal/global.dart';
import 'package:image/image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/data-printer.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/widget-printer.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:math' as math;

class BluetoothThermalAfterScan extends StatefulWidget {
  const BluetoothThermalAfterScan({super.key, required this.title});
  final String title;
  @override
  State<BluetoothThermalAfterScan> createState() =>
      _BluetoothThermalAfterScanState();
}

class _BluetoothThermalAfterScanState extends State<BluetoothThermalAfterScan> {
  String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  List<String> _options = [
    "permission bluetooth granted",
    "bluetooth enabled",
    "connection status",
    "update info"
  ];

  String _selectSize = "2";
  final _txtText = TextEditingController(text: "Hello developer");
  bool _progress = false;
  String _msjprogress = "";

  String optionprinttype = "58 mm";
  List<String> options = ["48 mm", "58 mm", "80 mm"];

  ScreenshotController controller = ScreenshotController();

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      print("patformversion: $platformVersion");
      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    print("bluetooth enabled: $result");
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    setState(() {
      _info = platformVersion + " ($porcentbatery% battery)";
    });
  }

  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    // final List<BluetoothInfo> listResult =
    //     await PrintBluetoothThermal.pairedBluetooths;
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    /*await Future.forEach(listResult, (BluetoothInfo bluetooth) {
      String name = bluetooth.name;
      String mac = bluetooth.macAdress;
    });*/

    setState(() {
      _progress = false;
    });

    if (listResult.length == 0) {
      _msj =
          "There are no bluetoohs linked, go to settings and link the printer";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);

    print("state conected $result");

    if (result) connected = true;
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

  Future<void> printTest() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      const PaperSize paper = PaperSize.mm58;
      CapabilityProfile profile = await CapabilityProfile.load();

      final Generator generator = Generator(paper, profile);
      final Uint8List buf = await controller
          .captureFromLongWidget(buildCaptainOrder(), pixelRatio: 1);

      final Image image = decodeImage(buf)!;
      List<int> ticket = [];
      // ticket += generator.reset();
      ticket += generator.image(image);
      ticket += generator.feed(2);
      PrintBluetoothThermal.writeBytes(ticket);
    } else {
      //no conectado, reconecte
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, "/ScanScreen").then((value) async {
                  if (printer != null) {
                    await connect(printer!.remoteId.toString());
                  }
                });
              },
              icon: Icon(Icons.bluetooth))
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await connect(printer!.remoteId.toString());
                    },
                    child: Text("Connect"),
                  ),
                  ElevatedButton(
                    onPressed: this.printTest,
                    child: Text("Print"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await disconnect();
                    },
                    child: Text("Disconnect"),
                  ),
                ],
              ),
              Screenshot(child: buildCaptainOrder(), controller: controller)
            ],
          ),
        ),
      ),
    );
  }
}
