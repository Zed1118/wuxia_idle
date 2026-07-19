import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/battle_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/mass_battle_strategy.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/battle_demo.dart';
import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// 阵型选择分支行为级测试（目标 2 · 2026-07-19）。
///
/// 覆盖对象（stage_entry_flow.dart）：
///   - `_StageBattleHostState.initState` 群战分支（L512-531）：massBattle 关
///     真装配链（gameplaySettings → MainlineProgress → StageBattleSetup.buildTeams
///     → buildEnemyTeamsPerWave）走到 `_pickFormation`；
///   - `_pickFormation`（L1199-1215）+ `_FormationPickerDialog`（L1217-1259）：
///     三阵型可选态 / 默认预选 / 选择结果落战斗装配 / 未选回退默认。
///
/// **wiring 方案**：不注入 battle*ForTest（走真实 `_runBattle` → 真实 host）；
/// 仅 override battleProvider 为录制 notifier——`startBattle` 是 host 群战分支
/// 的唯一出口，录制 strategy 即行为级观测点，阵型烘焙再经 strategy 直验
/// （applyFormationTo 体例,不跑完整战斗）。真 Isar（fallback 单人队）+
/// SharedPreferences mock 支撑 initState 装配链,全部真时钟交互收进 runAsync。
void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  StageDef massStage() => const StageDef(
    id: 'stage_formation_probe',
    name: '测试群战关',
    stageType: StageType.massBattle,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [
      EnemyDef(
        id: 'enemy_formation_probe',
        name: '测试守军',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        baseHp: 1000,
        baseAttack: 500,
        baseSpeed: 100,
        skillIds: [],
        iconPath: '',
      ),
    ],
    isBossStage: false,
    baseExpReward: 0,
    difficultyMultiplier: 1.0,
    massBattleEnemyCounts: [1],
  );

  /// P3 种子(id=1 角色 + 主修 + 装备,沿 stage_battle_setup_test 配方)——
  /// buildTeams 硬前置「角色须已修主修」(stage_battle_setup.dart L265)。
  Future<void> seedCharacter() =>
      Phase2SeedService(isar: IsarSetup.instance).seedP3();

  /// 真实 initState 链是异步的(设置/进度/装配依次 await):runAsync 真时钟
  /// 轮询 + pump 推进,直到条件满足(对齐 stage_entry_flow_branches_test 体例)。
  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() cond, {
    String reason = '',
  }) async {
    for (var i = 0; i < 300 && !cond(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    expect(cond(), isTrue, reason: reason);
  }

  Future<void> closeIsar(Directory? tempDir) async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (tempDir != null && await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  testWidgets('群战入场 → 三阵型可选 + 预选默认;点八卦阵 → 落到 MassBattleStrategy 装配', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final (left, right) = BattleDemo.mockTeams();
    final notifier = _RecordingBattleNotifier(
      BattleState.initial(leftTeam: left, rightTeam: right),
    );
    final probe = _FlowProbe();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [battleProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          home: _StartPage(stage: massStage(), probe: probe),
        ),
      ),
    );
    await tester.pump();

    Directory? tempDir;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_formation_test_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      try {
        await seedCharacter();
        await tester.tap(find.text('start'));
        await pumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().isNotEmpty,
          reason: '群战分支应弹出阵型选择对话框(_pickFormation)',
        );
        expect(probe.error, isNull);

        // ── 各阵型可选态:三 tile 全在(label + hint),默认=雁行阵预选 ──
        expect(find.text(UiStrings.massBattleFormationTitle), findsOneWidget);
        for (final label in [
          UiStrings.massBattleFormationYanXing,
          UiStrings.massBattleFormationBaGua,
          UiStrings.massBattleFormationFengShi,
        ]) {
          expect(find.text(label), findsOneWidget, reason: '$label 应可选');
        }
        for (final hint in [
          UiStrings.massBattleFormationYanXingHint,
          UiStrings.massBattleFormationBaGuaHint,
          UiStrings.massBattleFormationFengShiHint,
        ]) {
          expect(find.text(hint), findsOneWidget);
        }
        final tiles = tester
            .widgetList<ListTile>(find.byType(ListTile))
            .toList();
        expect(tiles, hasLength(3));
        final selected = tiles.where((t) => t.selected).toList();
        expect(selected, hasLength(1), reason: '恰一个预选项');
        expect(
          (selected.single.title! as Text).data,
          UiStrings.massBattleFormationYanXing,
          reason: '未配置 stageFormations 的关默认预选雁行阵(formationFor 兜底)',
        );

        // ── 选择结果:点八卦阵 → startBattle 收 MassBattleStrategy(baGua) ──
        await tester.tap(find.text(UiStrings.massBattleFormationBaGua));
        await pumpUntil(
          tester,
          () => notifier.recordedStrategy != null,
          reason: '选定阵型后应调 startBattle 落战斗装配',
        );
        final strategy = notifier.recordedStrategy;
        expect(strategy, isA<MassBattleStrategy>());
        final mb = strategy! as MassBattleStrategy;
        expect(mb.formation, Formation.baGua, reason: '玩家选择落到 strategy');
        expect(mb.waveCount, 1, reason: 'massBattleEnemyCounts [1] → 单 wave');
        expect(probe.error, isNull);

        // ── 装配生效:strategy 首步把八卦阵 modifier 烘焙进玩家队(敌方不沾) ──
        final numbers = GameRepository.instance.numbers;
        final config = numbers.massBattle;
        var s = BattleState.initial(
          leftTeam: notifier.recordedLeft,
          rightTeam: notifier.recordedRight,
        );
        expect(notifier.recordedLeft, isNotEmpty, reason: '真装配链产出玩家队');
        s = mb.stepOne(s, numbers);
        for (final c in s.leftTeam) {
          expect(
            c.attackPowerMultiplierSource,
            AttackPowerMultiplierSource.formation,
            reason: '玩家队入口快照应烘焙阵型来源',
          );
          expect(
            c.attackPowerMultiplier,
            config.formations[Formation.baGua]!.damageMultiplier,
            reason: '伤害乘数 = 八卦阵 damageMultiplier',
          );
        }
        for (final c in s.rightTeam) {
          expect(
            c.attackPowerMultiplierSource,
            isNot(AttackPowerMultiplierSource.formation),
            reason: '阵型是玩家战略选择,敌方不沾',
          );
        }
      } finally {
        await closeIsar(tempDir);
      }
    });
  });

  testWidgets('群战入场 → 不作选择关闭对话框 → 回退默认阵型(雁行阵)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (left, right) = BattleDemo.mockTeams();
    final notifier = _RecordingBattleNotifier(
      BattleState.initial(leftTeam: left, rightTeam: right),
    );
    final probe = _FlowProbe();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [battleProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          home: _StartPage(stage: massStage(), probe: probe),
        ),
      ),
    );
    await tester.pump();

    Directory? tempDir;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_formation_test_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      try {
        await seedCharacter();
        await tester.tap(find.text('start'));
        await pumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().isNotEmpty,
          reason: '群战分支应弹出阵型选择对话框',
        );

        // 模拟「未选择即关闭」(barrierDismissible=false,生产仅可能系统返回):
        // 直接 pop 对话框路由返回 null → _pickFormation 回退 defaultFormation。
        Navigator.of(tester.element(find.byType(AlertDialog))).pop();
        await pumpUntil(
          tester,
          () => notifier.recordedStrategy != null,
          reason: '回退路径同样应落战斗装配',
        );
        final strategy = notifier.recordedStrategy;
        expect(strategy, isA<MassBattleStrategy>());
        expect(
          (strategy! as MassBattleStrategy).formation,
          Formation.yanXing,
          reason: 'picked==null → 回退 formationFor 默认(雁行阵)',
        );
        expect(probe.error, isNull);
      } finally {
        await closeIsar(tempDir);
      }
    });
  });
}

