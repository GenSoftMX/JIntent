import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class TestState extends JState {
  @override
  JState copyWith() => this;

  @override
  List<Object?> get props => [];
}

class TestIntent extends JIntent<TestState> with JMetaData<TestState> {
  @override
  String get name => 'CustomIntentName';

  @override
  String get type => 'customType';

  @override
  Map<String, dynamic> get metadata => {'key': 'value'};

  @override
  Future<void> onInvoke() async {}
}

void main() {
  test('JMetaData mixin provides correct metadata', () {
    final intent = TestIntent();

    expect(intent.name, 'CustomIntentName');
    expect(intent.type, 'customType');
    expect(intent.metadata, {'key': 'value'});
  });

  test('JMetaData default name is runtimeType', () {
    final defaultIntent = _DefaultIntent();

    expect(defaultIntent.name, '_DefaultIntent');
    expect(defaultIntent.type, 'default');
    expect(defaultIntent.metadata, {});
  });
}

class _DefaultIntent extends JIntent<TestState> with JMetaData<TestState> {
  @override
  Future<void> onInvoke() async {}
}
