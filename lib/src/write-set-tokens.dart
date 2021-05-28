import './sets-lookup.dart';
import './types/set-lookup.dart';

import './types/tokens.dart';

/// Takes character code and returns character to be displayed in a set
/// @param charCode Character code of set element
/// @returns The string for the sets character
String setChar(int charCode) => charCode == 94
    ? '\\^'
    : charCode == 92
        ? '\\\\'
        : charCode == 93
            ? '\\]'
            : charCode == 45
                ? '\\-'
                : String.fromCharCode(charCode);

/// Test if a character set matches a 'set-lookup'
/// @param set The set to be tested
/// @param param The predefined 'set-lookup' & the number of elements in the lookup
/// @returns true if the character set corresponds to the 'set-lookup'
bool _isSameSet(List<SetToken> set, SetLookup setLookup) {
  if (setLookup.len != set.length) {
    return false;
  }
  final map = {...setLookup.lookup};
  for (final elem in set) {
    if (elem is Set) {
      return false;
    }

    String? key;
    if (elem is Char) {
      key = elem.value.toString();
    } else if (elem is Range) {
      key = '${elem.from}-${elem.to}';
    }

    if (map[key] == true) {
      map[key!] = false;
    } else {
      return false;
    }
  }
  return true;
}

/// Writes a token within a set
/// @param set The set token to display
/// @returns {string} The token as a string
String _writeSetToken(SetToken set) {
  if (set is Char) {
    return setChar(set.value);
  } else if (set is Range) {
    return '${setChar(set.from)}-${setChar(set.to)}';
  }
  return writeSetTokens(set as Set, true);
}

/// Writes the tokens for a set
/// @param set The set to display
/// @param isNested Whether the token is nested inside another set token
/// @returns The tokens for the set
String writeSetTokens(Set set, [bool isNested = false]) {
  if (_isSameSet(set.set, INTS)) {
    return set.not ? '\\D' : '\\d';
  }
  if (_isSameSet(set.set, WORDS)) {
    return set.not ? '\\W' : '\\w';
  }
  if (set.not && _isSameSet(set.set, NOTANYCHAR)) {
    return '.';
  }
  if (_isSameSet(set.set, WHITESPACE)) {
    return set.not ? '\\S' : '\\s';
  }
  var tokenString = '';
  for (var i = 0; i < set.set.length; i++) {
    final subset = set.set[i];
    tokenString += _writeSetToken(subset);
  }
  final contents = '${set.not ? '^' : ''}$tokenString';
  return isNested ? contents : '[$contents]';
}
