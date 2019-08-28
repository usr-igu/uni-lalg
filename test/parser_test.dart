import 'package:lalg2/lalg2.dart';
import 'package:lalg2/parse_exception.dart';
import 'package:test/test.dart';

void testaParser(String source) {
  var parser = Parser(source);
  parser.parse();
}

void main() {
  test('fonte vazia', () {
    try {
      testaParser('');
    } on ParseException {
      assert(true);
    }
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
