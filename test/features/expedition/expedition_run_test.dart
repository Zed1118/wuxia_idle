import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

void main() {
  test('ExpeditionRun 默认值与方针枚举可用', () {
    final run = ExpeditionRun()
      ..saveDataId = 1
      ..policy = ExpeditionPolicy.yanJingCaiYao
      ..seed = 12345
      ..departedAt = DateTime(2026, 7, 15)
      ..currentNode = 3;
    expect(run.currentNode, 3);
    expect(run.policy, ExpeditionPolicy.yanJingCaiYao);
    expect(run.lastSettledAt, isNull);
    expect(run.members, isEmpty);
    expect(ExpeditionPolicy.values.length, 3);
  });
}
