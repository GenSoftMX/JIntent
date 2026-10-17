import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class _Point extends JEquatable {
  const _Point(this.x, this.y);
  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];
}

void main() {
  test('JEquatable compares by props', () {
    expect(const _Point(1, 2), const _Point(1, 2));
    expect(const _Point(1, 2), isNot(const _Point(2, 1)));
  });

  test('JEquatable enables a readable toString', () {
    expect(const _Point(1, 2).toString(), '_Point(1, 2)');
  });
}
