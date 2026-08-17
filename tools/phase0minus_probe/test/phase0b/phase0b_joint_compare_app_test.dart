import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/joint/phase0b_joint_compare_app.dart';

void main() {
  testWidgets('compare labels both routes and preserves non-claims', (
    tester,
  ) async {
    await tester.pumpWidget(const Phase0bJointCompareApp());
    await tester.pump();

    expect(find.text('左：整帧姿态图集'), findsOneWidget);
    expect(find.text('右：分层关节木偶'), findsOneWidget);
    expect(find.textContaining('无蒙皮 / IK / 网格变形'), findsOneWidget);
    expect(find.textContaining('不是最终动画品质'), findsOneWidget);
  });
}
