import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';

/// B2.4 总览「下一节点剩余时间」(§7.1) 依赖的节点时长曲线 + 剩余时间纯函数。
/// 与 settle `_completedNodesBy` 的完成节点判定共用同一单调曲线(绝对时间锚定)。
void main() {
  const normal = 100;
  const elite = 300;

  group('nodeDurationMinutes', () {
    test('普通节点取 normalMinutes，险关(5 的倍数)取 eliteMinutes', () {
      expect(
        ExpeditionRules.nodeDurationMinutes(3,
            normalMinutes: normal, eliteMinutes: elite),
        normal,
      );
      expect(
        ExpeditionRules.nodeDurationMinutes(5,
            normalMinutes: normal, eliteMinutes: elite),
        elite,
      );
      expect(
        ExpeditionRules.nodeDurationMinutes(10,
            normalMinutes: normal, eliteMinutes: elite),
        elite,
      );
    });
  });

  group('cumulativeMinutesToCompleteNode', () {
    int cum(int node) => ExpeditionRules.cumulativeMinutesToCompleteNode(
          node,
          normalMinutes: normal,
          eliteMinutes: elite,
        );

    test('node ≤ 0 → 0', () {
      expect(cum(0), 0);
      expect(cum(-3), 0);
    });

    test('逐节点累计，险关按 elite 计入', () {
      expect(cum(1), 100); // 节点1 普通
      expect(cum(4), 400); // 1-4 全普通
      expect(cum(5), 700); // + 节点5 险关(300)
      expect(cum(6), 800); // + 节点6 普通
      expect(cum(10), 1400); // 8 普通 ×100 + 2 险关(5,10) ×300
    });
  });

  group('nextNodeRemaining', () {
    final departedAt = DateTime(2026, 7, 16, 0, 0);
    Duration remaining(int completedNodes, DateTime now) =>
        ExpeditionRules.nextNodeRemaining(
          departedAt: departedAt,
          completedNodes: completedNodes,
          now: now,
          normalMinutes: normal,
          eliteMinutes: elite,
        );

    test('出发瞬间：距下一节点(第1个)完成 = 该节点全时长', () {
      expect(remaining(0, departedAt), const Duration(minutes: 100));
    });

    test('过去一半：剩余 = 半时长', () {
      expect(
        remaining(0, departedAt.add(const Duration(minutes: 40))),
        const Duration(minutes: 60),
      );
    });

    test('now 已越过下一节点完成时刻 → 归零(可结算未追平)', () {
      expect(
        remaining(0, departedAt.add(const Duration(minutes: 100))),
        Duration.zero,
      );
      expect(
        remaining(0, departedAt.add(const Duration(minutes: 150))),
        Duration.zero,
      );
    });

    test('已完成 4 节点：下一节点(第5=险关)剩余按 elite 全时长', () {
      // now = 出发 + 累计到节点4(400min)，下一节点5(险关300)刚开始。
      expect(
        remaining(4, departedAt.add(const Duration(minutes: 400))),
        const Duration(minutes: 300),
      );
    });
  });
}
