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
  List<Tabela> _tabelas;

  final String fonte;

  Parser(this.fonte) {
    _lexer = Lexer(fonte);
    _tabelas = List<Tabela>()..add(Tabela());
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
      throw ParseException('tipos incompatíveis.');
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
      _tipoVar();
      return true;
    }
    return false;
  }

  // <tipo_var> ::= real | integer
  // Ação semântica adicionar tipo da tabela de símbolos.
  bool _tipoVar() {
    final tabela = _tabelas.last;
    if (maybeKind(TokenKind.ReservadaReal)) {
      tabela.setType('real');
      return true;
    } else if (maybeKind(TokenKind.ReservadaInteger)) {
      tabela.setType('integer');
      return true;
    }
    return false;
  }

  // <variaveis> ::= ident <mais_var>
  // Ação semântica: Adicionar identificadores na tabela de símbolo.
  void _variaveis(_DeclType declType) {
    final id = _textoToken();
    final span = _spanAtual;
    isKind(TokenKind.Identificador);
    final tabela = _tabelas.last;
    switch (declType) {
      // Adicionar elementos na tabela.
      case _DeclType.Variable:
        tabela.push(Linha(id: id, span: span, kind: 'variable'));
        break;
      case _DeclType.Argument:
        if (tabela.find(id) == null) {
          throw ParseException('símbolo não declarado', symbol: id);
        }
        break;
      case _DeclType.Parameter:
        tabela.push(Linha(id: id, span: span, kind: 'parameter'));
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
      final span = _spanAtual;
      isKind(TokenKind.Identificador);
      // Tabela de símbolos mãe
      final tabela = _tabelas.last;
      // Gera a tabela do procedimento
      var tabelaProc = Tabela();
      tabela.push(
          Linha(id: id, span: span, kind: 'procedure', table: tabelaProc));
      // Empilha a tabela de procedimento
      _tabelas.add(tabelaProc);
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
  void _listaArg(String id) {
    if (maybeKind(TokenKind.SimboloAbreParens)) {
      _argumentos(id, 0);
      isKind(TokenKind.SimboloFechaParens);
    }
  }

  // <argumentos> ::= ident <mais_ident>
  // Ação semântica: Verifica se a quantidade parâmetros não se ultrapassou o limite.
  // Ação semântica: Verifica se a ordem e o tipo do parâmetro estão corretos
  void _argumentos(String id, int count) {
    isKind(TokenKind.Identificador);
    final proc = _tabelas.last.find(id);
    if (proc.kind == 'procedure') {
      if (count >= proc.table.countParameters()) {
        throw ParseException('parâmetros em excesso');
      }
    }
    _maisIdent(id, count + 1);
  }

  // <mais_ident> ::= ; <argumentos> | λ
  // Ação semântica: Verifica se ainda tinham parâmetros para serem verificados.
  void _maisIdent(String id, int count) {
    if (maybeKind(TokenKind.SimboloPontoEVirgula)) {
      _argumentos(id, count);
    } else {
      final proc = _tabelas.last.find(id);
      if (proc != null) {
        if (proc.kind == 'procedure') {
          if (count < proc.table.countParameters()) {
            throw ParseException('falta parâmetros', symbol: proc.id);
          }
        }
      }
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
      final tabela = _tabelas.last;
      final id = _textoToken();
      final proc = tabela.find(id);
      isKind(TokenKind.Identificador);
      if (proc == null) {
        throw ParseException('símbolo não declarado', symbol: id);
      }
      _restoIdent(id);
    }
  }

// <restoIdent> ::= := <expressao> | <lista_arg>
  void _restoIdent(String id) {
    if (maybeKind(TokenKind.SimboloAtribuicao)) {
      _expressao();
    } else {
      _listaArg(id);
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
