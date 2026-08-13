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

  testWidgets('runtime overlay states the prototype boundary', (tester) async {
    await tester.pumpWidget(const Phase0bRuntimeApp());
    await tester.pump();

    expect(find.textContaining('POSE ATLAS PROTOTYPE'), findsOneWidget);
    expect(find.textContaining('不是骨骼动画'), findsOneWidget);
    expect(find.byKey(const ValueKey('phase0b-runtime-beat')), findsOneWidget);
  });
}
