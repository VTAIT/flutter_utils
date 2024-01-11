import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/global.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../bluetooth-ble/utils/string_utils.dart';
import '../bluetooth-ble/screens/device_screen.dart';
import '../bluetooth-ble/utils/snackbar.dart';
import '../bluetooth-ble/widgets/connected_device_tile.dart';
import '../bluetooth-ble/widgets/scan_result_tile.dart';
// import '../utils/extra.dart';

class ScanScreen extends StatefulWidget {
  final Function(BluetoothDevice device)? updateItem;
  const ScanScreen({Key? key, this.updateItem}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      setState(() {});
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      setState(() {});
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });

    onScanPressed();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      int divisor = Platform.isAndroid ? 8 : 1;
      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5),
          continuousUpdates: true,
          continuousDivisor: divisor);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false);
    }
    setState(() {}); // force refresh of systemDevices
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
          success: false);
    }
  }

  // Chọn máy in
  void onConnectPressed(BluetoothDevice device) {
    PrintBluetoothThermal.connect(macPrinterAddress: device.remoteId.toString())
        .then((result) {
      if (result) {
        printer = device;
        Navigator.of(context).pop();
        return Future.delayed(Duration(milliseconds: 500));
      }
      Snackbar.show(
          ABC.b, prettyException("Connect Error:", "Không kết nối được máy in"),
          success: false);
    });
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    setState(() {});
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(
          child: const Text("SCAN"), onPressed: onScanPressed);
    }
  }

  List<Widget> _buildConnectedDeviceTiles(BuildContext context) {
    return _connectedDevices
        .map(
          (d) => ConnectedDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: d),
                settings: RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    List<Widget> results = [];
    String printerId = printer?.remoteId.toString() ?? "";
    if (printerId.isNotEmpty) {
      results.add(ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: Colors.lightBlue,
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              printer!.platformName,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              printerId,
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
        trailing: ElevatedButton(
            child: const Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final bool status = await PrintBluetoothThermal.disconnect;
              if (status) {
                printer = null;
                setState(() {
                  _buildScanResultTiles(context);
                });
              }
            }),
      ));
    }

    for (ScanResult r in _scanResults) {
      String name = nvl(r.device.platformName.toUpperCase());
      String id = r.device.remoteId.toString();
      if (name.isNotEmpty) {
        // log('${r.device.platformName} found! rssi: ${r.rssi} id: ${r.device.remoteId}');
        results.add(ListTile(
          leading: Icon(
            Icons.bluetooth,
            color: Colors.grey,
          ),
          title: name.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      id,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  ],
                )
              : Text(id),
          trailing: ElevatedButton(
              child: const Text('CONNECT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                onConnectPressed(r.device);
              }),
        ));
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Scan Bluetooth'),
          actions: [
            Visibility(
              visible: !FlutterBluePlus.isScanningNow,
              child: IconButton(
                  onPressed: () {
                    onScanPressed();
                  },
                  icon: Icon(Icons.refresh)),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        // floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
