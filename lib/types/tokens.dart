import 'package:equatable/equatable.dart';

enum Types { ROOT, GROUP, POSITION, SET, RANGE, REPETITION, REFERENCE, CHAR }

class Base {
  final Types type;

  const Base(this.type);
}

class ValueType<T> extends Token with EquatableMixin {
  final T value;

  const ValueType(Types type, this.value) : super(type);

  @override
  List<Object?> get props => [value];
}

class Token extends Tokens {
  const Token(Types type) : super(type);
}

class Tokens extends Base {
  const Tokens(Types type) : super(type);
}

class SetToken {}

abstract class RootOrGroup {
  List<Token>? stack;
  List<List<Token>>? options;

  RootOrGroup(this.stack, this.options);
}

class Root extends Tokens with EquatableMixin implements RootOrGroup {
  Root({
    this.flags,
    this.options,
    required this.stack,
  }) : super(Types.ROOT);

  @override
  List<Token>? stack;
  @override
  List<List<Token>>? options;
  final List<String>? flags;

  @override
  List<Object?> get props => [stack, options, flags];
}

class Group extends Token with EquatableMixin implements RootOrGroup {
  Group({
    required this.remember,
    this.options,
    required this.stack,
    this.followedBy,
    this.notFollowedBy,
    this.lookBehind,
  }) : super(Types.GROUP);

  @override
  List<Token>? stack;
  @override
  List<List<Token>>? options;
  bool remember;
  bool? followedBy;
  bool? notFollowedBy;
  final bool? lookBehind;

  @override
  List<Object?> get props => [
        stack,
        options,
        remember,
        followedBy,
        notFollowedBy,
        lookBehind,
      ];
}

class Set extends Token with EquatableMixin implements SetToken {
  const Set({
    required this.set,
    required this.not,
  }) : super(Types.SET);

  final List<SetToken> set;
  final bool not;

  @override
  List<Object?> get props => [set, not];
}

class Range extends Token with EquatableMixin implements SetToken {
  const Range({
    required this.from,
    required this.to,
  }) : super(Types.RANGE);

  final int from;
  final int to;

  @override
  List<Object?> get props => [from, to];
}

class Repetition extends Token with EquatableMixin {
  const Repetition({
    required this.min,
    required this.max,
    required this.value,
  }) : super(Types.REPETITION);

  final int min;
  final int max;
  final Token value;

  @override
  List<Object?> get props => [min, max, value];
}

class Position extends ValueType<String> {
  Position(String value) : super(Types.POSITION, value) {
    assert(['\$', '^', 'b', 'B'].contains(value));
  }
}

class Reference extends ValueType<int> {
  const Reference(int value) : super(Types.REFERENCE, value);
}

class Char extends ValueType<int> implements SetToken {
  const Char(int value) : super(Types.CHAR, value);
}
