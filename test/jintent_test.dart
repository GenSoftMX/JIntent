import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jstate.dart';

void main() {
  group('Jintent counter test', () {
    final initialState = MockState.initialState();

    final controller = MockController(initialState);

    test('Intent should update the state count to 1', () async {
      final intent = MockIntent();

      controller.intent(intent);

      expect(controller.currentState.count, equals(1));
    });
  });
}

class MockController extends JController<MockState> {
  MockController(super.initialState);
}

class MockState extends JState {
  final int count;

  MockState({required this.count});

  @override
  MockState copyWith({int? newStateCount}) => MockState(
        count: newStateCount ?? count,
      );

  factory MockState.initialState() => MockState(count: 0);
}

class MockIntent extends JIntent<MockState> {
  @override
  invoke(JController<MockState> controller) {
    final state = controller.currentState;

    controller.setState(state.copyWith(newStateCount: 1));
  }
}
