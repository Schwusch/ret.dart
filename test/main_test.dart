import 'package:ret/ret.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Char char(String c) => Char(c.codeUnitAt(0));

List<Char> charStr(String str) => str.split('').map(char).toList();

void main() {
  group('Regexp Tokenizer', () {
    group('No special characters', () {
      final t = tokenizer('walnuts');

      test('List of char tokens', () {
        expect(t, equals(Root(stack: charStr('walnuts'))));
      });
    });

    group('Positionals', () {
      test(r'^ and $ in one liner', () {
        
      });
    });
  });
}
