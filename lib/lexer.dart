import 'package:lalg2/token.dart';

enum _Estado {
  Invalido,
  Comeco,
  Identificador,
  LiteralInteiro,
  LiteralReal,
  MeioReal,
  DoisPontos,
  MenorQue,
  MaiorQue,
  Divisao,
  InicioComentarioBloco,
  InicioComentarioBloco2,
  FimComentarioBloco2,
}
final _LETRAS = 'abcdefghijklmnopqrstuvwxyz';
final _NUMEROS = '0123456789';
final _RESERVADAS = {
  "program": TokenKind.ReservadaProgram,
  "integer": TokenKind.ReservadaInteger,
  "procedure": TokenKind.ReservadaProcedure,
  "var": TokenKind.ReservadaVar,
  "real": TokenKind.ReservadaReal,
  "if": TokenKind.ReservadaIf,
  "then": TokenKind.ReservadaThen,
  "else": TokenKind.ReservadaElse,
  "begin": TokenKind.ReservadaBegin,
  "end": TokenKind.ReservadaEnd,
  "while": TokenKind.ReservadaWhile,
  "do": TokenKind.ReservadaDo,
  "write": TokenKind.ReservadaWrite,
  "read": TokenKind.ReservadaRead,
};

class Lexer {
  final String source;
  Lexer(this.source);

  int _line = 0;
  int _position = 0;

  TokenSpan next() {
    if (_position >= source.length) {
      return null;
    }

    TokenKind kind = TokenKind.Eof;
    int start = _position;

    var state = _Estado.Comeco;
    loop:
    while (_position < source.length) {
      final c = source[_position].toLowerCase();
      switch (state) {
        case _Estado.Comeco:
          if ([' ', '\n', '\t'].contains(c)) {
            start = _position + 1;
            if (c == '\n') {
              this._line++;
            }
            break;
          }
          if (_LETRAS.contains(c)) {
            state = _Estado.Identificador;
            kind = TokenKind.Identificador;
            break;
          }
          if (_NUMEROS.contains(c)) {
            state = _Estado.LiteralInteiro;
            kind = TokenKind.LiteralInteiro;
            break;
          }
          if (c == '(') {
            kind = TokenKind.SimboloAbreParens;
            _position++;
            break loop;
          }
          if (c == ')') {
            kind = TokenKind.SimboloFechaParens;
            _position++;
            break loop;
          }
          if (c == ',') {
            kind = TokenKind.SimboloVirgula;
            _position++;
            break loop;
          }
          if (c == ':') {
            state = _Estado.DoisPontos;
            kind = TokenKind.SimboloDoisPontos;
            break;
          }
          if (c == ';') {
            kind = TokenKind.SimboloPontoEVirgula;
            _position++;
            break loop;
          }
          if (c == '+') {
            kind = TokenKind.SimboloMais;
            _position++;
            break loop;
          }
          if (c == '-') {
            kind = TokenKind.SimboloMenos;
            _position++;
            break loop;
          }
          if (c == '*') {
            kind = TokenKind.SimboloMultiplicao;
            _position++;
            break loop;
          }
          if (c == '.') {
            kind = TokenKind.SimboloPontoFinal;
            _position++;
            break loop;
          }
          if (c == '<') {
            state = _Estado.MenorQue;
            kind = TokenKind.SimboloMenorQue;
            break;
          }
          if (c == '>') {
            state = _Estado.MaiorQue;
            kind = TokenKind.SimboloMaiorQue;
            break;
          }
          if (c == '\$') {
            kind = TokenKind.SimboloCifra;
            _position++;
            break loop;
          }
          if (c == '=') {
            kind = TokenKind.SimboloIgual;
            _position++;
            break loop;
          }
          if (c == '{') {
            state = _Estado.InicioComentarioBloco;
            break;
          }
          if (c == '/') {
            state = _Estado.Divisao;
            break;
          }
          break;
        case _Estado.Identificador:
          if (_LETRAS.contains(c) || _NUMEROS.contains(c)) {
            break;
          }
          break loop;
        case _Estado.LiteralInteiro:
          if (_NUMEROS.contains(c)) {
            break;
          } else if (c == '.') {
            state = _Estado.MeioReal;
          } else {
            break loop;
          }
          break;
        case _Estado.MeioReal:
          if (_NUMEROS.contains(c)) {
            state = _Estado.LiteralReal;
            kind = TokenKind.LiteralReal;
            break;
          }
          state = _Estado.Invalido;
          break;
        case _Estado.LiteralReal:
          if (_NUMEROS.contains(c)) {
            break;
          }
          break loop;
        case _Estado.DoisPontos:
          if (c == '=') {
            kind = TokenKind.SimboloAtribuicao;
            _position++;
          }
          break loop;
        case _Estado.MenorQue:
          if (c == '=') {
            kind = TokenKind.SimboloMenorIgual;
            _position++;
          } else if (c == '>') {
            kind = TokenKind.SimboloDiferente;
            _position++;
          }
          break loop;
        case _Estado.MaiorQue:
          if (c == '=') {
            kind = TokenKind.SimboloMaiorIgual;
            _position++;
          }
          break loop;
        case _Estado.Divisao:
          if (c == '*') {
            state = _Estado.InicioComentarioBloco2;
            break;
          }
          kind = TokenKind.SimboloDivisao;
          break loop;
        case _Estado.InicioComentarioBloco:
          if (c == '}') {
            state = _Estado.Comeco;
          }
          break;
        case _Estado.InicioComentarioBloco2:
          if (c == '*') {
            state = _Estado.FimComentarioBloco2;
          }
          break;
        case _Estado.FimComentarioBloco2:
          if (c == '/') {
            state = _Estado.Comeco;
            break;
          }
          state = _Estado.InicioComentarioBloco2;
          break;
        case _Estado.Invalido:
          kind = TokenKind.Invalid;
          break loop;
      }
      _position++;
    }
    if (kind == TokenKind.Identificador) {
      final keyword = source.substring(start, _position);
      if (_RESERVADAS.containsKey(keyword)) {
        kind = _RESERVADAS[keyword];
      }
    }
    return TokenSpan(
      line: _line,
      start: start,
      length: _position - start,
      kind: kind,
    );
  }
}
