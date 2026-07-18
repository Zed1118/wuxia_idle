import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import '../../../support/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 首通展示帧 BattleScreen 集成:开局亮相延迟起手 / 敌方首次蓄力提示 /
/// 破招题字强化。沿 start_paused_test 轻量 setUp(override battleProvider,
/// no-op advance,避免 Timer 真 tick 读 GameRepository 崩)。
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
  firstClearOpeningHoldMs: 300,
  firstClearFirstSkillHoldMs: 200,
  firstClearBossChargeHoldMs: 200,
);

const _powerSkill = SkillDef(
  id: 'power_1',
  name: '崩山掌',
  description: 'd',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  internalForceCost: 60,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'none',
);

const _hit = AttackResult(
  finalDamage: 1500,
  mainDamage: 1500,
  quakeDamage: 0,
  isCritical: false,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.0,
  defenseRate: 0.15,
  evasionRate: 0.05,
  appliedEffects: <String>[],
  formulaBreakdown: 'test',
);

/// no-op advance(不触发真 tick)+ 计数 advanceOneAction;emit 直接置 state
/// 驱动 ref.listen 边沿。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  int advanceOneActionCalls = 0;

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void advanceOneAction({int maxConsecutiveSteps = 300}) {
    advanceOneActionCalls++;
  }

  void emit(BattleState s) => state = s;
}