/// 录制 notifier:host 群战分支唯一出口是 `battleProvider.notifier.startBattle`,
/// 录下 strategy / teams / winCondition 即行为级观测点;不推进战斗(战斗结算链
/// 非本测族目标,阵型烘焙经 strategy.stepOne 直验)。
class _RecordingBattleNotifier extends BattleNotifier {
  _RecordingBattleNotifier(this._initial);

  final BattleState _initial;

  BattleStrategy? recordedStrategy;
  StageWinCondition? recordedWinCondition;
  List<BattleCharacter> recordedLeft = const [];
  List<BattleCharacter> recordedRight = const [];

  @override
  BattleState build() => _initial;

  @override
  void startBattle(
    List<BattleCharacter> leftTeam,
    List<BattleCharacter> rightTeam, {
    BattleStrategy? strategy,
    int? seed,
    StageWinCondition? winCondition,
  }) {
    recordedStrategy = strategy;
    recordedWinCondition = winCondition;
    recordedLeft = leftTeam;
    recordedRight = rightTeam;
  }

  @override
  void advance({int maxConsecutiveTicks = 100}) {}
}

class _FlowProbe {
  String? error;
  var completed = false;
}

/// 流程触发页:不注入任何 battle*ForTest → 走真实 `_runBattle` → 真实
/// `_StageBattleHost`(initState 群战分支含 `_pickFormation`)。
class _StartPage extends ConsumerStatefulWidget {
  const _StartPage({required this.stage, required this.probe});

  final StageDef stage;
  final _FlowProbe probe;

  @override
  ConsumerState<_StartPage> createState() => _StartPageState();
}

class _StartPageState extends ConsumerState<_StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () async {
          try {
            await runStageFlow(context: context, ref: ref, stage: widget.stage);
            widget.probe.completed = true;
          } catch (e) {
            widget.probe.error = e.toString();
          }
        },
        child: const Text('start'),
      ),
    );
  }
}
