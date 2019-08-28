class TokenSpan {
  TokenSpan({this.line, this.start, this.length, this.kind});
  final int line;
  final int start;
  final int length;
  final TokenKind kind;
}

enum TokenKind {
  Eof,
  Invalid,
  Identificador,
  LiteralInteiro,
  LiteralReal,
  ReservadaVar,
  ReservadaInteger,
  ReservadaReal,
  ReservadaIf,
  ReservadaThen,
  ReservadaElse,
  ReservadaBegin,
  ReservadaEnd,
  ReservadaWhile,
  ReservadaDo,
  ReservadaWrite,
  ReservadaRead,
  ReservadaProgram,
  ReservadaProcedure,
  SimboloCifra, // $
  SimboloAbreParens, // (
  SimboloFechaParens, // )
  SimboloMultiplicao, // *
  SimboloDivisao, // /
  SimboloMais, // +
  SimboloMenos, // -
  SimboloDiferente, // <>
  SimboloMaiorIgual, // >=
  SimboloMenorIgual, // <=
  SimboloMaiorQue, // >
  SimboloMenorQue, // <
  SimboloDoisPontos, // :
  SimboloAtribuicao, // :=
  SimboloPontoEVirgula, // ;
  SimboloIgual, // =
  SimboloVirgula, // ,
  SimboloPontoFinal, // .
}
