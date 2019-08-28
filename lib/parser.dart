import 'package:lalg2/lexer.dart';
import 'package:lalg2/parse_exception.dart';
import 'package:lalg2/token.dart';

class Parser {
  Lexer _lexer;
  TokenSpan _current;
  final String source;
  Parser(this.source) {
    _lexer = Lexer(source);
  }

  void parse() {
    _current = _lexer.next();
    _programa();
  }

  void isKind(TokenKind kind) {
    if (_current == null) {
      throw ParseException('Fim do arquivo fonte.');
    }
    if (_current.kind == kind) {
      _current = _lexer.next();
    } else {
      throw ParseException(
          'Esperava o tipo de token $kind porém recebi ${_current.kind} na linha ${_current.line}.');
    }
  }

  bool maybeKind(TokenKind kind) {
    if (_current == null) {
      throw ParseException('Fim do arquivo fonte.');
    }
    if (_current.kind == kind) {
      _current = _lexer.next();
      return true;
    }
    return false;
  }

  //// REGRAS ////
  // <programa> ::= program ident <corpo> .
  void _programa() {
    isKind(TokenKind.ReservadaProgram);
    isKind(TokenKind.Identificador);
    _corpo();
    isKind(TokenKind.SimboloPontoFinal);
  }

  // <corpo> ::= <dc> begin <comandos> end
  void _corpo() {
    _dc();
    isKind(TokenKind.ReservadaBegin);
    _comandos();
    isKind(TokenKind.ReservadaEnd);
  }

  // <dc> ::= <dc_v> <mais_dc> | <dc_p> <mais_dc> | λ
  void _dc() {
    if (_dcV()) {
      _maisDc();
    } else if (_dcP()) {
      _maisDc();
    }
  }

  // <mais_dc> ::= ; <dc> | λ
  void _maisDc() {
    if (maybeKind(TokenKind.SimboloPontoEVirgula)) {
      _dc();
    }
  }

  // <dc_v> ::= var <variaveis> : <tipo_var>
  bool _dcV() {
    if (maybeKind(TokenKind.ReservadaVar)) {
      _variaveis();
      isKind(TokenKind.SimboloDoisPontos);
      _tipoVar();
      return true;
    }
    return false;
  }

  // <tipo_var> ::= real | integer
  bool _tipoVar() {
    return maybeKind(TokenKind.ReservadaReal) ||
        maybeKind(TokenKind.ReservadaInteger);
  }

  // <variaveis> ::= ident <mais_var>
  void _variaveis() {
    isKind(TokenKind.Identificador);
    _maisVar();
  }

  // <mais_var> ::= , <variaveis> | λ
  void _maisVar() {
    if (maybeKind(TokenKind.SimboloVirgula)) {
      _variaveis();
    }
  }

  // <dc_p> ::= procedure ident <parametros> <corpo_p>
  bool _dcP() {
    if (maybeKind(TokenKind.ReservadaProcedure)) {
      isKind(TokenKind.Identificador);
      _parametros();
      _corpoP();
      return true;
    }
    return false;
  }

  // <parametros> ::= ( <lista_par> ) | λ
  void _parametros() {
    if (maybeKind(TokenKind.SimboloAbreParens)) {
      _listaPar();
      isKind(TokenKind.SimboloFechaParens);
    }
  }

  // <lista_par> ::= <variaveis> : <tipo_var> <mais_par>
  void _listaPar() {
    _variaveis();
    isKind(TokenKind.SimboloDoisPontos);
    _tipoVar();
    _maisPar();
  }

  // <mais_par> ::= ; <lista_par> | λ
  void _maisPar() {
    if (maybeKind(TokenKind.SimboloPontoEVirgula)) {
      _listaPar();
    }
  }

  // <corpo_p> ::= <dc_loc> begin <comandos> end
  void _corpoP() {
    _dcLoc();
    isKind(TokenKind.ReservadaBegin);
    _comandos();
    isKind(TokenKind.ReservadaEnd);
  }

  // <dc_loc> ::= <dc_v> <mais_dcloc> | λ
  void _dcLoc() {
    if (_dcV()) {
      _maisDcLoc();
    }
  }

  // <mais_dcloc> ::= ; <dc_loc> | λ
  void _maisDcLoc() {
    if (maybeKind(TokenKind.SimboloPontoEVirgula)) {
      _dcLoc();
    }
  }

  // <lista_arg> ::= ( <argumentos> ) | λ
  void _listaArg() {
    if (maybeKind(TokenKind.SimboloAbreParens)) {
      _argumentos();
      isKind(TokenKind.SimboloFechaParens);
    }
  }

