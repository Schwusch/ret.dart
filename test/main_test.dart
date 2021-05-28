import 'package:ret/ret.dart';
import 'package:ret/src/sets.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Char char(String c) => Char(c.codeUnitAt(0));

List<Char> charStr(String str) => str.split('').map(char).toList();

void main() {
  group('Regexp Tokenizer', () {
    group('No special characters', () {
      test('List of char tokens', () {
        expect(
          tokenizer('walnuts'),
          equals(Root(stack: charStr('walnuts'))),
        );
      });
    });

    group('Positionals', () {
      group(r'^ and $ in one liner', () {
        test('Positionals at beginning and end', () {
          expect(
            tokenizer(r'^yes$'),
            equals(
              Root(
                stack: [
                  Position('^'),
                  ...charStr('yes'),
                  Position(r'$'),
                ],
              ),
            ),
          );
        });
      });

      group('\\b and \\B', () {
        test('Word boundary at beginning', () {
          expect(
            tokenizer('\\bbeginning\\B'),
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
      test('Class contains all characters and range', () {
        expect(
          tokenizer('[\$!a-z123] thing [^0-9]'),
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
        test('Class contains some whitespace characters (not included in .)',
            () {
          final LINE_SEPARATOR = '\u2028';
          final PAGE_SEPARATOR = '\u2029';

          expect(
              tokenizer('[\t\r\n\u2028\u2029 ]'),
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
        test('Contains both classes and no range', () {
          expect(
            tokenizer('[01]-[ab]'),
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
        test('Returns root object with options', () {
          expect(
            tokenizer('foo|bar|za'),
            equals(
              Root(
                stack: null,
                options: [charStr('foo'), charStr('bar'), charStr('za')],
              ),
            ),
          );
        });
      });

      group('Group', () {
        group('with no special characters', () {
          test('Token list contains group token', () {
            expect(
              tokenizer('hey (there)'),
              Root(
                stack: [
                  ...charStr('hey '),
                  Group(remember: true, stack: charStr('there')),
                ],
              ),
            );
          });

          group('that is not remembered', () {
            test('Remember is false on the group object', () {
              expect(
                tokenizer('(?:loner)'),
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
            test('Returns a group', () {
              expect(
                tokenizer('what(?!ever)'),
                equals(
                  Root(
                    stack: [
                      ...charStr('what'),
                      Group(
                        remember: false,
                        notFollowedBy: true,
                        stack: charStr('ever'),
                      )
                    ],
                  ),
                ),
              );
            });
          });
        });

        group('matched next clause', () {
          test('Returns a group', () {
            expect(
              tokenizer('hello(?= there)'),
              equals(
                Root(
                  stack: [
                    ...charStr('hello'),
                    Group(
                        remember: false,
                        followedBy: true,
                        stack: charStr(' there'))
                  ],
                ),
              ),
            );
          });
        });

        group('with subgroup', () {
          test('groups within groups', () {
            expect(
                tokenizer('a(b(c|(?:d))fg) @_@'),
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
            expect(
              tokenizer('(?:pika){2}'),
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
            expect(
              tokenizer('NO{6,}'),
              equals(Root(
                stack: [
                  char('N'),
                  Repetition(min: 6, max: -1, value: char('O')),
                ],
              )),
            );
          });

          test('Min and max differ and min < max', () {
            expect(
                tokenizer('pika\\.\\.\\. chu{3,20}!{1,2}'),
                equals(Root(stack: [
                  ...charStr('pika... ch'),
                  Repetition(min: 3, max: 20, value: char('u')),
                  Repetition(min: 1, max: 2, value: char('!')),
                ])));
          });

          test('Brackets around a non-repetitional returns a non-repetitional',
              () {
            expect(
              tokenizer('a{mustache}'),
              equals(Root(stack: charStr('a{mustache}'))),
            );
          });
        });

        group('Predefined repetitional', () {
          test('? (Optional) - Get back correct min and max', () {
            expect(
              tokenizer('hey(?: you)?'),
              equals(
                Root(
                  stack: [
                    ...charStr('hey'),
                    Repetition(
                      min: 0,
                      max: 1,
                      value: Group(
                        remember: false,
                        stack: charStr(' you'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });

          test('+ (At least one) - Correct min and max', () {
            expect(
              tokenizer('(no )+'),
              equals(
                Root(
                  stack: [
                    Repetition(
                        min: 1,
                        max: -1,
                        value: Group(remember: true, stack: charStr('no '))),
                  ],
                ),
              ),
            );
          });

          test('* (Any amount) - 0 to Infinity', () {
            expect(
              tokenizer('XF*D'),
              equals(
                Root(
                  stack: [
                    char('X'),
                    Repetition(min: 0, max: -1, value: char('F')),
                    char('D'),
                  ],
                ),
              ),
            );
          });
        });

        group('Reference', () {
          test('Reference a group', () {
            expect(
              tokenizer('<(\\w+)>\\w*<\\1>'),
              equals(
                Root(
                  stack: [
                    char('<'),
                    Group(
                      remember: true,
                      stack: [
                        Repetition(min: 1, max: -1, value: words),
                      ],
                    ),
                    char('>'),
                    Repetition(min: 0, max: -1, value: words),
                    char('<'),
                    Reference(1),
                    char('>'),
                  ],
                ),
              ),
            );
          });
        });

        group('Range (in set) test cases', () {
          group('Testing complex range cases', () {
            test(
              'token.from is a hyphen and the range is preceded by a single character [a\\--\\-]',
              () {
                expect(
                  tokenizer('[a\\--\\-]'),
                  equals(
                    Root(
                      stack: [
                        Set(
                          set: [
                            Char(97),
                            Range(from: 45, to: 45),
                          ],
                          not: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            test(
              'token.from is a hyphen and the range is preceded by a single character [a\\--\\/]',
              () {
                expect(
                  tokenizer('[a\\--\\/]'),
                  equals(
                    Root(
                      stack: [
                        Set(
                          set: [
                            Char(97),
                            Range(from: 45, to: 47),
                          ],
                          not: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            test(
              'token.from is a hyphen and the range is preceded by a single character [c\\--a]',
              () {
                expect(
                  tokenizer('[c\\--a]'),
                  equals(
                    Root(
                      stack: [
                        Set(
                          set: [
                            Char(99),
                            Range(from: 45, to: 97),
                          ],
                          not: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            test(
              'token.from is a hyphen and the range is preceded by a single character [\\-\\--\\-]',
              () {
                expect(
                  tokenizer('[\\-\\--\\-]'),
                  equals(
                    Root(
                      stack: [
                        Set(
                          set: [
                            Char(45),
                            Range(from: 45, to: 45),
                          ],
                          not: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            test(
              'token.from is a hyphen and the range is preceded by a predefined set [\\w\\--\\-]',
              () {
                expect(
                  tokenizer('[\\w\\--\\-]'),
                  equals(
                    Root(
                      stack: [
                        Set(
                          set: [
                            Set(
                              set: [
                                Char(95),
                                Range(from: 97, to: 122),
                                Range(from: 65, to: 90),
                                Range(from: 48, to: 57),
                              ],
                              not: false,
                            ),
                            Range(from: 45, to: 45),
                          ],
                          not: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            test(
              'token.from is a caret and the range is the first item of the set [9-\\^]',
              () {
                expect(
                  tokenizer('[9-\\^]'),
                  equals(
                    Root(
                      stack: [
                        Set(
                          set: [Range(from: 57, to: 94)],
                          not: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            test('token.to is a closing square bracket [2-\\]]', () {
              expect(
                tokenizer('[2-\\]]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 50, to: 93)],
                        not: false,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('token.to is a closing square bracket [\\]-\\^]', () {
              expect(
                tokenizer('[\\]-\\^]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 93, to: 94)],
                        not: false,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('token.to is a closing square bracket [[-\\]]', () {
              expect(
                tokenizer('[[-\\]]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 91, to: 93)],
                        not: false,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('token.to is a closing square bracket [[-]]', () {
              expect(
                tokenizer('[[-]]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Char(91), Char(45)],
                        not: false,
                      ),
                      Char(93),
                    ],
                  ),
                ),
              );
            });

            test('token.from is a caret [\\^-_]', () {
              expect(
                tokenizer('[\\^-_]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 94, to: 95)],
                        not: false,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('token.from is a caret [\\^-^]', () {
              expect(
                tokenizer('[\\^-^]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 94, to: 94)],
                        not: false,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('token.from is a caret and set is negated [^\\^-_]', () {
              expect(
                tokenizer('[^\\^-_]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 94, to: 95)],
                        not: true,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('token.from is a caret [^\\^-^] and set is negated', () {
              expect(
                tokenizer('[^\\^-^]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [Range(from: 94, to: 94)],
                        not: true,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('Contains empty set', () {
              expect(
                tokenizer('[]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [],
                        not: false,
                      ),
                    ],
                  ),
                ),
              );
            });

            test('Contains empty negated set', () {
              expect(
                tokenizer('[^]'),
                equals(
                  Root(
                    stack: [
                      Set(
                        set: [],
                        not: true,
                      ),
                    ],
                  ),
                ),
              );
            });
          });
        });
      });
    });
  });
}
