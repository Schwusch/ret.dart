import 'package:ret/types/tokens.dart';

const _INTS = [Range(from: 48, to: 57)];

const List<SetToken> _WORDS = [
  Char(95),
  Range(from: 97, to: 122),
  Range(from: 65, to: 90),
  Range(from: 48, to: 57),
];

const List<SetToken> _WHITESPACE = [
  Char(9),
  Char(10),
  Char(11),
  Char(12),
  Char(13),
  Char(32),
  Char(160),
  Char(5760),
  Range(from: 8192, to: 8202),
  Char(8232),
  Char(8233),
  Char(8239),
  Char(8287),
  Char(12288),
  Char(65279),
];

const _NOTANYCHAR = [
  Char(10),
  Char(13),
  Char(8232),
  Char(8233),
];

final words = Set(set: _WORDS, not: false);
final notWords = Set(set: _WORDS, not: true);
final ints = Set(set: _INTS, not: false);
final notInts = Set(set: _INTS, not: true);
final whitespace = Set(set: _WHITESPACE, not: false);
final notWhitespace = Set(set: _WHITESPACE, not: true);
final anyChar = Set(set: _NOTANYCHAR, not: true);
