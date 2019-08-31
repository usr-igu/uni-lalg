class LexerException implements Exception {
  String message;
  String symbol;
  int line;
  LexerException(this.message, {this.symbol, this.line});
}
