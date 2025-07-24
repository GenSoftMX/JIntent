import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/src/core/jstate.dart';

class TestState extends JState {
  final int counter;
  final String text;

  const TestState({required this.counter, required this.text});

  @override
  TestState copyWith({int? counter, String? text}) {
    return TestState(
      counter: counter ?? this.counter,
      text: text ?? this.text,
    );
  }

  @override
  List<Object?> get props => [counter, text];
}

void main() {
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
