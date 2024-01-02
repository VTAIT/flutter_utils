import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:image/image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/data-printer.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/widget-printer.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:screenshot/screenshot.dart';

class BluetoothThermal extends StatefulWidget {
  const BluetoothThermal({super.key, required this.title});
  final String title;
  @override
  State<BluetoothThermal> createState() => _BluetoothThermalState();
}

class _BluetoothThermalState extends State<BluetoothThermal> {
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
    initPlatformState();
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
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("state conected $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
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
          .captureFromWidget(buildCaptainOrder(), pixelRatio: 1);
      final Image image = decodeImage(buf)!;
      List<int> ticket = [];
      ticket += generator.image(image);
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      print("print test result:  $result");
    } else {
      //no conectado, reconecte
    }
  }

  Future<void> printWithoutPackage() async {
    //impresion sin paquete solo de PrintBluetoothTermal
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String text = _txtText.text.toString() + "\n";
      bool result = await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: int.parse(_selectSize), text: text));
      print("status print result: $result");
      setState(() {
        _msj = "printed status: $result";
      });
    } else {
      //no conectado, reconecte
      setState(() {
        _msj = "no connected device";
      });
      print("no conectado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: [
          PopupMenuButton(
            elevation: 3.2,
            //initialValue: _options[1],
            onCanceled: () {
              print('You have not chossed anything');
            },
            tooltip: 'Menu',
            onSelected: (Object select) async {
              String sel = select as String;
              if (sel == "permission bluetooth granted") {
                bool status =
                    await PrintBluetoothThermal.isPermissionBluetoothGranted;
                setState(() {
                  _info = "permission bluetooth granted: $status";
                });
                //open setting permision if not granted permision
              } else if (sel == "bluetooth enabled") {
                bool state = await PrintBluetoothThermal.bluetoothEnabled;
                setState(() {
                  _info = "Bluetooth enabled: $state";
                });
              } else if (sel == "update info") {
                initPlatformState();
              } else if (sel == "connection status") {
                final bool result =
                    await PrintBluetoothThermal.connectionStatus;
                setState(() {
                  _info = "connection status: $result";
                });
              }
            },
            itemBuilder: (BuildContext context) {
              return _options.map((String option) {
                return PopupMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('info: $_info\n '),
              Text(_msj),
              Row(
                children: [
                  Text("Type print"),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: optionprinttype,
                    items: options.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        optionprinttype = newValue!;
                      });
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      this.getBluetoots();
                    },
                    child: Row(
                      children: [
                        Visibility(
                          visible: _progress,
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 1, backgroundColor: Colors.white),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(_progress ? _msjprogress : "Search"),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: connected ? this.disconnect : null,
                    child: Text("Disconnect"),
                  ),
                  ElevatedButton(
                    onPressed: connected ? this.printTest : null,
                    child: Text("Test"),
                  ),
                ],
              ),
              Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: ListView.builder(
                    itemCount: items.length > 0 ? items.length : 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          String mac = items[index].macAdress;
                          this.connect(mac);
                        },
                        title: Text('Name: ${items[index].name}'),
                        subtitle: Text("macAddress: ${items[index].macAdress}"),
                      );
                    },
                  )),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey.withOpacity(0.3),
                ),
                child: Column(children: [
                  Text(
                      "Text size without the library without external packets, print images still it should not use a library"),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _txtText,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Text",
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      DropdownButton<String>(
                        hint: Text('Size'),
                        value: _selectSize,
                        items: <String>['1', '2', '3', '4', '5']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: new Text(value),
                          );
                        }).toList(),
                        onChanged: (String? select) {
                          setState(() {
                            _selectSize = select.toString();
                          });
                        },
                      )
                    ],
                  ),
                  ElevatedButton(
                    onPressed: connected ? this.printWithoutPackage : null,
                    child: Text("Print"),
                  ),
                ]),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
