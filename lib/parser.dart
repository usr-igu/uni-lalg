import 'dart:collection';
import 'dart:developer';

import 'package:lalg2/lexer.dart';
import 'package:lalg2/parse_exception.dart';
import 'package:lalg2/table.dart';
import 'package:lalg2/token.dart';

enum _DeclType {
  Variable,
  Parameter,
  Argument,
}

class Parser {
  Lexer _lexer;
  TokenSpan _spanAtual;
  List<TabelaDeSimbolos> _tabelas;
  int _address;

  Queue<Simbolo> _simbolos;

  final String fonte;

  Parser(this.fonte) {
    _lexer = Lexer(fonte);
    _tabelas = List()..add(TabelaDeSimbolos());
    _simbolos = Queue();
    _address = 0;
  }

  void parse() {
    _spanAtual = _lexer.next();
    _programa();
  }

  void isKind(TokenKind kind) {
    if (_spanAtual == null) {
      throw ParseException('fim do arquivo fonte.');
    }
    if (_spanAtual.kind == kind) {
      _spanAtual = _lexer.next();
    } else {
      throw ParseException('token não esperado');
    }
  }

  bool maybeKind(TokenKind kind) {
    if (_spanAtual == null) {
      throw ParseException('fim do arquivo fonte.');
    }
    if (_spanAtual.kind == kind) {
      _spanAtual = _lexer.next();
      return true;
    }
    return false;
  }

  String _textoToken() {
    return fonte.substring(
        _spanAtual.start, _spanAtual.start + _spanAtual.length);
  }

  //// REGRAS ////
  ////////////////
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
      _variaveis(_DeclType.Variable);
      isKind(TokenKind.SimboloDoisPontos);
      final type = _tipoVar();
      while (_simbolos.isNotEmpty) {
        final simbolo = _simbolos.removeFirst()..type = type;
        _tabelas.last.push(simbolo);
      }
      return true;
    }
    return false;
  }

  // <tipo_var> ::= real | integer
  // Ação semântica adicionar tipo da tabela de símbolos.
  String _tipoVar() {
    if (maybeKind(TokenKind.ReservadaReal)) {
      return 'real';
    } else if (maybeKind(TokenKind.ReservadaInteger)) {
      return 'integer';
    }
    throw ParseException('esperava um tipo real ou integer');
  }

  // <variaveis> ::= ident <mais_var>
  // Ação semântica: Adicionar identificadores na tabela de símbolo.
  void _variaveis(_DeclType declType) {
    final id = _textoToken();
    isKind(TokenKind.Identificador);
    // final tabela = _tabelas.last;
    // Adicionar elementos na tabela.
    switch (declType) {
      case _DeclType.Variable:
        final simbolo =
            Simbolo(id: id, category: 'variable', address: _address++);
        _simbolos.add(simbolo);
        break;
      case _DeclType.Argument:
        if (_tabelas.last.find(id) == null) {
          throw ParseException('símbolo não declarado', symbol: id);
        }
        break;
      case _DeclType.Parameter:
        final simbolo =
            Simbolo(id: id, category: 'parameter', address: _address++);
        _simbolos.add(simbolo);
        break;
    }
    _maisVar(declType);
  }

  // <mais_var> ::= , <variaveis> | λ
  void _maisVar(_DeclType declType) {
    if (maybeKind(TokenKind.SimboloVirgula)) {
      _variaveis(declType);
    }
  }

  // <dc_p> ::= procedure ident <parametros> <corpo_p>
  // Ação semântica: Adiciona procedimentos na tabela de símbolos.
  bool _dcP() {
    if (maybeKind(TokenKind.ReservadaProcedure)) {
      final id = _textoToken();
      isKind(TokenKind.Identificador);
      // Tabela de símbolos mãe
      final tabela = _tabelas.last;
      // Gera a tabela do procedimento
      var tabelaProc = TabelaDeSimbolos();
      tabela.push(Simbolo(
          id: id,
          category: 'procedure',
          table: tabelaProc,
          address: _address++));
      // Empilha a tabela de procedimento
      _tabelas.add(tabelaProc);
      _simbolos.clear();
      _parametros();
      _corpoP();
      // Desempilha tabela do procedimento
      _tabelas.removeLast();
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
    _variaveis(_DeclType.Parameter);
    isKind(TokenKind.SimboloDoisPontos);
    final tipo = _tipoVar();
    while (_simbolos.isNotEmpty) {
      final simbolo = _simbolos.removeFirst()..type = tipo;
      _tabelas.last.push(simbolo);
    }
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
  // Ação semântica: Verifica se a quantidade parâmetros não se ultrapassou o limite.
  // Ação semântica: Verifica se a ordem e o tipo do parâmetro estão corretos
  void _argumentos() {
    final ident = _textoToken();
    isKind(TokenKind.Identificador);
    final simbolo = Simbolo(id: ident);
    _simbolos.addFirst(simbolo);
    _maisIdent();
  }

  // <mais_ident> ::= ; <argumentos> | λ
  // Ação semântica: Verifica se ainda tinham parâmetros para serem verificados.
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
      _variaveis(_DeclType.Argument);
      isKind(TokenKind.SimboloFechaParens);
    } else if (maybeKind(TokenKind.ReservadaWrite)) {
      isKind(TokenKind.SimboloAbreParens);
      _variaveis(_DeclType.Argument);
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
      final id = _textoToken();
      var identificador = _tabelas.last.find(id);
      isKind(TokenKind.Identificador);
      if (identificador == null) {
        // Sobe no escopo pai se ele existir
        try {
          final tabelaPai = _tabelas.elementAt(_tabelas.length - 2);
          final identificadorPai = tabelaPai.find(id);
          if (identificadorPai == null) {
            throw ParseException('símbolo não declarado', symbol: id);
          } else {
            identificador = identificadorPai;
          }
        } catch (e) {
          throw ParseException('símbolo não declarado', symbol: id);
        }
      }
      _restoIdent(identificador);
      // Verifica argumentos
      if (identificador.category == "procedure") {
        final parametros = identificador.table.parametros();
        if (_simbolos.length < parametros.length) {
          throw ParseException('falta parâmetros');
        } else if (_simbolos.length > parametros.length) {
          throw ParseException('parâmetros em excesso');
        }
        while (_simbolos.isNotEmpty) {
          final argumento = _simbolos.removeFirst();
          final simbolo = _tabelas.last.find(argumento.id);
          if (simbolo == null) {
            throw ParseException('símbolo não declarado');
          }
          final parametro = parametros.removeLast();
          if (simbolo.type != parametro.type) {
            throw ParseException('tipo errado em chamada de procedimento');
          }
        }
      }
    }
  }

