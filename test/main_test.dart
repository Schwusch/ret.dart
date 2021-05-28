import 'package:ret/ret.dart';
import 'package:ret/sets.dart';
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
      group(r'^ and $ in one liner', () {
        final t = tokenizer(r'^yes$');

        test('Positionals at beginning and end', () {
          expect(
              t,
              equals(
                Root(
                  stack: [
                    Position('^'),
                    ...charStr('yes'),
                    Position(r'$'),
                  ],
                ),
              ));
        });
      });

      group('\\b and \\B', () {
        final t = tokenizer('\\bbeginning\\B');

        test('Word boundary at beginning', () {
          expect(
            t,
            Root(
              stack: [
                Position('b'),
                ...charStr('beginning'),
                Position('B'),
              ],
            ),
          );
        });
      });
    });

    group('Predefined sets', () {
      final t = tokenizer('\\w\\W\\d\\D\\s\\S.');

      test('Words set', () {
        expect(t.stack?[0], equals(words));
      });

      test('Non-Words set', () {
        expect(t.stack?[1], equals(notWords));
      });

      test('Integer set', () {
        expect(t.stack?[2], equals(ints));
      });

      test('Non-Integer set', () {
        expect(t.stack?[3], equals(notInts));
      });

      test('Whitespace set', () {
        expect(t.stack?[4], equals(whitespace));
      });

      test('Non-Whitespace set', () {
        expect(t.stack?[5], equals(notWhitespace));
      });

      test('Any character set', () {
        expect(t.stack?[6], equals(anyChar));
      });
    });

    group('Custom sets', () {
      final t = tokenizer('[\$!a-z123] thing [^0-9]');

      test('Class contains all characters and range', () {
        expect(
          t,
          equals(Root(
            stack: [
              Set(
                set: [
                  ...charStr(r'$!'),
                  Range(
                    from: 'a'.codeUnitAt(0),
                    to: 'z'.codeUnitAt(0),
                  ),
                  ...charStr('123'),
                ],
                not: false,
              ),
              ...charStr(' thing '),
              Set(
                set: [
                  Range(
                    from: '0'.codeUnitAt(0),
                    to: '9'.codeUnitAt(0),
                  ),
                ],
                not: true,
              ),
            ],
          )),
        );
      });

      group('Whitespace characters', () {
        final t = tokenizer('[\t\r\n\u2028\u2029 ]');

        test('Class contains some whitespace characters (not included in .)',
            () {
          final LINE_SEPARATOR = '\u2028';
          final PAGE_SEPARATOR = '\u2029';

          expect(
              t,
              equals(
                Root(stack: [
                  Set(
                    set: [
                      ...charStr('\t\r\n'),
                      char(LINE_SEPARATOR),
                      char(PAGE_SEPARATOR),
                      char(' '),
                    ],
                    not: false,
                  ),
                ]),
              ));
        });
      });

      group('Two sets in a row with dash in between', () {
        final t = tokenizer('[01]-[ab]');

        test('Contains both classes and no range', () {
          expect(
            t,
            equals(
              Root(
                stack: [
                  Set(set: charStr('01'), not: false),
                  char('-'),
                  Set(set: charStr('ab'), not: false),
                ],
              ),
            ),
          );
        });
      });

      group('| (Pipe)', () {
        final t = tokenizer('foo|bar|za');

        test('Returns root object with options', () {
          expect(
              t,
              equals(Root(
                stack: null,
                options: [charStr('foo'), charStr('bar'), charStr('za')],
              )));
        });
      });

      group('Group', () {
        group('with no special characters', () {
          final t = tokenizer('hey (there)');

          test('Token list contains group token', () {
            expect(
                t,
                Root(
                  stack: [
                    ...charStr('hey '),
                    Group(remember: true, stack: charStr('there')),
                  ],
                ));
          });
          group('that is not remembered', () {
            final t = tokenizer('(?:loner)');

            test('Remember is false on the group object', () {
              expect(
                t,
                equals(
                  Root(
                    stack: [
                      Group(remember: false, stack: charStr('loner')),
                    ],
                  ),
                ),
              );
            });
          });

          group('matched previous clause if not followed by this', () {
            final t = tokenizer('what(?!ever)');

            test('Returns a group', () {
              expect(
                  t,
                  equals(Root(stack: [
                    ...charStr('what'),
                    Group(
                      remember: false,
                      notFollowedBy: true,
                      stack: charStr('ever'),
                    )
                  ])));
            });
          });
        });

        group('matched next clause', () {
          final t = tokenizer('hello(?= there)');

          test('Returns a group', () {
            expect(
                t,
                equals(Root(stack: [
                  ...charStr('hello'),
                  Group(
                      remember: false,
                      followedBy: true,
                      stack: charStr(' there'))
                ])));
          });
        });
        group('with subgroup', () {
          final t = tokenizer('a(b(c|(?:d))fg) @_@');

          test('groups within groups', () {
            expect(
                t,
                Root(stack: [
                  char('a'),
                  Group(remember: true, stack: [
                    char('b'),
                    Group(remember: true, stack: null, options: [
                      charStr('c'),
                      [Group(remember: false, stack: charStr('d'))]
                    ]),
                    ...charStr('fg'),
                  ]),
                  ...charStr(' @_@'),
                ]));
          });
        });
      });

      group('Custom repetition with', () {
        group('exact amount', () {
          test('Min and max are the same', () {
            final t = tokenizer('(?:pika){2}');

            expect(
              t,
              equals(
                Root(stack: [
                  Repetition(
                    min: 2,
                    max: 2,
                    value: Group(
                      remember: false,
                      stack: charStr('pika'),
                    ),
                  )
                ]),
              ),
            );
          });

          test('minimum amount only to infinity', () {
            final t = tokenizer('NO{6,}');

            expect(
              t,
              equals(Root(
                stack: [
                  char('N'),
                  Repetition(min: 6, max: -1, value: char('O')),
                ],
              )),
            );
          });

          test('Min and max differ and min < max', () {
            final t = tokenizer('pika\\.\\.\\. chu{3,20}!{1,2}');
          });
        });
      });
    });
  });
}
