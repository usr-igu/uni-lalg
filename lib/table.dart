import 'dart:collection';

import 'package:lalg2/parse_exception.dart';
import 'package:meta/meta.dart';

class Table {
  List<Symbol> lines;
  Table() {
    lines = List<Symbol>();
  }

  void push(Symbol line) {
    if (lines.any((l) => l.id == line.id && l.category == line.category)) {
      throw ParseException('elemento já declarado');
    }
    lines.add(line);
  }

  Symbol find(String id) {
    return lines.firstWhere((l) => l.id == id, orElse: () => null);
  }

  Queue<Symbol> parameters() {
    return Queue.from(lines.where((t) => t.category == 'parameter'));
  }

  List<Symbol> variables() {
    return lines.where((t) => t.category == 'variable').toList();
  }

  void bindType(String type) {
    lines.where((t) => t.type == null).forEach((f) => f.type = type);
  }
}

class Symbol {
  String id;
  String category;
  String type;
  int address;
  int position;
  Table table;
  Symbol(
      {@required this.id,
      this.category,
      this.type,
      this.table,
      this.address,
      this.position}) {
    if (this.category != 'procedure') {
      assert(this.table == null);
    } else {
      assert(this.type == null);
    }
  }
}
