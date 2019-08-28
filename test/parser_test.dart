import 'package:lalg2/lalg2.dart';
import 'package:lalg2/parse_exception.dart';
import 'package:test/test.dart';

void testaParser(String source) {
  var parser = Parser(source);
  parser.parse();
}

void main() {
  test('exemplo básico', () {
    testaParser(r'''program asdf
        var a: integer
        begin
          read(a)
        end.''');
  });

  test('variável redeclarada', () {
    expect(
        () => testaParser(r'''program foo
            var ab: integer;
            var ab: real  
            begin
              read(ab)
            end.'''),
        throwsA(predicate((e) =>
            e is ParseException && e.message == 'elemento já declarado')));
  });

  test('usando argumento não declarado', () {
    expect(
        () => testaParser(r'''program foo
            var ab: integer;
            begin
              read(xx)
            end.'''),
        throwsA(predicate((e) =>
            e is ParseException && e.message == 'símbolo não declarado')));
  });

  test('usando procedimento não declarado', () {
    expect(
        () => testaParser(r'''program foo
            var ab: integer;
            begin
              foo(ab)
            end.'''),
        throwsA(predicate((e) =>
            e is ParseException && e.message == 'símbolo não declarado')));
  });

  test('muitos parâmetros para o procedimento', () {
    expect(
        () => testaParser(r'''program foo
            var ab: integer;
            procedure foo(x: integer; y: real)
            var a: integer
            begin
              a := x + y
            end
            begin
              foo(ab;ab;ab)
            end.'''),
        throwsA(predicate((e) =>
            e is ParseException && e.message == 'parâmetros em excesso')));
  });

  test('poucos parâmetros para o procedimento', () {
    expect(
        () => testaParser(r'''program foo
            var xx: integer;
            procedure baz(x: integer; y: real; z: integer)
            var a: integer
            begin
              a := a + a
            end
            begin
              baz(xx)
            end.'''),
        throwsA(predicate(
            (e) => e is ParseException && e.message == 'falta parâmetros')));
  });

  test('operação com variáveis não declaradas', () {
    expect(
        () => testaParser(r'''program foo
            var ab: integer;
            var bc: integer;
            var cd: integer
            begin
              ab := bc + kk;
            end.'''),
        throwsA(predicate((e) =>
            e is ParseException && e.message == 'símbolo não declarado')));
  });

  test('exemplo sala de aula', () {
    testaParser(r'''program nome2
        /*exe*mplo2*/
        var a, x:real;
        var ab:real;
        var ac:real;
        var abx: integer; 
        var b:integer;
        procedure nomep(x:integer)
        var a,c:integer;
        begin
        read(c,a);
        if a < x + c then
        a:= c+x;
        write(a)
        else c:=a+x
        $
        end
        begin{programa principal}
        read(b);
        nomep(b)
        end.''');
  });

  test('exemplo ava', () {
    testaParser(r'''program teste
        /* declaracao de variaveis */
        var a,b,c: integer;
        var d,e,f: real;
        var g,h : integer;
        
        /* declaracao de procedimentos */
        procedure um (a, g: real; d, c: integer)
          var h, i, j: real;
          var l: integer
        begin
          h := 2.0;
          a := g + 3.4 / h;
          l := c - d * 2;
          if (c+d)>=5 then
            write(a)
          else
            write(l)
          $
        end;
        
        procedure dois (j: integer; k: real; l: integer)
          var cont,quant: integer
        begin
          read(quant);
          while cont <= quant do
             write(cont)
          $;
          l := l + j + cont;
          write(k);
          write(l)
        end
        
        /*  corpo * principal / */
        
        begin
        read(e); {real}
        read(f); {real}
        read(g); {inteiro}
        read(h); { inteiro} 
        d := e/f; {real}
        dois(h;d;c);
        um(f;e;g;h)         {real,real,inteiro,inteiro}
        {aqui termina o programa}
        end.''');
  });
}
