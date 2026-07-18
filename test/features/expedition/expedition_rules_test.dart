import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart'
    show ExpeditionPolicy;

void main() {
  test('每 5 的倍数节点为险关（精英战）', () {
    for (final n in [5, 10, 15, 20, 25, 30]) {
      expect(ExpeditionRules.isEliteNode(n), isTrue, reason: 'node $n');
    }
    for (final n in [1, 4, 7, 11, 29]) {
      expect(ExpeditionRules.isEliteNode(n), isFalse, reason: 'node $n');
    }
  });

  test('相同 saveId/runSerial/node 生成相同节点类型（稳定）', () {
    ExpeditionNode gen(int n) => ExpeditionRules.generateNode(
      saveId: 1,
      runSerial: 2,
      node: n,
      policy: ExpeditionPolicy.yanJingCaiYao,
    );
    expect(gen(7).type, gen(7).type);
    // 险关恒为遭遇型险关
    expect(gen(10).type, ExpeditionNodeType.xianGuan);
  });

  test('沿径采药方针偏采药节点（权重生效，统计意义）', () {
    var caiYao = 0;
    for (var n = 1; n <= 200; n++) {
      if (n % 5 == 0) continue; // 排除险关
      if (ExpeditionRules.generateNode(
            saveId: 1,
            runSerial: 1,
            node: n,
            policy: ExpeditionPolicy.yanJingCaiYao,
          ).type ==
          ExpeditionNodeType.caiYao) {
        caiYao++;
      }
    }
    // 采药方针下采药占比应显著高于均分（4 类普通节点均分 25%）
    expect(caiYao / 160.0, greaterThan(0.35));
  });
}
