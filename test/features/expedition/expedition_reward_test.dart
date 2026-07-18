import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';

void main() {
  test('第 10/20/30 节点固定含一张断魂帖（§4.4 里程碑）', () {
    final r = ExpeditionRules.rewardsForNode(
      node: const ExpeditionNode(
        index: 10,
        type: ExpeditionNodeType.xianGuan,
        durationMinutes: 180,
      ),
      saveId: 1,
      runSerial: 1,
    );
    expect(r.quantityOf('item_duanhuntie'), 1);
  });
  test('采药节点产药草/灵泉水（rewardKey 走 defId，非中文散写）', () {
    final r = ExpeditionRules.rewardsForNode(
      node: const ExpeditionNode(
        index: 1,
        type: ExpeditionNodeType.caiYao,
        durationMinutes: 90,
      ),
      saveId: 1,
      runSerial: 1,
    );
    expect(r.any((e) => e.rewardKey.startsWith('item_')), isTrue);
    expect(r.quantityOf('item_duanhuntie'), 0);
  });
  test('第 30 节点后单位时间奖励不再增长（§4.5 封顶）', () {
    int expAt(int node) => ExpeditionRules.rewardsForNode(
      node: ExpeditionNode(
        index: node,
        type: ExpeditionNodeType.zaoYu,
        durationMinutes: 90,
      ),
      saveId: 1,
      runSerial: 1,
    ).quantityOf('exp');
    expect(expAt(35), lessThanOrEqualTo(expAt(30)));
  });
}
