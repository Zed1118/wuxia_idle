import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_event_order_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';

void main() {
  test('同一原始事件产生稳定只读 canonical projection', () {
    const source = Phase0aAttackStarted(
      seq: 3,
      tick: 7,
      actor: 'player',
      moveKind: Phase0aMoveKind.light,
    );
    final first = Phase0aEventOrderAdapter.project([source]);
    final second = Phase0aEventOrderAdapter.toCombatEventRecords([source]);

    expect(first, second);
    expect(first.single.eventId, contains('attack_started'));
    expect(first.single.tick, 7);
    expect(first.single.stage, CombatEventStage.startup);
    expect(() => first.add(first.single), throwsUnsupportedError);
  });

  test('输入不可变且 live/headless 等价输入得到相同结果', () {
    final input = <Phase0aEvent>[
      const Phase0aAttackStarted(
        seq: 1,
        tick: 2,
        actor: 'player',
        moveKind: Phase0aMoveKind.heavy,
      ),
      const Phase0aBattleDefeat(seq: 2, tick: 3),
    ];
    final before = List<Phase0aEvent>.of(input);
    final live = Phase0aEventOrderAdapter.project(input);
    final headless = Phase0aEventOrderAdapter.project(List.of(input));

    expect(input, before);
    expect(live, headless);
    expect(live.last.feedKind, CombatFeedKind.defeat);
    expect(live.last.stage, CombatEventStage.presentation);
  });

  test('重复或未排序 seq fail closed', () {
    const first = Phase0aAttackStarted(
      seq: 2,
      tick: 2,
      actor: 'player',
      moveKind: Phase0aMoveKind.light,
    );
    const duplicate = Phase0aBattleVictory(seq: 2, tick: 2);
    const earlier = Phase0aBattleVictory(seq: 1, tick: 2);

    expect(
      () => Phase0aEventOrderAdapter.project([first, duplicate]),
      throwsArgumentError,
    );
    expect(
      () => Phase0aEventOrderAdapter.project([first, earlier]),
      throwsArgumentError,
    );
  });

  test('同拍领域阶段映射保持 C10 顺序', () {
    final records = Phase0aEventOrderAdapter.project([
      const Phase0aSkillAvailabilityChanged(
        seq: 1,
        tick: 4,
        slot: '1',
        availability: Phase0aSkillAvailability.ready,
      ),
      const Phase0aAttackStarted(
        seq: 2,
        tick: 4,
        actor: 'player',
        moveKind: Phase0aMoveKind.light,
      ),
      const Phase0aHitLanded(
        seq: 3,
        tick: 4,
        actor: 'player',
        target: 'enemy',
        moveKind: Phase0aMoveKind.light,
        isCritical: false,
        isUltimate: false,
        resolvedDamage: 1,
        remainingHealth: 9,
      ),
    ]);
    expect(records.map((record) => record.stage), [
      CombatEventStage.legalityAndResources,
      CombatEventStage.startup,
      CombatEventStage.damageAndPosture,
    ]);
  });
}
