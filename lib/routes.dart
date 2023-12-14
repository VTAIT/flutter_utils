import 'package:flutter/material.dart';
import 'package:flutter_utils/audio/AudioPlayerScreen.dart';
import 'package:flutter_utils/bluetooth-ble/fuelSensorConfigPage.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/bluetooth-print.dart';
import 'package:flutter_utils/hive/hive_screen.dart';
import 'package:flutter_utils/main.dart';
import 'package:flutter_utils/visitory/visitory_screen.dart';
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
  '/BlueTooth Thermal': (context) => const BlueToothPrint(
        title: "BlueTooth Thermal",
      ),
  '/BlueTooth BLE': (context) => FuelSensorConfigPage(),
};
