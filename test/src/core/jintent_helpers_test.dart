import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:mocktail/mocktail.dart';

class MockController<T extends JState> extends Mock implements JController<T> {}

class MockEffect<T> extends Mock implements JEffect<T> {}

class TestState extends JState {
  @override
  TestState copyWith() => this;

  @override
  List<Object?> get props => [];
}

class TestIntent extends JIntent<TestState> with JIntentHelpers<TestState> {
  @override
  Future<void> onInvoke() async {}
  @override
  late JController<TestState> controller;
}

void main() {
  late MockController<TestState> mockController;
  late TestIntent intent;

  setUp(() {
    mockController = MockController<TestState>();
    intent = TestIntent();
    intent.controller = mockController;
  });

  test('emitSideEffect calls controller.emitSideEffect', () {
    final effect = MockEffect();
    intent.emitSideEffect(effect);
    verify(() => mockController.emitSideEffect(effect)).called(1);
  });

  test('update forwards the reducer with this intent as origin', () {
    when(
      () => mockController.update(any(), origin: any(named: 'origin')),
    ).thenReturn(null);
    TestState reducer(TestState state) => state;

    intent.update(reducer);

    verify(() => mockController.update(reducer, origin: intent)).called(1);
  });

  test('emitAndWaitSideEffect returns the controller result', () async {
    final effect = MockEffect<bool>();
    when(
      () => mockController.emitAndWaitSideEffect<bool>(effect),
    ).thenAnswer((_) async => true);

    expect(await intent.emitAndWaitSideEffect<bool>(effect), isTrue);
  });
}
