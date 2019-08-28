import 'package:lalg2/table_exception.dart';
import 'package:lalg2/token.dart';

class Table {
  List<Line> lines;
  void push(Line line) {
    if (lines.any((l) => l.id == line.id)) {
      throw TableException('Elemento já existe na tabela.');
    }
    lines.add(line);
  }

  Line find(String id) {
    return lines.singleWhere((l) => l.id == id, orElse: () => null);
  }
}

class Line {
  final String id;
  final TokenSpan span;

  Line(this.id, this.span);
}
