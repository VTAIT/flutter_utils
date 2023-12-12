import 'package:flutter/material.dart';

import 'item.dart';
import 'visitory.dart';

class HandleItem implements Visitory {
  ValueNotifier<int> result = ValueNotifier<int>(0);

  @override
  void visit(Item item) {
    result.value += item.value;
  }
}
