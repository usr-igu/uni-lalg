class ParseException implements Exception {
  String message;
  String symbol;
  ParseException(this.message, {this.symbol});
}
