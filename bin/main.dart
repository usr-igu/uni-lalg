import 'dart:io';

import 'package:lalg2/lalg2.dart' as lalg2;

main(List<String> arguments) {
  String source = File('entrada.txt').readAsStringSync();
  var parser = lalg2.Parser(source);
  parser.parse();
  var xyz = 0;
}