  // <argumentos> ::= ident <mais_ident>
  void _argumentos() {
    isKind(TokenKind.Identificador);
    _maisIdent();
  }

  // <mais_ident> ::= ; <argumentos> | λ
  void _maisIdent() {
    if (maybeKind(TokenKind.SimboloPontoEVirgula)) {
      _argumentos();
    }
  }

  // <pfalsa> ::= else <comandos> | λ
  void _pFalsa() {
    if (maybeKind(TokenKind.ReservadaElse)) {
      _comandos();
    }
  }

  // <comandos> ::= <comando> <mais_comandos>
  void _comandos() {
    _comando();
    _maisComandos();
  }

  // <mais_comandos> ::= ; <comandos> | λ
  void _maisComandos() {
    if (maybeKind(TokenKind.SimboloPontoEVirgula)) {
      _comandos();
    }
  }

  // <comando> ::= read(<variaveis>)
  // | write(<variaveis>)
  // | while <condicao> do <comandos> $
  // | if <condicao> then <comandos> <pfalsa> $
  // | ident <restoIdent>
  void _comando() {
    if (maybeKind(TokenKind.ReservadaRead)) {
      isKind(TokenKind.SimboloAbreParens);
      _variaveis();
      isKind(TokenKind.SimboloFechaParens);
    } else if (maybeKind(TokenKind.ReservadaWrite)) {
      isKind(TokenKind.SimboloAbreParens);
      _variaveis();
      isKind(TokenKind.SimboloFechaParens);
    } else if (maybeKind(TokenKind.ReservadaWhile)) {
      _condicao();
      isKind(TokenKind.ReservadaDo);
      _comandos();
      isKind(TokenKind.SimboloCifra);
    } else if (maybeKind(TokenKind.ReservadaIf)) {
      _condicao();
      isKind(TokenKind.ReservadaThen);
      _comandos();
      _pFalsa();
      isKind(TokenKind.SimboloCifra);
    } else {
      isKind(TokenKind.Identificador);
      _restoIdent();
    }
  }

// <restoIdent> ::= := <expressao> | <lista_arg>
  void _restoIdent() {
    if (maybeKind(TokenKind.SimboloAtribuicao)) {
      _expressao();
    } else {
      _listaArg();
    }
  }

// <condicao> ::= <expressao> <relacao> <expressao>
  void _condicao() {
    _expressao();
    _relacao();
    _expressao();
  }

// <relacao>::= = | <> | >= | <= | > | <
  void _relacao() {
    if (maybeKind(TokenKind.SimboloIgual)) {
      return;
    }
    if (maybeKind(TokenKind.SimboloDiferente)) {
      return;
    }
    if (maybeKind(TokenKind.SimboloMaiorIgual)) {
      return;
    }
    if (maybeKind(TokenKind.SimboloMenorIgual)) {
      return;
    }
    if (maybeKind(TokenKind.SimboloMaiorQue)) {
      return;
    }
    isKind(TokenKind.SimboloMenorQue);
  }

// <expressao> ::= <termo> <outros_termos>
  void _expressao() {
    _termo();
    _outrosTermos();
  }

  // <op_un> ::= + | - | λ
  void _opUn() {}

  // <outros_termos> ::= <op_ad> <termo> <outros_termos> | λ
  void _outrosTermos() {
    if (_opAd()) {
      _termo();
      _outrosTermos();
    }
  }

  // <op_ad> ::= + | -
  bool _opAd() {
    return maybeKind(TokenKind.SimboloMais) ||
        maybeKind(TokenKind.SimboloMenos);
  }

  // <termo> ::= <op_un> <fator> <mais_fatores>
  void _termo() {
    _opUn();
    _fator();
    _maisFatores();
  }

  // <mais_fatores>::= <op_mul> <fator> <mais_fatores> | λ
  void _maisFatores() {
    if (_opMul()) {
      _fator();
      _maisFatores();
    }
  }

  // <op_mul> ::= * | /
  bool _opMul() {
    return maybeKind(TokenKind.SimboloMultiplicao) ||
        maybeKind(TokenKind.SimboloDivisao);
  }

  // <fator> ::= ident |numero_int |numero_real | (<expressao>)
  void _fator() {
    if (maybeKind(TokenKind.Identificador)) {
      return;
    }
    if (maybeKind(TokenKind.LiteralInteiro)) {
      return;
    }
    if (maybeKind(TokenKind.LiteralReal)) {
      return;
    }
    isKind(TokenKind.SimboloAbreParens);
    _expressao();
    isKind(TokenKind.SimboloFechaParens);
  }
}
