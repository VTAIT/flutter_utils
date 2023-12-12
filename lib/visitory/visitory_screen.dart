import 'package:flutter/material.dart';

import 'handleItem.dart';
import 'item.dart';

class VisitoryScreen extends StatefulWidget {
  const VisitoryScreen({super.key, required this.title});
  final String title;

  @override
  State<VisitoryScreen> createState() => _VisitoryScreenState();
}

class _VisitoryScreenState extends State<VisitoryScreen> {
  List<Item> list = [];
  HandleItem handleItem = HandleItem();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Value:',
            ),
            ValueListenableBuilder<int>(
              valueListenable: handleItem.result,
              builder: (BuildContext context, int value, Widget? child) {
                return Text(
                  '${handleItem.result.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            ElevatedButton(
                onPressed: () {
                  list.add(Item(10));
                  handleItem.result.value = 0;
                  list.forEach((element) {
                    element.visit(handleItem);
                  });
                },
                child: Text("Add 10")),
            ElevatedButton(
                onPressed: () {
                  handleItem.result.value = 0;
                  list.forEach((element) {
                    element.visit(handleItem);
                  });
                },
                child: Text("Caculator")),
            ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: Text("Show Value")),
          ],
        ),
      ),
    );
  }
}
