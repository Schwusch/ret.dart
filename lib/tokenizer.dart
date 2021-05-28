import 'package:ret/sets.dart';
import 'package:ret/types/tokens.dart';
import 'package:ret/util.dart';

Root tokenizer(String regexpStr) {
  var i = 0;
  String c;
  final start = Root(stack: []);

  RootOrGroup lastGroup = start;
  var last = start.stack!;
  var groupStack = <RootOrGroup>[];

  void repeatErr(int col) {
    throw Exception(
        'Invalid regular expression: "$regexpStr": nothing to repeat at column ${col - 1}');
  }

  var str = strToChars(regexpStr);

  while (i < str.length) {
    switch (c = str[i++]) {
      case '\\':
        switch (c = str[i++]) {
          case 'b':
            last.add(Position('b'));
            break;

          case 'B':
            last.add(Position('B'));
            break;

          case 'w':
            last.add(words);
            break;

          case 'W':
            last.add(notWords);
            break;

          case 'd':
            last.add(ints);
            break;

          case 'D':
            last.add(notInts);
            break;

          case 's':
            last.add(whitespace);
            break;

          case 'S':
            last.add(notWhitespace);
            break;

          default:
            // Check if c is integer.
            // In which case it's a reference.
            if (c.contains(RegExp('\d'))) {
              last.add(Reference(int.parse(c)));
            } else {
              // Escaped character.
              last.add(Char(c.codeUnitAt(0)));
            }
        }
        break;

      // Positionals.
      case '^':
        last.add(Position('^'));
        break;

      case r'$':
        last.add(Position(r'$'));
        break;

      // Handle custom sets.
      case '[':
        // Check if this class is 'anti' i.e. [^abc].
        bool not;
        if (str[i] == '^') {
          not = true;
          i++;
        } else {
          not = false;
        }

        // Get all the characters in class.
        final classTokens = tokenizeClass(str.substring(i), regexpStr);

        // Increase index by length of class.
        i += classTokens.end;
        last.add(Set(set: classTokens.token, not: not));

        break;

      // Class of any character except \n.
      case '.':
        last.add(anyChar);
        break;

      // Push group onto stack.
      case '(':
        final group = Group(remember: true, stack: []);

        // If if this is a special kind of group.
        if (str[i] == '?') {
          c = str[i + 1];
          i += 2;

          // Match if followed by.
          if (c == '=') {
            group.followedBy = true;

            // Match if not followed by.
          } else if (c == '!') {
            group.notFollowedBy = true;
          } else if (c != ':') {
            throw Exception(
                'Invalid regular expression: "$regexpStr": Invalid group, character "$c" after "?" at column ${i - 1}');
          }

          group.remember = false;
        }

        // Insert subgroup into current group stack.
        last.add(group);

        // Remember the current group for when the group closes.
        groupStack.add(lastGroup);

        // Make this new group the current group.
        lastGroup = group;
        last = group.stack!;

        break;

      // Pop group out of stack.
      case ')':
        if (groupStack.isEmpty) {
          throw Exception(
            'Invalid regular expression: "$regexpStr": Unmatched ) at column ${i - 1}',
          );
        }
        lastGroup = groupStack.removeLast();

        // Check if this group has a PIPE.
        // To get back the correct last stack.
        last = lastGroup.options != null
            ? lastGroup.options![lastGroup.options!.length - 1]
            : lastGroup.stack!;

        break;

      // Use pipe character to give more choices.
      case '|':
        // Create array where options are if this is the first PIPE
        // in this clause.
        if (lastGroup.options == null) {
          lastGroup.options = [lastGroup.stack!];
          lastGroup.stack = null;
        }
        // Create a new stack and add to options for rest of clause.
        var stack = <Token>[];
        lastGroup.options!.add(stack);
        last = stack;

        break;

      // Repetition.
      // For every repetition, remove last element from last stack
      // then insert back a RANGE object.
      // This design is chosen because there could be more than
      // one repetition symbols in a regex i.e. 'a?+{2,3}'.
      case '{':
        var rs = RegExp('^(\d+)(,(\d+)?)?\}').firstMatch(str.substring(i));
        int min;
        int max;
        if (rs != null) {
          if (last.isEmpty) {
            repeatErr(i);
          }
          min = int.parse(rs[1]!);
          max = rs[2] != null
              ? rs[3] != null
                  ? int.parse(rs[3]!)
                  : -1
              : min;
          i += rs[0]!.length;

          last.add(Repetition(min: min, max: max, value: last.removeLast()));
        } else {
          last.add(Char(123));
        }

        break;

      case '?':
        if (last.isEmpty) {
          repeatErr(i);
        }
        last.add(Repetition(min: 0, max: 1, value: last.removeLast()));
        break;

      case '+':
        if (last.isEmpty) {
          repeatErr(i);
        }
        last.add(Repetition(min: 1, max: -1, value: last.removeLast()));

        break;

      case '*':
        if (last.isEmpty) {
          repeatErr(i);
        }
        last.add(Repetition(min: 0, max: -1, value: last.removeLast()));

        break;

      // Default is a character that is not `\[](){}?+*^$`.
      default:
        last.add(Char(c.codeUnitAt(0)));
    }
  }

  // Check if any groups have not been closed.
  if (groupStack.isNotEmpty) {
    throw Exception(
        'Invalid regular expression: "$regexpStr": Unterminated group');
  }

  return start;
}
