import './write-set-tokens.dart';
import './types/tokens.dart';

String _reduceStack(List<Token> stack) => stack.map<String>(reconstruct).join();

String createAlternate(RootOrGroup token) {
  if (token.options != null) {
    return token.options!.map(_reduceStack).join('|');
  } else if (token.stack != null) {
    return _reduceStack(token.stack!);
  } else {
    throw Exception('options or stack must not be null');
  }
}

String reconstruct(Tokens token) {
  switch (token.type) {
    case Types.ROOT:
      token as Root;
      return createAlternate(token);
    case Types.GROUP:
      token as Group;
      final prefix = token.remember
          ? ''
          : token.followedBy ?? false
              ? '?='
              : token.notFollowedBy ?? false
                  ? '?!'
                  : '?:';
      return '($prefix${createAlternate(token)})';
    case Types.POSITION:
      token as Position;
      if (token.value == '^' || token.value == r'$') {
        return token.value;
      } else {
        return '\\${token.value}';
      }
    case Types.SET:
      token as Set;
      return writeSetTokens(token);
    case Types.RANGE:
      token as Range;
      return '${setChar(token.from)}-${setChar(token.to)}';
    case Types.REPETITION:
      token as Repetition;
      final max = token.max;
      final min = token.min;
      String endWith;
      if (min == 0 && max == 1) {
        endWith = '?';
      } else if (min == 1 && max == -1) {
        endWith = '+';
      } else if (min == 0 && max == -1) {
        endWith = '*';
      } else if (max == -1) {
        endWith = '{$min,}';
      } else if (min == max) {
        endWith = '{$min}';
      } else {
        endWith = '{$min,$max}';
      }
      return '${reconstruct(token.value)}$endWith';
    case Types.REFERENCE:
      token as Reference;
      return '\\${token.value}';
    case Types.CHAR:
      token as Char;
      final c = String.fromCharCode(token.value);
      // Note that the escaping for characters inside classes is handled
      // in the write-set-tokens module so '-' and ']' are not escaped here
      return (RegExp(r'[[\\{}$^.|?*+()]').hasMatch(c) ? '\\' : '') + c;
    default:
      throw Exception('Invalid token type "$token"');
  }
}