// <restoIdent> ::= := <expressao> | <lista_arg>
  void _restoIdent(Simbolo identificador) {
    if (maybeKind(TokenKind.SimboloAtribuicao)) {
      _expressao();
      while (_simbolos.isNotEmpty) {
        final simbolo = _simbolos.removeFirst();
        if (simbolo.type != identificador.type) {
          throw ParseException('tipos incompatíveis em expressão');
        }
      }
    } else {
      _listaArg();
    }
  }

// <condicao> ::= <expressao> <relacao> <expressao>
  void _condicao() {
    _expressao();
    _relacao();
    _expressao();
    var simbolo = _simbolos.removeFirst();
    if (_simbolos.any((t) => t.type != simbolo.type)) {
      throw ParseException('tipos incompatíveis em relação');
    }
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
  // Ação semântica: Verificar tipos em expressões.
  void _expressao() {
    _termo();
    _outrosTermos();
  }

  // <op_un> ::= + | - | λ
  void _opUn() {
    if (maybeKind(TokenKind.SimboloMais)) {
      return;
    }
    if (maybeKind(TokenKind.SimboloMenos)) {
      return;
    }
  }

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
  // Ação semântica: Verificar tipos em expressões.
  void _termo() {
    _opUn();
    _fator();
    _maisFatores();
  }

  // <mais_fatores>::= <op_mul> <fator> <mais_fatores> | λ
  // Ação semântica: Verificar tipos em expressões.
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
  // Ação semântica: Verificar tipos em expressões.
  void _fator() {
    final id = _textoToken();
    if (maybeKind(TokenKind.Identificador)) {
      final line = _tabelas.last.find(id);
      if (line == null) {
        throw ParseException('símbolo não declarado', symbol: id);
      }
      _simbolos.add(line);
    } else if (maybeKind(TokenKind.LiteralInteiro)) {
      _simbolos
          .add(Simbolo(id: 'literal', type: 'integer', category: 'constant'));
    } else if (maybeKind(TokenKind.LiteralReal)) {
      _simbolos.add(Simbolo(id: 'literal', type: 'real', category: 'constant'));
    } else {
      isKind(TokenKind.SimboloAbreParens);
      _expressao();
      isKind(TokenKind.SimboloFechaParens);
    }
  }
}
