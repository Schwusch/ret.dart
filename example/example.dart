import 'package:ret/ret.dart';

void main() {
  final tokens = tokenizer('foo|bar');

  print(tokens);
  // Root(null, [[Char(102), Char(111), Char(111)], [Char(98), Char(97), Char(114)]], null)

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
