import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_action_template.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_playback_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_vfx_entries.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// [BattlePlaybackController] 单元测试 —— Task 4 抽离的收益：`playAction` 本体 +
/// 播放调度（pause/resume/fast-forward）从 `_BattleScreenState` 抽出后可直接单测。
///
/// 谐调 [WidgetRef] 依赖：控制器构造需 WidgetRef + TickerProvider + rebuild 回调，
/// WidgetRef 只在 widget 内存在，故用 [testWidgets] 搭一个 `ConsumerStatefulWidget`
/// harness（[TickerProviderStateMixin]，控制器内起多个 AnimationController），
/// initState 里构造控制器并经 GlobalKey 暴露，pumpWidget 后同步断言可观测状态。
///
/// numbersConfigProvider 不覆盖且 GameRepository 未加载 → `_impactConfigOrNull()`
/// 直接返 null，
/// playAction 的打击感/hit-stop 分支天然跳过（轻量测口径，同 battle_screen 的
/// 轻量 widget 测约定）；断言聚焦飘字/弹道/特效队列 + 调度标志等同步可观测态。

const _testAnim = AnimationNumbers(
  attackRushMs: 10,
  attackHoldMs: 10,
  attackRetreatMs: 10,
  attackRushOffsetPx: 20.0,
  damagePopupFloatPx: 20.0,
  damagePopupMs: 100,
  actionIntervalMs: 50,
  fastForwardIntervalMs: 20,
  shakeOffsetPx: 1.0,
  shakeDurationMs: 50,
  criticalFontScale: 1.5,
  projectileMs: 30,
  hitFlashMs: 30,
  readableActionIntervalMs: 2100,
);

/// 定住种子态、advance/step 全 no-op，避免 timer 触发真引擎推进。
class _NoopBattleNotifier extends BattleNotifier {
  _NoopBattleNotifier(this._initial);
  final BattleState _initial;

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void advanceOneAction({int maxConsecutiveSteps = 300}) {}

  @override
  void step() {}
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({super.key, this.readablePacing = false});

  final bool readablePacing;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness>
    with TickerProviderStateMixin {
  late final BattlePlaybackController controller;

  @override
  void initState() {
    super.initState();
    controller = BattlePlaybackController(
      vsync: this,
      ref: ref,
      rebuild: (fn) {
        if (mounted) setState(fn);
      },
      animConfig: _testAnim,
      readablePacing: widget.readablePacing,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// 非闪避命中结果（触发飘字/弹道/特效/受击闪）。
AttackResult _hitResult({bool crit = false}) => AttackResult(
  finalDamage: crit ? 240 : 120,
  mainDamage: crit ? 240 : 120,
  quakeDamage: 0,
  isCritical: crit,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: crit ? 1.5 : 1.0,
  defenseRate: 0.1,
  evasionRate: 0.0,
  appliedEffects: const [],
  formulaBreakdown: '',
);

const _projectileSkill = SkillDef(
  id: 'test_hidden_weapon',
  name: '飞针',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1000,
  qiDelta: -100,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'hidden_weapon',
);

const _projectileUltimate = SkillDef(
  id: 'test_flying_sword_ultimate',
  name: '御剑诀',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  qiDelta: -300,
  cooldownTurns: 5,
  requiresManualTrigger: true,
  visualEffect: 'flying_sword_art',
);

const _aoeSkill = SkillDef(
  id: 'test_aoe_skill',
  name: '落英掌',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1800,
  qiDelta: -180,
  cooldownTurns: 3,
  requiresManualTrigger: false,
  visualEffect: 'falling_petals',
  targetType: TargetType.aoe,
);

/// 左首(actorId=1) 攻 右首(targetId=11) 的动作。target 位于 teamSide=1
/// slotIndex=0 → slotKey = 1*3+0 = 3。
BattleAction _attackAction({bool crit = false, SkillDef? skill}) =>
    BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 11,
      skill: skill,
      attackResult: _hitResult(crit: crit),
      description: 'test hit',
    );

Future<_HarnessState> _pump(
  WidgetTester tester, {
  bool readablePacing = false,
  BattleState? state,
}) async {
  final key = GlobalKey<_HarnessState>();
  final (left, right) = BattleDemo.mockTeams();
  final initial =
      state ?? BattleState.initial(leftTeam: left, rightTeam: right);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() => _NoopBattleNotifier(initial)),
      ],
      child: MaterialApp(
        home: _Harness(key: key, readablePacing: readablePacing),
      ),
    ),
  );
  // 卸载 harness → State.dispose → controller.dispose，取消任何挂起 timer/ticker。
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  return key.currentState!;
}

