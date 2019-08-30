import 'dart:collection';

import 'package:lalg2/lexer.dart';
import 'package:lalg2/parse_exception.dart';
import 'package:lalg2/table.dart';
import 'package:lalg2/token.dart';
import 'dart:io';

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

  // Geração de código
  List<String> c;

  final String fonte;

  Parser(this.fonte) {
    _lexer = Lexer(fonte);
    _tabelas = List()..add(TabelaDeSimbolos());
    _simbolos = Queue();
    c = List<String>();
    _address = 0;
  }

  void execute() {
    var d = List<double>(32);
    var s = 0;
    var i = 0;
    while (true) {
      final parts = c[i].split(' ');
      final instr = parts[0];
      final data = parts.length > 1 ? double.parse(parts[1]) : null;
      if (instr == 'CRCT') {
        s += 1;
        d[s] = data;
      } else if (instr == 'CRVL') {
        s += 1;
        d[s] = d[data.floor()];
      } else if (instr == 'SOMA') {
        d[s - 1] = d[s - 1] + d[s];
        s -= 1;
      } else if (instr == 'SUBT') {
        d[s - 1] = d[s - 1] - d[s];
        s -= 1;
      } else if (instr == 'MULT') {
        d[s - 1] = d[s - 1] * d[s];
        s -= 1;
      } else if (instr == 'DIVI') {
        d[s - 1] = d[s - 1] / d[s];
        s -= 1;
      } else if (instr == 'INVE') {
        d[s] = -d[s];
      } else if (instr == 'CPME') {
        if (d[s - 1] < d[s]) {
          d[s - 1] = 1;
        } else {
          d[s - 1] = 0;
        }
        s -= 1;
      } else if (instr == 'CPMA') {
        if (d[s - 1] > d[s]) {
          d[s - 1] = 1;
        } else {
          d[s - 1] = 0;
        }
        s -= 1;
      } else if (instr == 'CPIG') {
        if (d[s - 1] == d[s]) {
          d[s - 1] = 1;
        } else {
          d[s - 1] = 0;
        }
        s -= 1;
      } else if (instr == 'CPES') {
        if (d[s - 1] != d[s]) {
          d[s - 1] = 1;
        } else {
          d[s - 1] = 0;
        }
        s -= 1;
      } else if (instr == 'CPMI') {
        if (d[s - 1] <= d[s]) {
          d[s - 1] = 1;
        } else {
          d[s - 1] = 0;
        }
        s -= 1;
      } else if (instr == 'CPMAI') {
        if (d[s - 1] >= d[s]) {
          d[s - 1] = 1;
        } else {
          d[s - 1] = 0;
        }
        s -= 1;
      } else if (instr == 'ARMZ') {
        d[data.floor()] = d[s];
        s -= 1;
      } else if (instr == 'DSVI') {
        i = data.floor();
      } else if (instr == 'DSVF') {
        if (d[s] == 0) {
          i = data.floor();
        }
        s -= 1;
      } else if (instr == 'LEIT') {
        s += 1;
        final valor = stdin.readLineSync();
        final valorDouble = double.parse(valor.trim());
        d[s] = valorDouble;
      } else if (instr == 'IMPR') {
        print(d[s]);
        s -= 1;
      } else if (instr == 'ALME') {
        s += data.floor();
      } else if (instr == 'INPP') {
        s -= 1;
      } else if (instr == 'PARA') {
        return;
      } else if (instr == 'PARAM') {
        s += 1;
        d[s] = d[data.floor()];
      } else if (instr == 'PUSHER') {
        s += 1;
        d[s] = data;
      } else if (instr == 'CHPR') {
        i = data.floor();
      } else if (instr == 'DESM') {
        s -= data.floor();
      } else if (instr == 'RTPR') {
        i -= d[s].floor();
        s -= 1;
      } else {
        throw ParseException('instrução inválida');
      }
      i += 1;
    }
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
      throw ParseException('token não esperado',
          symbol: _spanAtual.kind.toString(), line: _spanAtual.line);
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
    c.add('INPP');
    isKind(TokenKind.ReservadaProgram);
    isKind(TokenKind.Identificador);
    _corpo();
    isKind(TokenKind.SimboloPontoFinal);
    c.add('PARA');
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
        c.add('ALME 1');
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
    // Adicionar elementos na tabela.
    switch (declType) {
      case _DeclType.Variable:
        final simbolo =
            Simbolo(id: id, category: 'variable', address: _address++);
        _simbolos.add(simbolo);
        break;
      case _DeclType.Argument:
        final simbolo = _tabelas.last.find(id);
        if (simbolo == null) {
          throw ParseException('símbolo não declarado', symbol: id);
        }
        _simbolos.add(simbolo);
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
      final procedurePos = c.length;
      final id = _textoToken();
      isKind(TokenKind.Identificador);
      // Tabela de símbolos mãe
      final tabela = _tabelas.last;
      // Gera a tabela do procedimento
      var tabelaProc = TabelaDeSimbolos();
      tabela.push(
        Simbolo(
            id: id,
            category: 'procedure',
            table: tabelaProc,
            address: _address++,
            position: c.length),
      );
      // Empilha a tabela de procedimento
      c.add('DSVI ???');
      _tabelas.add(tabelaProc);
      _simbolos.clear();
      _parametros();
      _corpoP();
      final count =
          _tabelas.last.parametros().length + _tabelas.last.variaveis().length;
      c.add('DESM $count');
      c.add('RTPR');
      c[procedurePos] = 'DSVI ${c.length}';
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
    final simbolo = Simbolo(id: ident, type: 'argument');
    _simbolos.add(simbolo);
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
  bool _pFalsa() {
    if (maybeKind(TokenKind.ReservadaElse)) {
      _comandos();
      return true;
    }
    return false;
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
      while (_simbolos.isNotEmpty) {
        final simbolo = _simbolos.removeFirst();
        c.add('LEIT');
        c.add('ARMZ ${simbolo.address}');
      }
      isKind(TokenKind.SimboloFechaParens);
    } else if (maybeKind(TokenKind.ReservadaWrite)) {
      isKind(TokenKind.SimboloAbreParens);
      _variaveis(_DeclType.Argument);
      while (_simbolos.isNotEmpty) {
        final simbolo = _simbolos.removeFirst();
        c.add('CRVL ${simbolo.address}');
        c.add('IMPR');
      }
      isKind(TokenKind.SimboloFechaParens);
    } else if (maybeKind(TokenKind.ReservadaWhile)) {
      final whilePos = c.length;
      _condicao();
      isKind(TokenKind.ReservadaDo);
      final whileCorpoPos = c.length;
      c.add('DSVF ????'); // Aloca a posição para o endereço
      _comandos();
      c.add('DSVI $whilePos');
      c[whileCorpoPos] = 'DSVF ${c.length}'; // Salva a posteriori o retorno
      isKind(TokenKind.SimboloCifra);
    } else if (maybeKind(TokenKind.ReservadaIf)) {
      _condicao();
      final ifPos = c.length; // Salva a priori o o endereço
      c.add('DSVF ????'); // Aloca a posição para o endereço
      isKind(TokenKind.ReservadaThen);
      _comandos();
      c[ifPos] = 'DSVF ${c.length + 1}';
      final thenElsePos = c.length;
      c.add('DSVI ????');
      _pFalsa();
      c[thenElsePos] = 'DSVI ${c.length}';
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
    }
  }

// <restoIdent> ::= := <expressao> | <lista_arg>
  void _restoIdent(Simbolo identificador) {
    if (maybeKind(TokenKind.SimboloAtribuicao)) {
      _expressao();
      c.add('ARMZ ${identificador.address}');
      while (_simbolos.isNotEmpty) {
        final simbolo = _simbolos.removeFirst();
        if (simbolo.type != identificador.type) {
          throw ParseException('tipos incompatíveis em expressão',
              line: _spanAtual.line);
        }
      }
    } else {
      final procedurePos = c.length;
      c.add('PUSHER');
      _listaArg();

      // Verifica quantidade de argumentos
      final parametros = identificador.table.parametros();
      if (_simbolos.length < parametros.length) {
        throw ParseException('falta parâmetros');
      } else if (_simbolos.length > parametros.length) {
        throw ParseException('parâmetros em excesso');
      }

      // Verifica ordem e tipos
      while (_simbolos.isNotEmpty) {
        final argumento = _simbolos.removeLast();
        final simbolo = _tabelas.last.find(argumento.id);
        if (simbolo == null) {
          throw ParseException('símbolo não declarado');
        }
        final parametro = parametros.removeLast();
        if (simbolo.type != parametro.type) {
          throw ParseException('tipo errado em chamada de procedimento');
        }
        c.add('PARAM ${simbolo.address}');
      }
      c.add('CHPR ${identificador.position + 1}');
      c[procedurePos] = 'PUSHER ${c.length}';
    }
  }

// <condicao> ::= <expressao> <relacao> <expressao>
  void _condicao() {
    _expressao();
    final relacao = _relacao();
    _expressao();
    c.add(relacao);
    var simbolo = _simbolos.removeFirst();
    if (_simbolos.any((t) => t.type != simbolo.type)) {
      throw ParseException('tipos incompatíveis em relação');
    } else {
      _simbolos.clear();
    }
  }

// <relacao>::= = | <> | >= | <= | > | <
  String _relacao() {
    if (maybeKind(TokenKind.SimboloIgual)) {
      return 'CPIG';
    } else if (maybeKind(TokenKind.SimboloDiferente)) {
      return 'CPES';
    } else if (maybeKind(TokenKind.SimboloMaiorIgual)) {
      return 'CMAI';
    } else if (maybeKind(TokenKind.SimboloMenorIgual)) {
      return 'CPMI';
    } else if (maybeKind(TokenKind.SimboloMaiorQue)) {
      return 'CPMA';
    } else {
      isKind(TokenKind.SimboloMenorQue);
      return 'CPME';
    }
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
      c.add('INVE');
      return;
    }
  }

  // <outros_termos> ::= <op_ad> <termo> <outros_termos> | λ
  void _outrosTermos() {
    final opAd = _opAd();
    if (opAd != null) {
      _termo();
      c.add('$opAd');
      _outrosTermos();
    }
  }

  // <op_ad> ::= + | -
  String _opAd() {
    if (maybeKind(TokenKind.SimboloMais)) {
      return 'SOMA';
    } else if (maybeKind(TokenKind.SimboloMenos)) {
      return 'SUBT';
    }
    return null;
  }

  // <termo> ::= <op_un> <fator> <mais_fatores>
  // Ação semântica: Verificar tipos em expressões.
  void _termo() {
    _opUn();
    _fator();
    _maisFatores();
  }

  // <mais_fatores> ::= <op_mul> <fator> <mais_fatores> | λ
  // Ação semântica: Verificar tipos em expressões.
  void _maisFatores() {
    final opMul = _opMul();
    if (opMul != null) {
      _fator();
      c.add('$opMul');
      _maisFatores();
    }
  }

  // <op_mul> ::= * | /
  String _opMul() {
    if (maybeKind(TokenKind.SimboloMultiplicao)) {
      return 'MULT';
    } else if (maybeKind(TokenKind.SimboloDivisao)) {
      return 'DIVI';
    }
    return null;
  }

  // <fator> ::= ident |numero_int |numero_real | (<expressao>)
  // Ação semântica: Verificar tipos em expressões.
  void _fator() {
    final id = _textoToken();
    if (maybeKind(TokenKind.Identificador)) {
      var identificador = _tabelas.last.find(id);
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
      _simbolos.add(identificador);
      c.add('CRVL ${identificador.address}');
    } else if (maybeKind(TokenKind.LiteralInteiro)) {
      _simbolos.add(Simbolo(
          id: 'literal', type: 'integer', category: 'constant', value: id));
      c.add('CRCT $id');
    } else if (maybeKind(TokenKind.LiteralReal)) {
      _simbolos.add(Simbolo(
          id: 'literal', type: 'real', category: 'constant', value: id));
      c.add('CRCT $id');
    } else {
      isKind(TokenKind.SimboloAbreParens);
      _expressao();
      isKind(TokenKind.SimboloFechaParens);
    }
  }
}
