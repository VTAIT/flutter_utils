import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'utils/string_utils.dart';

class BluetoothListPage extends StatefulWidget {
  // final FlutterBluePlus bluePlus;
  final Function(BluetoothDevice device)? updateItem;
  const BluetoothListPage({Key? key, this.updateItem}) : super(key: key);

  @override
  State<BluetoothListPage> createState() => _BluetoothListPageState();
}

class _BluetoothListPageState extends State<BluetoothListPage> {
  List<ScanResult> listViewDevice = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    listDevices();
  }

  @override
  void dispose() {
    listViewDevice.clear();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _handleResult() {
    if (mounted) {
      setState(() {
        isScanning = false;
      });
    }

    List<ScanResult> results = FlutterBluePlus.lastScanResults;

    for (ScanResult r in results) {
      String name = nvl(r.device.platformName.toUpperCase());
      // print("_handleResult: ${name}");

      if (name.isNotEmpty) {
        log('${r.device.platformName} found! rssi: ${r.rssi} id: ${r.device.remoteId}');
        listViewDevice.add(r);
      }
    }

    FlutterBluePlus.stopScan();

    // print("_handleResult: ${results.length}");

    if (mounted) setState(() {});
  }

  void listDevices() async {
    // log('Start scan device bluetooth');
    if (isScanning) return;
    setState(() {
      listViewDevice.clear();
      isScanning = true;
    });

    FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 4), androidUsesFineLocation: true)
        .then((value) => _handleResult())
        .onError((error, stackTrace) {
      setState(() {
        isScanning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //log('len: ${listViewDevice.length}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bluetooth'),
        centerTitle: true,
        actions: [
          Visibility(
            visible: (!isScanning),
            child: IconButton(
                onPressed: () {
                  listDevices();
                },
                icon: Icon(Icons.refresh)),
          )
        ],
      ),
      body: isScanning
          ? new Center(
              child: CircularProgressIndicator(),
            )
          : _buildList(context),
    );
  }

  ListView _buildList(BuildContext context) {
    return ListView.builder(
      itemCount: listViewDevice.length,
      itemBuilder: (_, index) {
        ScanResult device = listViewDevice[index];
        log('device: $device');
        return Card(
          child: ListTile(
            title: Text(device.device.name),
            subtitle: Text("${device.device.id}\nRSSI: ${device.rssi}"),
            leading: const Icon(Icons.bluetooth),
            onTap: () {
              widget.updateItem?.call(device.device);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
