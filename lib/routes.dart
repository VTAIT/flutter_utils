import 'package:flutter/material.dart';
import 'package:flutter_utils/audio/AudioPlayerScreen.dart';
import 'package:flutter_utils/bluetooth-ble/fuelSensorConfigPage.dart';
import 'package:flutter_utils/bluetooth-esc-pos/bluetooth-print-esc-pos.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/configBluetoothPrinterPage.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/print-bluetooth-thermal-after-scan.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/print-bluetooth-thermal.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/scan_screen.dart';
import 'package:flutter_utils/hive/hive_screen.dart';
import 'package:flutter_utils/main.dart';
import 'package:flutter_utils/printer-thermal-network/printer-thermail-network.dart';
import 'package:flutter_utils/socket/screen-socket.dart';
import 'package:flutter_utils/visitory/visitory_screen.dart';
import 'package:flutter_utils/vlc/screen-vlc.dart';
import 'package:flutter_utils/websocket/web-socket-screen.dart';

Map<String, WidgetBuilder> routes = {
  '/': (context) => const MyHomePage(title: 'Home Page'),
  '/Visitory Pattern': (context) => const VisitoryScreen(
        title: "Visitory Pattern",
      ),
  '/AudioPlayer': (context) => const AudioPlayerScreen(
        title: "AudioPlayer",
      ),
  '/Hive': (context) => const HiveScreen(
        title: "Hive",
      ),
  '/WebSocket': (context) => const WebSocketScreen(
        title: "Web Socket",
      ),
  '/BlueTooth Thermal': (context) => const BluetoothThermal(
        title: "BlueTooth Thermal",
      ),
  '/BlueTooth BLE': (context) => FuelSensorConfigPage(),
  '/BlueTooth ESC POS': (context) => const BlueToothPrintESCPOS(
        title: "BlueTooth ESC POS",
      ),
  '/NetWork ESC POS': (context) => const PrinterThermalNetWorkScreen(
        title: "NetWork ESC POS",
      ),
  '/Socket': (context) => const SocketIO(
        title: "Socket",
      ),
  '/VLC': (context) => const ScreenVLC(
        title: "VLC",
      ),
  '/ConfigBluetoothPrinterPage': (context) => ConfigBluetoothPrinterPage(),
  '/BluetoothThermalAfterScan': (context) => const BluetoothThermalAfterScan(
        title: "BlueTooth Thermal After Scan",
      ),
  '/ScanScreen': (context) => const ScanScreen(),
};
