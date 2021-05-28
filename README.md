
# Regular Expression Tokenizer

A Dart port of [ret.js](https://github.com/fent/ret.js).

Tokenizes strings that represent a regular expressions.

# Usage

```dart
import 'package:ret/ret.dart';

final tokens = tokenizer('foo|bar');
```

`tokens` will contain the following object:

```dart
Root(
  options: [
    [
        Char(102),
        Char(111),
        Char(111),
    ],
    [
        Char(98),
        Char(97),
        Char(114),
    ]
  ]
)
```

# Reconstructing Regular Expressions from Tokens

The reconstruct function accepts any token and returns, as a string, the component of the regular expression that is associated with that token.

```dart
import 'package:ret/ret.dart';

void main() {
  final tokens = tokenizer('foo|bar');

  final setToken = Set(
    set: [
      Char(97),
      Char(98),
      Char(99),
    ],
    not: true,
  );

  reconstruct(tokens); // 'foo|bar'
  reconstruct(Char(102)); // 'f'
  reconstruct(setToken); // '^abc'
}
```

# Exceptions

ret.dart will throw exceptions if given a string with an invalid regular expression. All possible errors are

* Invalid group. When a group with an immediate `?` character is followed by an invalid character. It can only be followed by `!`, `=`, or `:`. Example: `(?_abc)`
* Nothing to repeat. Thrown when a repetitional token is used as the first token in the current clause, as in right in the beginning of the regexp or group, or right after a pipe. Examples: 
  - `foo|?bar`
  - `{1,3}foo|bar`
  - `foo(+bar)`
* Unmatched `)`. A group was not opened, but was closed. Example: `hello)2u`
* Unterminated group. A group was not closed. Example: `(1(23)4`
* Unterminated character class. A custom character set was not closed. Example: `[abc`

# Regular Expression Syntax

Regular expressions follow the [JavaScript syntax](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp).

The following latest JavaScript additions are not supported yet:
* `\p` and `\P`: [Unicode property escapes](https://github.com/tc39/proposal-regexp-unicode-property-escapes)
* `(?<group>)` and `\k<group>`: [Named groups](https://github.com/tc39/proposal-regexp-named-groups)
* `(?<=)` and `(?<!)`: [Negative lookbehind assertions](https://github.com/tc39/proposal-regexp-lookbehind)