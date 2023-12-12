import 'bean.dart';
import 'visitory.dart';

class Item implements Bean {
  int value = 0;
  Item(this.value);

  @override
  void visit(Visitory visitory) {
    visitory.visit(this);
  }
}
