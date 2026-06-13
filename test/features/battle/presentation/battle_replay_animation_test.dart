import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_replay.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

/// 半手动战斗 P0 步骤5-E:BattleScreen replay 动画驱动。
///
/// autoReplay 模式下 BattleScreen 自动驱动战斗(autoStart),但每个 Timer tick
/// **用 [BattleNotifier.step]**(每整数 tick 可观测,命中 op 锚点)而非 advance
/// (批量跳 tick 漏锚点),并在 `state.tick == op.anchor` 注入 requestUltimate。
/// 与 `BattleNotifier.replay` 同语义(确定性已由 battle_replay_execution_test
/// 锁死),本测验证 driver wiring:在锚点注入 + 用 step + 战斗结束停。
const _testAnim = AnimationNumbers(
  attackRushMs: 10,
  attackHoldMs: 10,
  attackRetreatMs: 10,
  attackRushOffsetPx: 20.0,
  damagePopupFloatPx: 20.0,
  damagePopupMs: 100,
  actionIntervalMs: 20,
  fastForwardIntervalMs: 10,
  shakeOffsetPx: 1.0,
  shakeDurationMs: 50,
  criticalFontScale: 1.5,
  projectileMs: 30,
  hitFlashMs: 30,
);

const _power = SkillDef(
  id: 'p_replay',
  name: '崩山拳',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  internalForceCost: 200,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);

/// 驱动记录 notifier:step() 推进 tick 并在 [_finishAfter] 步后置 leftWin;
/// requestUltimate 记录注入序列。不跑真内核(确定性已另测锁)。
class _ReplayDriveNotifier extends BattleNotifier {
  _ReplayDriveNotifier(this._left, this._right, this._finishAfter);
  final List<BattleCharacter> _left;
  final List<BattleCharacter> _right;
  final int _finishAfter;

  int stepCount = 0;
  int advanceCount = 0;
  final List<({int charId, String skillId, int? targetId, int atTick})> injected =
      [];

  @override
  BattleState build() =>
      BattleState.initial(leftTeam: const [], rightTeam: const []);

  void begin() {
    state = BattleState.initial(leftTeam: _left, rightTeam: _right);
  }

  @override
  void step() {
    stepCount++;
    final t = state.tick + 1;
    state = state.copyWith(
      tick: t,
      result: t >= _finishAfter ? BattleResult.leftWin : null,
    );
  }

  @override
  void advance({int maxConsecutiveTicks = 100}) {
    advanceCount++;
  }

  @override
  void requestUltimate(int characterId, SkillDef ultimate, {int? targetId}) {
    injected.add((
      charId: characterId,
      skillId: ultimate.id,
      targetId: targetId,
      atTick: state.tick,
    ));
  }
}

BattleCharacter _unit(int charId, int side, int slot) => BattleCharacter(
      characterId: charId,
      name: '$charId',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 2000,
      currentInternalForce: 2000,
      speed: 110,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.1,
      totalEquipmentAttack: 700,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const <SkillDef>[_power],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: side,
      slotIndex: slot,
    );

void main() {
  testWidgets('replay 驱动: 锚点注入 ops + 用 step 推进 + 结束停', (tester) async {
    final left = [_unit(1, 0, 0)];
    final right = [_unit(-1, 1, 0)];
    const ops = [
      BattleReplayOp(anchor: 0, charId: 1, skillId: 'p_replay', targetId: -1),
      BattleReplayOp(anchor: 2, charId: 1, skillId: 'p_replay', targetId: -1),
    ];
    late _ReplayDriveNotifier notifier;

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleProvider.overrideWith(() {
            notifier = _ReplayDriveNotifier(left, right, 5);
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: BattleScreen(
            animConfig: _testAnim,
            replaySeed: 999,
            replayOps: ops,
          ),
        ),
      ),
    );

    // 触发 startBattle 等价的 empty→nonempty 转换 → 启 replay timer。
    notifier.begin();
    await tester.pump();

    // 推进 Timer 至战斗结束(5 步 × 20ms + 余量)。
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(notifier.stepCount, greaterThanOrEqualTo(5), reason: 'replay 用 step 驱动');
    expect(notifier.advanceCount, 0, reason: 'replay 路径不走 advance(批量跳 tick 漏锚点)');
    // 两个 op 各在自己锚点 tick 注入。
    expect(notifier.injected.map((e) => e.atTick), containsAll(<int>[0, 2]),
        reason: 'ops 在 anchor tick 注入');
    expect(notifier.injected, hasLength(2));
    expect(notifier.injected.every((e) => e.skillId == 'p_replay'), isTrue);

    await tester.pumpWidget(const SizedBox()); // 卸载,停 timer
  });
}
