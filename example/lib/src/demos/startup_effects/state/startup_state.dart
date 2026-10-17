import 'package:jintent/jintent.dart';

class StartupState extends JState {
  const StartupState({this.status = 'Ready', this.name});

  final String status;
  final String? name;

  @override
  StartupState copyWith({String? status, String? name}) =>
      StartupState(status: status ?? this.status, name: name ?? this.name);

  @override
  List<Object?> get props => [status, name];
}