Future<_TestBattleNotifier> _pumpBattle(
  WidgetTester tester, {
  required bool firstClearShowcase,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final (left, right) = BattleDemo.mockTeams();
  final notifier = _TestBattleNotifier(
    BattleState.initial(leftTeam: left, rightTeam: right),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [battleProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        home: BattleScreen(
          animConfig: _testAnim,
          playback: BattleScreenPlaybackConfig(
            autoStartOnMount: true,
            firstClearShowcase: firstClearShowcase,
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // postFrame:autoStartOnMount → startTimer
  await tester.pump(); // 开局题字若走 postFrame 兜底再补一帧
  return notifier;
}

void main() {
  testWidgets('首通开局亮相:题字出现 + 起手停顿内不推进,停顿后自动起拍', (tester) async {
    final notifier = await _pumpBattle(tester, firstClearShowcase: true);
    // 开局亮相题字在场。
    expect(find.text(UiStrings.firstClearOpening), findsWidgets);
    // 停顿(300ms)内:拍钟未启动,无自动推进(对照:常规 50ms 拍早该 tick)。
    await tester.pump(const Duration(milliseconds: 100));
    expect(notifier.advanceOneActionCalls, 0, reason: '开局停顿内不应推进战斗');
    // 停顿结束后拍钟启动,开始自动推进。
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      notifier.advanceOneActionCalls,
      greaterThan(0),
      reason: '停顿结束后应自动起拍',
    );
  });

  testWidgets('生产入口竞态回归:挂载后才翻 firstClearShowcase,起拍前补挂生效', (tester) async {
    // 复刻 StageEntryFlow 真实时序:首通判定在 postFrame 异步落定,首帧以
    // false 挂空团 BattleScreen → setState 翻 true(didUpdateWidget 透传)→
    // startBattle 空→非空边沿起拍。修复前 _showcase 构造期定死 null,
    // 生产首通四拍整套丢失(2026-07-14 真机 T4 实测发现)。
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notifier = _TestBattleNotifier(
      BattleState.initial(leftTeam: const [], rightTeam: const []),
    );
    Future<void> pumpHost({required bool showcase}) => tester.pumpWidget(
      ProviderScope(
        overrides: [battleProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          home: BattleScreen(
            animConfig: _testAnim,
            playback: BattleScreenPlaybackConfig(
              autoStartOnMount: true,
              firstClearShowcase: showcase,
            ),
          ),
        ),
      ),
    );

    // 首帧:判定未落定(false)+ 空团不起拍,无题字。
    await pumpHost(showcase: false);
    await tester.pump();
    expect(find.text(UiStrings.firstClearOpening), findsNothing);

    // 异步判定落定:同一屏翻 true(didUpdateWidget → setFirstClearShowcase)。
    await pumpHost(showcase: true);
    // startBattle:空→非空边沿起拍(build 内 ref.listen 生产同路径)。
    final (left, right) = BattleDemo.mockTeams();
    notifier.emit(BattleState.initial(leftTeam: left, rightTeam: right));
    await tester.pump(); // 空团 placeholder → 战斗 body 挂载
    await tester.pump(); // 开局题字 postFrame 兜底补一帧(同 _pumpBattle 注释)

    // 开局亮相题字在场 + 停顿内不推进(修复前:无题字且 50ms 拍立即推进)。
    expect(find.text(UiStrings.firstClearOpening), findsWidgets);
    await tester.pump(const Duration(milliseconds: 100));
    expect(notifier.advanceOneActionCalls, 0, reason: '补挂后开局停顿应生效');
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      notifier.advanceOneActionCalls,
      greaterThan(0),
      reason: '停顿结束后应自动起拍',
    );
  });

  testWidgets('非首通:无开局题字,立即起拍(现有路径回归)', (tester) async {
    final notifier = await _pumpBattle(tester, firstClearShowcase: false);
    expect(find.text(UiStrings.firstClearOpening), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      notifier.advanceOneActionCalls,
      greaterThan(0),
      reason: '非首通无停顿,50ms 拍应已推进',
    );
  });

  testWidgets('首通敌方首次蓄力:教学题字出现', (tester) async {
    final notifier = await _pumpBattle(tester, firstClearShowcase: true);
    // 放完开局停顿,进入常规播放。
    await tester.pump(const Duration(milliseconds: 400));
    // 敌方首个角色起手蓄力(chargingSkill null→非null 边沿)。
    final s = notifier.state;
    final charged = s.rightTeam.first.copyWith(chargingSkill: _powerSkill);
    notifier.emit(s.copyWith(rightTeam: [charged, ...s.rightTeam.skip(1)]));
    await tester.pump();
    expect(find.text(UiStrings.firstClearChargeCue), findsWidgets);
  });

  testWidgets('首通玩家破招:题字用峰值字号(非首通走基准 56)', (tester) async {
    final notifier = await _pumpBattle(tester, firstClearShowcase: true);
    await tester.pump(const Duration(milliseconds: 400));
    final s = notifier.state;
    final action = BattleAction(
      tick: 1,
      actorId: s.leftTeam.first.characterId,
      targetId: s.rightTeam.first.characterId,
      skill: _powerSkill,
      attackResult: _hit,
      description: 'd',
      interrupted: true,
    );
    notifier.emit(s.copyWith(actionLog: [...s.actionLog, action]));
    await tester.pump();
    final texts = tester.widgetList<Text>(
      find.text(UiStrings.interruptCaption),
    );
    expect(texts, isNotEmpty);
    for (final t in texts) {
      expect(
        t.style?.fontSize,
        _testAnim.hitTier.captionPeakSize.toDouble(),
        reason: '首通破招题字应用峰值字号',
      );
    }
  });

  testWidgets('非首通玩家破招:题字基准字号 56(回归)', (tester) async {
    final notifier = await _pumpBattle(tester, firstClearShowcase: false);
    await tester.pump(const Duration(milliseconds: 100));
    final s = notifier.state;
    final action = BattleAction(
      tick: 1,
      actorId: s.leftTeam.first.characterId,
      targetId: s.rightTeam.first.characterId,
      skill: _powerSkill,
      attackResult: _hit,
      description: 'd',
      interrupted: true,
    );
    notifier.emit(s.copyWith(actionLog: [...s.actionLog, action]));
    await tester.pump();
    final texts = tester.widgetList<Text>(
      find.text(UiStrings.interruptCaption),
    );
    expect(texts, isNotEmpty);
    for (final t in texts) {
      expect(t.style?.fontSize, 56, reason: '非首通破招题字保持基准字号');
    }
  });
}
