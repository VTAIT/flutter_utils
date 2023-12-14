import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TabWidget extends StatefulWidget {
  final Icon icon;
  final String title;
  final String? moduleName;
  final String moduleRight;
  String tabName = "";

  TabWidget(this.icon, this.title,
      {Key? key, this.moduleName = "", this.moduleRight = "S"})
      : super(key: key);

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
