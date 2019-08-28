import 'package:lalg2/lalg2.dart';
import 'package:lalg2/token.dart';
import 'package:test/test.dart';

void testaLexer(String source, List<TokenKind> spans) {
  var lexer = Lexer(source);
  var tokens = List<TokenKind>();
  var span = lexer.next();
  while (span != null) {
    tokens.add(span.kind);
    span = lexer.next();
  }
  expect(tokens.length, spans.length,
      reason: 'lista de tokens com tamanho inesperado');
  for (var i = 0; i < spans.length; i++) {
    expect(tokens[i], spans[i],
        reason: 'tipos de tokens diferentes do esperado');
  }
}

void main() {
  test('nenhum token', () {
    testaLexer('', <TokenKind>[]);
  });

  test('literais inteiros', () {
    testaLexer('0 1 10 1995', <TokenKind>[
      TokenKind.LiteralInteiro,
      TokenKind.LiteralInteiro,
      TokenKind.LiteralInteiro,
      TokenKind.LiteralInteiro,
    ]);
  });

  test('literais reais', () {
    testaLexer('0.0 3.14 100.100 0.3333', <TokenKind>[
      TokenKind.LiteralReal,
      TokenKind.LiteralReal,
      TokenKind.LiteralReal,
      TokenKind.LiteralReal,
    ]);
  });

  test('identificadores', () {
    testaLexer('abc ab3 ig0r', <TokenKind>[
      TokenKind.Identificador,
      TokenKind.Identificador,
      TokenKind.Identificador,
    ]);
  });

  test('comentário de bloco 1', () {
    testaLexer('{bla bla bla }', <TokenKind>[TokenKind.Eof]);
  });

  test('comentário de bloco 2', () {
    testaLexer('/* bla bla bla */', <TokenKind>[TokenKind.Eof]);
  });

  test('comentários dentro de comentário', () {
    testaLexer('{baz/*\nif (true) then false*/ foo }', <TokenKind>[
      TokenKind.Eof,
    ]);
  });

  test('tokens válidos entre comentários 1', () {
    testaLexer('\$ + /* bla bla bla */ - foo', <TokenKind>[
      TokenKind.SimboloCifra,
      TokenKind.SimboloMais,
      TokenKind.SimboloMenos,
      TokenKind.Identificador,
    ]);
  });

  test('tokens válidos entre comentários 2', () {
    testaLexer('100.100 while { bla bla bla } if else', <TokenKind>[
      TokenKind.LiteralReal,
      TokenKind.ReservadaWhile,
      TokenKind.ReservadaIf,
      TokenKind.ReservadaElse,
    ]);
  });

  test('floats inválidos', () {
    testaLexer('1. 0. .1 .0', <TokenKind>[
      TokenKind.Invalid,
      TokenKind.Invalid,
      TokenKind.SimboloPontoFinal,
      TokenKind.LiteralInteiro,
      TokenKind.SimboloPontoFinal,
      TokenKind.LiteralInteiro
    ]);
  });

  test('todos as keywords em uma linha', () {
    testaLexer(
        'program integer procedure var real if then else begin end while do write read',
        <TokenKind>[
          TokenKind.ReservadaProgram,
          TokenKind.ReservadaInteger,
          TokenKind.ReservadaProcedure,
          TokenKind.ReservadaVar,
          TokenKind.ReservadaReal,
          TokenKind.ReservadaIf,
          TokenKind.ReservadaThen,
          TokenKind.ReservadaElse,
          TokenKind.ReservadaBegin,
          TokenKind.ReservadaEnd,
          TokenKind.ReservadaWhile,
          TokenKind.ReservadaDo,
          TokenKind.ReservadaWrite,
          TokenKind.ReservadaRead,
        ]);
  });

  test('todos os símbolos em uma linha', () {
    testaLexer('( ) * / + - <> >= <= > < : := ; , . = \$', <TokenKind>[
      TokenKind.SimboloAbreParens,
      TokenKind.SimboloFechaParens,
      TokenKind.SimboloMultiplicao,
      TokenKind.SimboloDivisao,
      TokenKind.SimboloMais,
      TokenKind.SimboloMenos,
      TokenKind.SimboloDiferente,
      TokenKind.SimboloMaiorIgual,
      TokenKind.SimboloMenorIgual,
      TokenKind.SimboloMaiorQue,
      TokenKind.SimboloMenorQue,
      TokenKind.SimboloDoisPontos,
      TokenKind.SimboloAtribuicao,
      TokenKind.SimboloPontoEVirgula,
      TokenKind.SimboloVirgula,
      TokenKind.SimboloPontoFinal,
      TokenKind.SimboloIgual,
      TokenKind.SimboloCifra,
    ]);
  });
}
