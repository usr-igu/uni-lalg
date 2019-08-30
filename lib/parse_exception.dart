class ParseException implements Exception {
  String message;
  String symbol;
  int line;
  ParseException(this.message, {this.symbol, this.line});
}
