import 'package:ret/sets.dart';
import 'package:ret/types/set-lookup.dart';
import 'package:ret/types/tokens.dart';

SetLookup _setToLookup(List<SetToken> tokens) {
  var lookup = <String, bool>{};

  for (final token in tokens) {
    if (token is Char) {
      lookup[token.value.toString()] = true;
    }

    if (token is Range) {
      lookup['${token.from}-${token.to}'] = true;
    }
  }

  return SetLookup(tokens.length, lookup);
}

final INTS = _setToLookup(ints.set);
final WORDS = _setToLookup(words.set);
final WHITESPACE = _setToLookup(whitespace.set);
final NOTANYCHAR = _setToLookup(anyChar.set);
