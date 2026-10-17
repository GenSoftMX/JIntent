import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/src/core/jstate.dart';

class TestState extends JState {
  final int counter;
  final String text;

  const TestState({required this.counter, required this.text});

  @override
  TestState copyWith({int? counter, String? text}) {
    return TestState(counter: counter ?? this.counter, text: text ?? this.text);
  }

  @override
  List<Object?> get props => [counter, text];
}

const _unchanged = Object();

class ProfileState extends JState {
  final String? name;
  final List<String> tags;

  ProfileState({this.name, List<String> tags = const []})
    : tags = List.unmodifiable(tags);

  @override
  ProfileState copyWith({Object? name = _unchanged, List<String>? tags}) {
    if (!identical(name, _unchanged) && name != null && name is! String) {
      throw ArgumentError.value(name, 'name', 'Must be a String or null');
    }
    return ProfileState(
      name: identical(name, _unchanged) ? this.name : name as String?,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [name, tags];
}

class InitialState extends JState {
  const InitialState();

  @override
  InitialState copyWith() => this;

  @override
  List<Object?> get props => const [];
}

class LoadingState extends JState {
  const LoadingState();

  @override
  LoadingState copyWith() => this;

  @override
  List<Object?> get props => const [];
}

void main() {
  test('distinct state classes with equal props are not equal', () {
    // Guards the equatable version range (ADR-003): if a release stopped
    // comparing runtimeType, a transition between such states would be skipped.
    expect(const InitialState() == const LoadingState(), isFalse);
    expect(
      const InitialState().hashCode == const LoadingState().hashCode,
      isFalse,
    );
    expect(const LoadingState(), equals(const LoadingState()));
  });

  test(
    'nullable copy distinguishes omission, replacement and explicit null',
    () {
      final original = ProfileState(name: 'Ada');
      expect(original.copyWith().name, 'Ada');
      expect(original.copyWith(name: 'Grace').name, 'Grace');
      expect(original.copyWith(name: null).name, isNull);
      expect(original.name, 'Ada');
      expect(() => original.copyWith(name: 42), throwsArgumentError);
    },
  );

  test('defensive collections preserve state and value equality', () {
    final input = ['core'];
    final original = ProfileState(tags: input);
    input.add('external');
    expect(original.tags, ['core']);
    expect(() => original.tags.add('mutation'), throwsUnsupportedError);
    final equivalent = ProfileState(tags: const ['core']);
    expect(original, equivalent);
    expect(original.hashCode, equivalent.hashCode);
    final changed = original.copyWith(tags: ['core', 'effects']);
    expect(changed, isNot(original));
    expect(original.tags, ['core']);
  });

  test('TestState equality and copyWith', () {
    const state1 = TestState(counter: 0, text: 'hello');
    const state2 = TestState(counter: 0, text: 'hello');
    final state3 = state1.copyWith(counter: 1);

    // Equality based on props
    expect(state1, equals(state2));
    expect(state1 == state2, isTrue);

    // copyWith creates a new instance with updated field
    expect(state3.counter, 1);
    expect(state3.text, 'hello');

    // Original is unchanged
    expect(state1.counter, 0);
    expect(state1.text, 'hello');

    // Inequality due to different props
    expect(state1 == state3, isFalse);
  });
}
