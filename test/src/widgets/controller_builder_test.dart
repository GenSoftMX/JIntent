import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/widgets.dart';

class ViewState extends JState {
  const ViewState(this.count, this.label);
  final int count;
  final String label;
  @override
  ViewState copyWith({int? count, String? label}) =>
      ViewState(count ?? this.count, label ?? this.label);
  @override
  List<Object?> get props => [count, label];
}

class ViewController extends JController<ViewState> {
  ViewController([int count = 0]) : super(ViewState(count, 'initial'));
  @override
  void onInit() {}
}

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('builder reads initial state, follows updates and detaches', (
    tester,
  ) async {
    final controller = ViewController(3);
    addTearDown(controller.dispose);
    var builds = 0;
    await tester.pumpWidget(
      host(
        JControllerBuilder<ViewState>(
          controller: controller,
          builder: (_, state) {
            builds++;
            return Text('${state.count}');
          },
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    controller.update((s) => s.copyWith(count: 4));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    expect(builds, 2);
    await tester.pumpWidget(const SizedBox());
    controller.update((s) => s.copyWith(count: 5));
    await tester.pump();
    expect(builds, 2);
    expect(controller.mounted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector ignores unrelated state and equal selections', (
    tester,
  ) async {
    final controller = ViewController();
    addTearDown(controller.dispose);
    var builds = 0;
    await tester.pumpWidget(
      host(
        JControllerSelector<ViewState, int>(
          controller: controller,
          selector: (s) => s.count,
          builder: (_, value) {
            builds++;
            return Text('$value');
          },
        ),
      ),
    );
    controller.update((s) => s.copyWith(label: 'changed'));
    await tester.pump();
    expect(builds, 1);
    controller.update((s) => s.copyWith(count: 1));
    await tester.pump();
    expect(builds, 2);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('replacement uses new controller and releases the old one', (
    tester,
  ) async {
    final first = ViewController(1);
    final second = ViewController(10);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget view(ViewController c) => host(
      JControllerBuilder<ViewState>(
        controller: c,
        builder: (_, s) => Text('${s.count}'),
      ),
    );
    await tester.pumpWidget(view(first));
    await tester.pumpWidget(view(second));
    expect(find.text('10'), findsOneWidget);
    first.update((s) => s.copyWith(count: 99));
    await tester.pump();
    expect(find.text('10'), findsOneWidget);
    second.update((s) => s.copyWith(count: 11));
    await tester.pump();
    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('a new selector recomputes even without a state notification', (
    tester,
  ) async {
    final controller = ViewController(2);
    addTearDown(controller.dispose);
    Widget view(bool count) => host(
      JControllerSelector<ViewState, String>(
        controller: controller,
        selector: (s) => count ? '${s.count}' : s.label,
        builder: (_, value) => Text(value),
      ),
    );
    await tester.pumpWidget(view(true));
    await tester.pumpWidget(view(false));
    expect(find.text('initial'), findsOneWidget);
    controller.update((s) => s.copyWith(label: 'new label'));
    await tester.pump();
    expect(find.text('new label'), findsOneWidget);
  });
}
