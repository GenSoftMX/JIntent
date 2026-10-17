import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/experimental.dart' as legacy;
import 'package:jintent/jintent.dart';
import 'package:jintent/undo_redo.dart';

import '../core/core_test_support.dart';

class ContractController extends JController<CounterState>
    with UndoRedoMixin<CounterState> {
  ContractController() : super(const CounterState());
  @override
  void onInit() => enableUndoRedo(maxHistorySize: 4);

  void add() => updateWithUndo((s) => s.copyWith(value: s.value + 1));
}

class HistoryIntent extends JIntent<CounterState> {
  HistoryIntent({this.cancelFirst = false});
  final bool cancelFirst;
  @override
  Future<void> onInvoke() async {
    if (cancelFirst) cancel();
    final target = controller as ContractController;
    target.undo();
    if (cancelFirst) {
      target.clearHistory();
      target.disableUndoRedo();
      target.enableUndoRedo(maxHistorySize: 1);
    }
  }
}

class EqualCommand extends UndoableCommand<CounterState> {
  @override
  CounterState execute(CounterState state) =>
      state.copyWith(value: state.value);
  @override
  CounterState undo(CounterState state) => state;
}

class StepCommand extends UndoableCommand<CounterState> {
  @override
  CounterState execute(CounterState state) =>
      state.copyWith(value: state.value + 1);
  @override
  CounterState undo(CounterState state) =>
      state.copyWith(value: state.value - 1);
}

void main() {
  late ContractController controller;
  setUp(() => controller = ContractController());
  tearDown(() => controller.dispose());

  test(
    'history metadata notifies for clear and disable without domain writes',
    () {
      final observed = <JUndoHistoryState>[];
      controller.history.addListener(
        () => observed.add(controller.history.value),
      );
      controller.add();
      controller.undo();
      controller.redo();
      expect(observed.map((s) => [s.undoCount, s.redoCount]), [
        [1, 0],
        [0, 1],
        [1, 0],
      ]);
      controller.clearHistory();
      expect(controller.currentState.value, 1);
      expect(observed.last.canUndo, isFalse);
      controller.clearHistory();
      expect(observed, hasLength(4), reason: 'equal metadata is not emitted');
      controller.disableUndoRedo();
      expect(observed.last.enabled, isFalse);
      controller.enableUndoRedo();
      expect(observed.last.enabled, isTrue);
    },
  );

  test('equal snapshot restoration still publishes changed history', () {
    controller.add();
    controller.update((_) => const CounterState());
    var events = 0;
    controller.history.addListener(() => events++);
    expect(controller.undo(), isTrue);
    expect(controller.currentState.value, 0);
    expect(controller.history.value.canUndo, isFalse);
    expect(controller.history.value.canRedo, isTrue);
    expect(events, 1);
  });

  test(
    'undo and redo notify global observer and preserve intent attribution',
    () async {
      final origins = <JIntent?>[];
      final values = <int>[];
      final previous = JObserver.onStateChanged;
      addTearDown(() => JObserver.onStateChanged = previous);
      JObserver.onStateChanged = (before, after, intent) {
        origins.add(intent);
        values.add((after as CounterState).value);
      };
      controller.add();
      final intent = HistoryIntent();
      await controller.intent(intent);
      controller.redo();
      expect(values, [1, 0, 1]);
      expect(origins, [null, intent, null]);
    },
  );

  test('cancelled intents cannot alter history or its enabled state', () async {
    controller.add();
    final before = controller.history.value;
    await controller.intent(HistoryIntent(cancelFirst: true));
    expect(controller.currentState.value, 1);
    expect(controller.history.value, before);
    expect(controller.canUndo, isTrue);
  });

  test(
    'invalid capacities preserve history; smaller capacities trim both stacks',
    () {
      for (var i = 0; i < 4; i++) {
        controller.add();
      }
      for (final limit in [0, -1]) {
        expect(
          () => controller.enableUndoRedo(maxHistorySize: limit),
          throwsArgumentError,
        );
        expect(
          () => CommandHistory<CounterState>(maxSize: limit),
          throwsArgumentError,
        );
      }
      expect(controller.undoStackSize, 4);
      controller.enableUndoRedo(maxHistorySize: 2);
      expect(controller.undoHistory.map((s) => s.value), [2, 3]);
      controller.undo();
      controller.undo();
      controller.enableUndoRedo(maxHistorySize: 1);
      expect(controller.redoStackSize, 1);
      expect(controller.redo(), isTrue);
      expect(controller.currentState.value, 3);
    },
  );

  test(
    'disposed controller rejects history operations and releases snapshots',
    () {
      controller.add();
      controller.dispose();
      expect(controller.undo(), isFalse);
      expect(controller.redo(), isFalse);
      controller.clearHistory();
      controller.disableUndoRedo();
      controller.enableUndoRedo();
      controller.updateWithUndo((_) => throw StateError('must not run'));
      expect(controller.undoHistory, isEmpty);
      expect(controller.redoHistory, isEmpty);
    },
  );

  test('legacy import resolves to the stable implementation', () {
    expect(
      legacy.CommandHistory<CounterState>(),
      isA<CommandHistory<CounterState>>(),
    );
  });

  test('restoring after shrinking never exceeds either stack capacity', () {
    for (var i = 0; i < 4; i++) {
      controller.add();
    }
    controller.undo();
    controller.undo();
    controller.enableUndoRedo(maxHistorySize: 1);
    expect(controller.undoStackSize, 1);
    expect(controller.redoStackSize, 1);
    controller.undo();
    expect(controller.redoStackSize, 1);
    controller.redo();
    expect(controller.undoStackSize, 1);
  });

  test(
    'disposal inside a reducer cannot retain a snapshot or notify history',
    () {
      var notifications = 0;
      controller.history.addListener(() => notifications++);
      controller.updateWithUndo((state) {
        controller.dispose();
        return state.copyWith(value: 1);
      });
      expect(controller.undoHistory, isEmpty);
      expect(notifications, 0);
    },
  );

  test('equal command preserves redo and does not add an undo entry', () {
    final history = CommandHistory<CounterState>();
    final next = history.execute(const CounterState(), StepCommand());
    final previous = history.undo(next)!;
    history.execute(previous, EqualCommand());
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);
    expect(history.redo(previous)!.value, 1);
  });
}
