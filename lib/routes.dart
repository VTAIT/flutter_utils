import 'package:flutter/material.dart';
import 'package:flutter_utils/audio/AudioPlayerScreen.dart';
import 'package:flutter_utils/main.dart';
import 'package:flutter_utils/visitory/visitory_screen.dart';

Map<String, WidgetBuilder> routes = {
  '/': (context) => const MyHomePage(title: 'Home Page'),
  '/Visitory': (context) => const VisitoryScreen(
        title: "Visitory Pattern",
      ),
  '/AudioPlayer': (context) => const AudioPlayerScreen(
        title: "AudioPlayer",
      ),
};
