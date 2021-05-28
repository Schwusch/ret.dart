import 'package:ret/sets.dart';
import 'package:ret/types/tokens.dart';
import 'package:ret/util.dart';
import 'package:test/test.dart';

void main() {
  group('strToChars', () {
    test('Convert escaped chars in str to their unescaped versions', () {
      final str =
          strToChars('\\v \\xFF hellow \\u00A3 \\50 there \\cB \\n \\w [\\b]');

      expect(str, equals('\v \xFF hellow \u00A3 \\( there  \n \\w \u0008'));
    });

    test('Escaped chars in regex source remain espaced', () {
      final str = strToChars(r'\\xFF hellow \\u00A3 \\50 there \\cB \\n \\w');

      expect(str,
          equals('\\\\xFF hellow \\\\u00A3 \\\\50 there \\\\cB \\\\n \\\\w'));
    });
  });

  group('tokenizeClass', () {
    group('Class tokens', () {
      final t = tokenizeClass('\\w\\d\$\\s\\]\\B\\W\\D\\S.+-] will ignore', '');

      test('Get a words set token', () {
        expect(t.token[0], equals(words));
      });

      test('Get an integers set token', () {
        expect(t.token[1], equals(ints));
      });

      test('Get some char tokens', () {
        expect(t.token[2], equals(Char(36)));
        expect(t.token[4], equals(Char(93)));
        expect(t.token[5], equals(Char(66)));
      });

      test('Get a whitespace set token', () {
        expect(t.token[3], equals(whitespace));
      });

      test('Get negated sets', () {
        expect(t.token[6], equals(notWords));
        expect(t.token[7], equals(notInts));
        expect(t.token[8], equals(notWhitespace));
      });

      test('Get correct char tokens at end of set', () {
        expect(t.token[9], equals(Char(46)));
        expect(t.token[10], equals(Char(43)));
        expect(t.token[11], equals(Char(45)));
      });

      test('Get correct position of closing brace', () {
        expect(t.end, equals(21));
      });
    });

    group('Ranges', () {
      final t = tokenizeClass('a-z0-9]', '');

      test('Get alphabetic range', () {
        expect(t.token[0], equals(Range(from: 97, to: 122)));
      });

      test('Get numeric range', () {
        expect(t.token[1], equals(Range(from: 48, to: 57)));
      });
    });

    group('Ranges with escaped characters', () {
      final t = tokenizeClass('\\\\-~]', '');

      test('Get escaped backslash range', () {
        expect(t.token[0], equals(Range(from: 92, to: 126)));
      });
    });
  });
}
