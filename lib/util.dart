import 'package:ret/sets.dart';

import 'types/tokens.dart';

const CTRL = '@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^ ?';

/// Finds character representations in str and convert all to
/// their respective characters.
String strToChars(String str) {
  final charsRegex = RegExp(
      r'(\[\\b\])|(\\)?\\(?:u([A-F0-9]{4})|x([A-F0-9]{2})|(0?[0-7]{2})|c([@A-Z[\\\]^?])|([0tnvfr]))');

  return str.replaceAllMapped(charsRegex, (match) {
    final s = match.group(0);
    final b = match.group(1);
    final lbs = match.group(2);
    final a16 = match.group(3);
    final b16 = match.group(4);
    final c8 = match.group(5);
    final dctrl = match.group(6);
    final eslsh = match.group(7);

    if (lbs != null) return s!;

    final code = b != null
        ? 8
        : a16 != null
            ? int.parse(a16, radix: 16)
            : b16 != null
                ? int.parse(b16, radix: 16)
                : c8 != null
                    ? int.parse(c8, radix: 8)
                    : dctrl != null
                        ? CTRL.indexOf(dctrl)
                        : {
                            '0': 0,
                            't': 9,
                            'n': 10,
                            'v': 11,
                            'f': 12,
                            'r': 13,
                          }[eslsh];

    final c = String.fromCharCode(code!);
    return RegExp(r'[[\]{}^$.|?*+()]').hasMatch(c) ? '\\$c' : c;
  });
}

class ClassTokenized {
  final List<SetToken> token;
  final int end;

  ClassTokenized(this.token, this.end);
}

/// Turns class into tokens
/// reads str until it encounters a ] not preceeded by a \
ClassTokenized tokenizeClass(String str, String regexpStr) {
  final tokens = <SetToken>[];
  String? c;

  final regexp = RegExp(
      r'\\(?:(w)|(d)|(s)|(W)|(D)|(S))|((?:(?:\\)(.)|([^\]\\]))-(((?:\\)])|(((?:\\)?([^\]])))))|(\])|(?:\\)?([^])');

  for (final match in regexp.allMatches(str)) {
    SetToken? p;
    if (match.group(1) != null) {
      p = words;
    } else if (match.group(2) != null) {
      p = ints;
    } else if (match.group(3) != null) {
      p = whitespace;
    } else if (match.group(4) != null) {
      p = notWords;
    } else if (match.group(5) != null) {
      p = notInts;
    } else if (match.group(6) != null) {
      p = notWhitespace;
    } else if (match.group(7) != null) {
      p = Range(
        from: (match.group(8) ?? match.group(9))!.codeUnitAt(0),
        to: (c = match.group(10)!).codeUnitAt(c.length - 1),
      );
    } else if ((c = match.group(16)) != null) {
      p = Char(c!.codeUnitAt(0));
    }

    if (p != null) {
      tokens.add(p);
    } else {
      return ClassTokenized(tokens, match.end);
    }
  }

  throw Exception(
      'Invalid regular expression: "$regexpStr": Unterminated character class');
}
