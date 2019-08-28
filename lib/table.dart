import 'package:lalg2/parse_exception.dart';
import 'package:lalg2/token.dart';
import 'package:meta/meta.dart';

class Tabela {
  List<Linha> lines;
  Tabela() {
    lines = List<Linha>();
  }

  void push(Linha line) {
    if (lines.any((l) => l.id == line.id && l.kind == line.kind)) {
      throw ParseException('elemento já declarado');
    }
    lines.add(line);
  }

  Linha find(String id) {
    return lines.firstWhere((l) => l.id == id, orElse: () => null);
  }

  int countParameters() {
    return lines.where((l) => l.kind == 'parameter').length;
  }

  void setType(String type) {
    lines.where((t) => t.type == null).forEach((f) => f.type = type);
  }
}

class Linha {
  String id;
  TokenSpan span;
  String kind;
  String type;
  Tabela table;
  Linha({@required this.id, this.span, this.kind, this.type, this.table}) {
    if (this.kind != 'procedure') {
      assert(this.table == null);
    } else {
      assert(this.type == null);
    }
  }
}
