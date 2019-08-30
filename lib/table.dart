import 'package:lalg2/parse_exception.dart';
import 'package:meta/meta.dart';

class TabelaDeSimbolos {
  List<Simbolo> lines;
  TabelaDeSimbolos() {
    lines = List<Simbolo>();
  }

  void push(Simbolo line) {
    if (lines.any((l) => l.id == line.id && l.category == line.category)) {
      throw ParseException('elemento já declarado');
    }
    lines.add(line);
  }

  Simbolo find(String id) {
    return lines.firstWhere((l) => l.id == id, orElse: () => null);
  }

  List<Simbolo> parametros() {
    return lines.where((t) => t.category == 'parameter').toList();
  }

  List<Simbolo> variaveis() {
    return lines.where((t) => t.category == 'variable').toList();
  }

  void setType(String type) {
    lines.where((t) => t.type == null).forEach((f) => f.type = type);
  }
}

class Simbolo {
  String id;
  String category;
  String type;
  int address;
  int position;
  TabelaDeSimbolos table;
  Simbolo(
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
