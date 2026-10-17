import 'package:jintent/jintent.dart';

class CounterState extends JState {
  final int value;

  const CounterState([this.value = 0]);

  @override
  CounterState copyWith({int? value}) => CounterState(value ?? this.value);

  @override
  List<Object?> get props => [value];
}

class CounterController extends JController<CounterState> {
  CounterController({super.dispatcher, super.effectBufferSize})
    : super(const CounterState());

  @override
  void onInit() {}
}

class CallbackIntent extends JIntent<CounterState> {
  final Future<void> Function(CallbackIntent intent) callback;

  CallbackIntent(this.callback);

  @override
  Future<void> onInvoke() => callback(this);
}

class BoolEffect extends JResultEffect<bool> {}
