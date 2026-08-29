import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';

Phase0aActor _actor(
  String id,
  Phase0aSide side,
  ArenaVector position, {
  Phase0aDefeatKind defeatKind = Phase0aDefeatKind.normal,
  bool isBoss = false,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: ArenaVector.zero,
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: defeatKind,
  isBoss: isBoss,
);

Phase0aArenaState _state() => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _actor('player', Phase0aSide.player, ArenaVector.zero),
  enemies: [
    _actor('normal_a', Phase0aSide.enemy, const ArenaVector(20, 20)),
    _actor('normal_b', Phase0aSide.enemy, const ArenaVector(-30, -40)),
    _actor(
      'elite',
      Phase0aSide.enemy,
      const ArenaVector(50, 0),
      defeatKind: Phase0aDefeatKind.elite,
    ),
    _actor(
      'boss',
      Phase0aSide.enemy,
      const ArenaVector(80, 10),
      defeatKind: Phase0aDefeatKind.elite,
      isBoss: true,
    ),
  ],
  skillSlots: const [],
);

const _clear = Phase0aClearApplied(
  seq: 7,
  tick: 3,
  actor: 'player',
  outcomes: [
    Phase0aSkillOutcome(
      target: 'normal_a',
      resolvedDamage: 11,
      isCritical: false,
      defeated: false,
      statusApplied: Phase0aSkillStatus.none,
      targetPosition: ArenaVector(20, 20),
    ),
    Phase0aSkillOutcome(
      target: 'normal_b',
      resolvedDamage: 29,
      isCritical: true,
      defeated: false,
      statusApplied: Phase0aSkillStatus.none,
      targetPosition: ArenaVector(-30, -40),
    ),
    Phase0aSkillOutcome(
      target: 'elite',
      resolvedDamage: 31,
      isCritical: false,
      defeated: false,
      statusApplied: Phase0aSkillStatus.none,
      targetPosition: ArenaVector(50, 0),
    ),
    Phase0aSkillOutcome(
      target: 'boss',
      resolvedDamage: 41,
      isCritical: false,
      defeated: false,
      statusApplied: Phase0aSkillStatus.none,
      targetPosition: ArenaVector(80, 10),
    ),
  ],
);

Phase0aVfxEntry _popup(Phase0aDamagePopupTargetClass targetClass) =>
    Phase0aVfxEntry(
      kind: Phase0aVfxKind.damagePopup,
      damage: 10,
      damageGroupId: targetClass.index + 100,
      damageTargetClass: targetClass,
    );

void main() {
  test('原始逐目标语义保留，普通怪按同一攻击组聚合，精英与 Boss 独立', () {
    final controller = Phase0aVfxController()..syncActors(_state());
    final raw = controller
        .consume(const [_clear])
        .where((entry) => entry.kind == Phase0aVfxKind.damagePopup)
        .toList();

    expect(raw, hasLength(4), reason: 'VFX 映射层不得丢逐目标结算语义');
    expect(raw.map((entry) => entry.damageGroupId).toSet(), {7});
    expect(raw.map((entry) => entry.damageTargetClass).toList(), const [
      Phase0aDamagePopupTargetClass.ordinaryEnemy,
      Phase0aDamagePopupTargetClass.ordinaryEnemy,
      Phase0aDamagePopupTargetClass.eliteEnemy,
      Phase0aDamagePopupTargetClass.boss,
    ]);

    final displayed = const Phase0aDamagePopupAggregator().collapse(raw);
    expect(displayed, hasLength(3));
    final ordinary = displayed.singleWhere(
      (entry) =>
          entry.damageTargetClass ==
          Phase0aDamagePopupTargetClass.ordinaryEnemy,
    );
    expect(ordinary.damage, 40);
    expect(ordinary.hitCount, 2);
    expect(ordinary.targetId, isNull);
    expect(ordinary.isCritical, isTrue);
    expect(ordinary.anchor, const ArenaVector(-30, -40));
    expect(
      displayed
          .where(
            (entry) =>
                entry.damageTargetClass ==
                    Phase0aDamagePopupTargetClass.eliteEnemy ||
                entry.damageTargetClass == Phase0aDamagePopupTargetClass.boss,
          )
          .map((entry) => entry.hitCount),
      everyElement(1),
    );
  });

  test('玩家承伤分类来自同步 actor，不能由 target id 字符串猜测', () {
    final controller = Phase0aVfxController()..syncActors(_state());
    final popup = controller
        .consume(const [
          Phase0aHitLanded(
            seq: 8,
            tick: 4,
            actor: 'normal_a',
            target: 'player',
            moveKind: Phase0aMoveKind.light,
            isCritical: false,
            isUltimate: false,
            resolvedDamage: 17,
            remainingHealth: 83,
          ),
        ])
        .singleWhere((entry) => entry.kind == Phase0aVfxKind.damagePopup);

    expect(popup.damageTargetClass, Phase0aDamagePopupTargetClass.player);
    expect(popup.damageGroupId, 8);
    expect(popup.hitCount, 1);
  });

  test('居民池满时玩家伤害淘汰普通组，普通新组不得挤掉全玩家池', () {
    final ordinaryResidents = List<Phase0aVfxEntry>.generate(
      8,
      (_) => _popup(Phase0aDamagePopupTargetClass.ordinaryEnemy),
    );
    expect(
      Phase0aDamagePopupResidentPolicy.evictionIndex(
        ordinaryResidents,
        _popup(Phase0aDamagePopupTargetClass.player),
      ),
      0,
    );

    final playerResidents = List<Phase0aVfxEntry>.generate(
      8,
      (_) => _popup(Phase0aDamagePopupTargetClass.player),
    );
    expect(
      Phase0aDamagePopupResidentPolicy.evictionIndex(
        playerResidents,
        _popup(Phase0aDamagePopupTargetClass.ordinaryEnemy),
      ),
      -1,
    );
  });

  test('伤害数字绘制优先级低于蓄力危险与破势反馈', () {
    expect(
      phase0aVfxPaintPriority(Phase0aVfxKind.damagePopup),
      lessThan(phase0aVfxPaintPriority(Phase0aVfxKind.bossChargeWarning)),
    );
    expect(
      phase0aVfxPaintPriority(Phase0aVfxKind.damagePopup),
      lessThan(phase0aVfxPaintPriority(Phase0aVfxKind.postureBroken)),
    );
  });
}
