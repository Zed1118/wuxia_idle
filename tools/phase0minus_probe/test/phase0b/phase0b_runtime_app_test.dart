import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/phase0b_runtime_app.dart';

void main() {
  test('six-pose atlas partitions non-divisible dimensions without gaps', () {
    const size = Size(1672, 941);
    final cells = List.generate(
      6,
      (index) => Phase0bRuntimeGame.atlasCellRectForSize(size, index),
    );

    expect(cells.first, const Rect.fromLTWH(0, 0, 1672 / 3, 941 / 2));
    expect(cells[2].right, size.width);
    expect(cells[3].top, 941 / 2);
    expect(cells.last.right, size.width);
    expect(cells.last.bottom, size.height);
    expect(
      () => Phase0bRuntimeGame.atlasCellRectForSize(size, 6),
      throwsRangeError,
    );
  });

  test('bandit atlas can move the row divider past top-pose boots', () {
    const size = Size(1672, 941);
    const divider = 500 / 941;
    final top = Phase0bRuntimeGame.atlasCellRectForSize(
      size,
      2,
      rowDividerRatio: divider,
    );
    final bottom = Phase0bRuntimeGame.atlasCellRectForSize(
      size,
      5,
      rowDividerRatio: divider,
    );

    expect(top.bottom, closeTo(500, 0.0001));
    expect(bottom.top, closeTo(500, 0.0001));
    expect(bottom.bottom, 941);
  });

  test('elite atlas partitions a 2x2 sheet', () {
    const size = Size(1254, 1254);
    final last = Phase0bRuntimeGame.atlasCellRectForSize(
      size,
      3,
      columns: 2,
      rows: 2,
    );

    expect(last, const Rect.fromLTWH(627, 627, 627, 627));
    expect(
      () =>
          Phase0bRuntimeGame.atlasCellRectForSize(size, 4, columns: 2, rows: 2),
      throwsRangeError,
    );
  });

  testWidgets('runtime overlay states the prototype boundary', (tester) async {
    await tester.pumpWidget(const Phase0bRuntimeApp());
    await tester.pump();

    expect(find.textContaining('1 主角 + 6 杂兵 + 1 精英'), findsOneWidget);
    expect(find.textContaining('不是骨骼动画'), findsOneWidget);
    expect(find.byKey(const ValueKey('phase0b-runtime-beat')), findsOneWidget);
  });
}