// slotKey(teamSide=1, slotIndex=0) —— 右首 id=11 的飘字键。
const _targetSlotKey = 3;

void main() {
  testWidgets('playActions 三目标群攻共享演出一次且保留逐目标反馈', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);
    final targets = state.rightTeam.take(3).toList();

    c.playActions([
      for (final target in targets)
        BattleAction(
          tick: 1,
          actorId: state.leftTeam.first.characterId,
          targetId: target.characterId,
          skill: _aoeSkill,
          attackResult: _hitResult(),
          description: 'aoe hit',
        ),
    ], state);
    await tester.pump();

    expect(c.debugActiveEffectCount, 1, reason: '同拍群攻的中央流派特效应只生成一次');
    for (final target in targets) {
      expect(
        c.debugPopupsForSlot(target.teamSide * 3 + target.slotIndex),
        hasLength(1),
        reason: '每个命中目标都应保留独立伤害飘字',
      );
    }
    expect(c.debugActionTemplateForSlot(0), BattleActionTemplate.area);
  });

  testWidgets('playActions 群攻代表动作优先保留暴击特效', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);
    final targets = state.rightTeam.take(3).toList();

    c.playActions([
      for (var i = 0; i < targets.length; i++)
        BattleAction(
          tick: 1,
          actorId: state.leftTeam.first.characterId,
          targetId: targets[i].characterId,
          skill: _aoeSkill,
          attackResult: _hitResult(crit: i == 2),
          description: 'aoe hit',
        ),
    ], state);
    await tester.pump();

    expect(c.debugActiveEffectCount, 2, reason: '一个共享流派特效 + 一个末位目标暴击特效');
    expect(
      c
          .debugPopupsForSlot(
            targets.last.teamSide * 3 + targets.last.slotIndex,
          )
          .single
          .data
          .text,
      UiStrings.criticalDamagePopup(240),
    );
  });

  testWidgets('playActions 群攻非代表目标被击杀仍触发一次施放级特写', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);
    final targets = state.rightTeam.take(3).toList();

    c.playActions([
      for (var i = 0; i < targets.length; i++)
        BattleAction(
          tick: 1,
          actorId: state.leftTeam.first.characterId,
          targetId: targets[i].characterId,
          skill: _aoeSkill,
          attackResult: _hitResult(),
          description: 'aoe hit',
          defeatedTarget: i == targets.length - 1,
        ),
    ], state);

    expect(c.debugCloseupIsAnimating, isTrue);
    expect(c.debugActiveEffectCount, 1, reason: '击杀只提升共享反馈，不重复中央流派特效');
  });

  testWidgets('playActions 无击杀群攻不误触发特写', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);
    final targets = state.rightTeam.take(2).toList();

    c.playActions([
      for (final target in targets)
        BattleAction(
          tick: 1,
          actorId: state.leftTeam.first.characterId,
          targetId: target.characterId,
          skill: _aoeSkill,
          attackResult: _hitResult(),
          description: 'aoe hit',
        ),
    ], state);

    expect(c.debugCloseupIsAnimating, isFalse);
  });

  testWidgets('playActions 不同 tick 的连续群攻各播放一次共享演出', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);
    final targets = state.rightTeam.take(2).toList();

    c.playActions([
      for (final tick in [1, 2])
        for (final target in targets)
          BattleAction(
            tick: tick,
            actorId: state.leftTeam.first.characterId,
            targetId: target.characterId,
            skill: _aoeSkill,
            attackResult: _hitResult(),
            description: 'aoe hit',
          ),
    ], state);
    await tester.pump();

    expect(c.debugActiveEffectCount, 2, reason: '两次施放不得被跨 tick 合并');
  });

  testWidgets('playAction 命中 → 飘字入队 popups[slotKey] 且 id 递增', (tester) async {
    final c = (await _pump(tester)).controller;

    expect(c.debugPopupsForSlot(_targetSlotKey), isEmpty, reason: '初始无飘字');

    c.playAction(_attackAction(), c._noopState(tester));
    await tester.pump();
    final firstList = c.debugPopupsForSlot(_targetSlotKey);
    expect(firstList.length, 1, reason: '一次命中 → 一条飘字');
    expect(firstList.first.data.text, '120');
    final firstId = firstList.first.id;
    final firstAnchor = firstList.first.anchor;

    c.playAction(_attackAction(crit: true), c._noopState(tester));
    await tester.pump();
    final secondList = c.debugPopupsForSlot(_targetSlotKey);
    expect(secondList.length, 2, reason: '二次命中 → 队列增长');
    expect(secondList.last.data.text, UiStrings.criticalDamagePopup(240));
    expect(
      secondList.last.anchor,
      isNot(firstAnchor),
      reason: '连续飘字应围绕目标散开,避免固定点堆叠',
    );
    expect(
      secondList.map((e) => e.id).toSet().length,
      2,
      reason: '两条飘字 id 互异（_nextPopupId 递增）',
    );
    expect(secondList.last.id, greaterThan(firstId));
  });

  testWidgets('playAction 命中 → 弹道 / 特效队列增长', (tester) async {
    final c = (await _pump(tester)).controller;
    expect(c.debugActiveTrailCount, 0);
    expect(c.debugActiveEffectCount, 0);

    c.playAction(
      _attackAction(crit: true, skill: _projectileSkill),
      c._noopState(tester),
    );
    await tester.pump();

    expect(
      c.debugActiveTrailCount,
      greaterThan(0),
      reason: 'actor→target 弹道 spawn',
    );
    expect(
      c.debugActiveEffectCount,
      greaterThan(0),
      reason: '流派命中特效 + 暴击特效 spawn（spawnBattleEffects）',
    );
    expect(c.debugActionTemplateForSlot(0), BattleActionTemplate.projectile);
    expect(
      isUltimateCaptionSkill(_projectileUltimate),
      isTrue,
      reason: '远程交付不得降级技能类型或丢失大招题字入口',
    );
  });

  testWidgets('近战动作前冲但不生成远程弹道', (tester) async {
    final c = (await _pump(tester)).controller;

    c.playAction(_attackAction(), c._noopState(tester));
    await tester.pump();

    expect(c.debugActiveTrailCount, 0);
    expect(c.debugActionTemplateForSlot(0), BattleActionTemplate.melee);
    expect(c.debugActiveEffectCount, greaterThan(0));
  });

  testWidgets('onBattleRestarted 清空上一场瞬时反馈并复位动作模板与特写', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);
    c.playAction(
      BattleAction(
        tick: 1,
        actorId: 1,
        targetId: 11,
        skill: _projectileSkill,
        attackResult: _hitResult(),
        description: 'last battle kill',
        defeatedTarget: true,
      ),
      state,
    );

    expect(c.debugPopupsForSlot(_targetSlotKey), isNotEmpty);
    expect(c.debugActiveTrailCount, greaterThan(0));
    expect(c.debugActiveEffectCount, greaterThan(0));
    expect(c.debugCloseupIsAnimating, isTrue);

    c.onBattleRestarted();

    expect(c.debugPopupsForSlot(_targetSlotKey), isEmpty);
    expect(c.debugActiveTrailCount, 0);
    expect(c.debugActiveEffectCount, 0);
    expect(c.debugActionTemplateForSlot(0), BattleActionTemplate.melee);
    expect(c.debugCloseupIsAnimating, isFalse);

    // 执行旧演出控制器的 post-frame 释放，并排空 Riverpod 自动释放任务。
    await tester.pump();
    await tester.pump();
  });

  testWidgets('远程大招保留大招表现并生成施术者到目标的弹道', (tester) async {
    final c = (await _pump(tester)).controller;

    c.playAction(
      _attackAction(crit: true, skill: _projectileUltimate),
      c._noopState(tester),
    );
    await tester.pump();

    expect(c.debugActionTemplateForSlot(0), BattleActionTemplate.projectile);
    expect(
      c.debugActiveTrailCount,
      greaterThan(0),
      reason: '远程大招应补回施术者到目标的视觉联系',
    );
    expect(c.debugActiveEffectCount, greaterThan(0), reason: '大招既有流派命中特效仍应保留');
  });

  testWidgets('群战第 4–7 敌人的动作与受击安全归并到敌方后景表现槽', (tester) async {
    final (left, rightBase) = BattleDemo.mockTeams();
    final right = [
      for (var i = 0; i < 7; i++)
        rightBase[i % rightBase.length].copyWith(
          characterId: 100 + i,
          slotIndex: i,
          isAlive: true,
        ),
    ];
    final state = BattleState.initial(leftTeam: left, rightTeam: right);
    final c = (await _pump(tester, state: state)).controller;

    c.playAction(
      BattleAction(
        tick: 1,
        actorId: right.last.characterId,
        targetId: left.first.characterId,
        attackResult: _hitResult(),
        description: 'overflow actor hit',
      ),
      state,
    );
    c.playAction(
      BattleAction(
        tick: 2,
        actorId: left.first.characterId,
        targetId: right.last.characterId,
        attackResult: _hitResult(),
        description: 'overflow target hit',
      ),
      state,
    );
    await tester.pump();

    expect(c.debugActionTemplateForSlot(5), BattleActionTemplate.melee);
    expect(c.debugPopupsForSlot(5), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('同槽四条普通伤害飘字稳定散到四角', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);

    for (var tick = 1; tick <= 4; tick++) {
      c.playAction(
        BattleAction(
          tick: tick,
          actorId: 1,
          targetId: 11,
          attackResult: _hitResult(),
          description: 'multi hit',
        ),
        state,
      );
    }

    final anchors = c
        .debugPopupsForSlot(_targetSlotKey)
        .map((entry) => entry.anchor)
        .toSet();
    expect(anchors, hasLength(4));
    expect(anchors, isNot(contains(DamagePopupAnchor.centerBurst)));
  });

  testWidgets('同槽多条暴击仅首条占中央，其余散到四角', (tester) async {
    final c = (await _pump(tester)).controller;
    final state = c._noopState(tester);

    for (var tick = 1; tick <= 5; tick++) {
      c.playAction(
        BattleAction(
          tick: tick,
          actorId: 1,
          targetId: 11,
          attackResult: _hitResult(crit: true),
          description: 'multi critical',
        ),
        state,
      );
    }

    final entries = c.debugPopupsForSlot(_targetSlotKey);
    expect(entries.first.anchor, DamagePopupAnchor.centerBurst);
    expect(entries.map((entry) => entry.anchor).toSet(), hasLength(5));
  });

  testWidgets('pause / resume 调度标志', (tester) async {
    final c = (await _pump(tester)).controller;

    expect(c.hasTimer, isFalse, reason: '未起播 → 无 timer');
    c.startTimer();
    expect(c.hasTimer, isTrue, reason: '战斗未结束 → 起 timer');

    c.pause();
    expect(c.isPaused, isTrue);
    expect(c.hasTimer, isFalse, reason: '已取消的 Timer 不应继续报告为活跃');
    expect(c.debugBeatIsAnimating, isFalse, reason: '暂停冻结读秒环节拍');

    c.resume();
    expect(c.isPaused, isFalse, reason: '战斗未结束 → 恢复解除暂停');
  });

  testWidgets('hit-stop 期间播放拍钟与读秒环同步冻结，到期一起恢复', (tester) async {
    final c = (await _pump(tester)).controller;

    c.startTimer();
    await tester.pump(const Duration(milliseconds: 10));
    expect(c.hasTimer, isTrue);
    expect(c.debugBeatIsAnimating, isTrue);

    c.debugApplyHitStop(30);
    final frozenBeat = c.beat.value;
    expect(c.hasTimer, isFalse);
    expect(c.debugBeatIsAnimating, isFalse);

    await tester.pump(const Duration(milliseconds: 20));
    expect(c.beat.value, frozenBeat);
    expect(c.hasTimer, isFalse);

    await tester.pump(const Duration(milliseconds: 11));
    expect(c.hasTimer, isTrue);
    expect(c.debugBeatIsAnimating, isTrue);
  });

  testWidgets('toggleFastForward 翻转 isFastForward', (tester) async {
    final c = (await _pump(tester)).controller;
    expect(c.isFastForward, isFalse);
    c.toggleFastForward();
    expect(c.isFastForward, isTrue);
    c.toggleFastForward();
    expect(c.isFastForward, isFalse);
  });

  testWidgets('readablePacing 仅放慢常速播放,不影响快进间隔', (tester) async {
    final c = (await _pump(tester, readablePacing: true)).controller;

    expect(c.playbackIntervalMsForTest, _testAnim.readableActionIntervalMs);
    c.toggleFastForward();
    expect(c.playbackIntervalMsForTest, _testAnim.fastForwardIntervalMs);
  });
}

extension on BattlePlaybackController {
  /// 取当前种子 BattleState（controller 内部 ref 读的同一 provider 值），
  /// 供 playAction 第二参数。经 tester 的 element 取 ProviderScope container。
  BattleState _noopState(WidgetTester tester) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_Harness)),
    );
    return container.read(battleProvider);
  }
}
