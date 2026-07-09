import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_playback_controller.dart';
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

/// 左首(actorId=1) 攻 右首(targetId=11) 的普攻动作。target 位于 teamSide=1
/// slotIndex=0 → slotKey = 1*3+0 = 3。
BattleAction _attackAction({bool crit = false}) => BattleAction(
  tick: 1,
  actorId: 1,
  targetId: 11,
  attackResult: _hitResult(crit: crit),
  description: 'test hit',
);

Future<_HarnessState> _pump(
  WidgetTester tester, {
  bool readablePacing = false,
}) async {
  final key = GlobalKey<_HarnessState>();
  final (left, right) = BattleDemo.mockTeams();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(
          () => _NoopBattleNotifier(
            BattleState.initial(leftTeam: left, rightTeam: right),
          ),
        ),
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
  testWidgets('playAction 命中 → 飘字入队 popups[slotKey] 且 id 递增', (tester) async {
    final c = (await _pump(tester)).controller;

    expect(c.popups[_targetSlotKey], isNull, reason: '初始无飘字');

    c.playAction(_attackAction(), c._noopState(tester));
    await tester.pump();
    final firstList = c.popups[_targetSlotKey];
    expect(firstList, isNotNull);
    expect(firstList!.length, 1, reason: '一次命中 → 一条飘字');
    expect(firstList.first.data.text, '120');
    final firstId = firstList.first.id;
    final firstAnchor = firstList.first.anchor;

    c.playAction(_attackAction(crit: true), c._noopState(tester));
    await tester.pump();
    final secondList = c.popups[_targetSlotKey]!;
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
    expect(c.activeTrails, isEmpty);
    expect(c.activeEffects, isEmpty);

    c.playAction(_attackAction(crit: true), c._noopState(tester));
    await tester.pump();

    expect(c.activeTrails, isNotEmpty, reason: 'actor→target 弹道 spawn');
    expect(
      c.activeEffects,
      isNotEmpty,
      reason: '流派命中特效 + 暴击特效 spawn（spawnBattleEffects）',
    );
  });

  testWidgets('pause / resume 调度标志', (tester) async {
    final c = (await _pump(tester)).controller;

    expect(c.hasTimer, isFalse, reason: '未起播 → 无 timer');
    c.startTimer();
    expect(c.hasTimer, isTrue, reason: '战斗未结束 → 起 timer');

    c.pause();
    expect(c.isPaused, isTrue);
    expect(c.beatCtrl.isAnimating, isFalse, reason: '暂停冻结读秒环节拍');

    c.resume();
    expect(c.isPaused, isFalse, reason: '战斗未结束 → 恢复解除暂停');
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
