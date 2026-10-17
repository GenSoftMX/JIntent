import 'package:jintent/jintent.dart';

class LabState extends JState {
  const LabState({this.finished = const []});

  /// Ids of the tasks that completed and wrote their result, in order.
  final List<int> finished;

  @override
  LabState copyWith({List<int>? finished}) =>
      LabState(finished: finished ?? this.finished);

  @override
  List<Object?> get props => [finished];
}
