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
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/battle_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/light_foot_strategy.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_gate.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';

import '../../../support/battle_demo.dart';
import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// 入场流 strategy 分支行为级测试（目标 4 · 2026-07-19，弹性续推）。
///
/// 覆盖对象（stage_entry_flow.dart `_StageBattleHostState.initState`）：
///   - 轻功分支（L532-544）：lightFoot 关 + terrainBiome 非空 →
///     startBattle 挂 LightFootStrategy(地形 + numbers.lightFoot 配置);
///   - 默认地面分支（L545-552）：非群战/非轻功地形关 →
///     startBattle 不传 strategy(DefaultGroundStrategy 兜底)。
///
/// wiring 与 stage_entry_flow_formation_test 同配方:不注入 battle*ForTest
/// 走真实 `_runBattle` → 真实 host;override battleProvider 为录制 notifier,
/// `startBattle` 入参即行为级观测点;地形烘焙经 strategy.stepOne 直验
/// (applyTerrainTo @visibleForTesting 体例)。
void main() {
  setUp(() => Phase0aMainlineGate.testOverride = false);
  tearDown(() => Phase0aMainlineGate.testOverride = null);

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  const probeEnemy = EnemyDef(
    id: 'enemy_strategy_probe',
    name: '测试对手',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 1000,
    baseAttack: 500,
    baseSpeed: 100,
    skillIds: [],
    iconPath: '',
  );

  StageDef lightFootStage() => const StageDef(
    id: 'stage_lightfoot_probe',
    name: '测试轻功关',
    stageType: StageType.lightFoot,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [probeEnemy],
    isBossStage: false,
    baseExpReward: 0,
    difficultyMultiplier: 1.0,
    terrainBiome: TerrainBiome.bamboo,
  );

  StageDef groundStage() => const StageDef(
    id: 'stage_ground_probe',
    name: '测试地面关',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [probeEnemy],
    isBossStage: false,
    baseExpReward: 0,
    difficultyMultiplier: 1.0,
  );

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

  /// 驱动真实入场链直到 startBattle 被录制(或暴露错误)。
  Future<void> driveFlow(
    WidgetTester tester,
    StageDef stage,
    _RecordingBattleNotifier notifier,
    _FlowProbe probe,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [battleProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          home: _StartPage(stage: stage, probe: probe),
        ),
      ),
    );
    await tester.pump();

    Directory? tempDir;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_strategy_test_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      try {
        await Phase2SeedService(isar: IsarSetup.instance).seedP3();
        await tester.tap(find.text('start'));
        await pumpUntil(
          tester,
          () => notifier.startCalled || probe.error != null,
          reason: '真实装配链应走到 startBattle',
        );
        expect(probe.error, isNull);
        expect(notifier.startCalled, isTrue);
      } finally {
        if (Isar.getInstance('wuxia_save_slot1') != null) {
          await IsarSetup.close();
        }
        IsarSetup.resetForTest();
        if (tempDir != null && await tempDir!.exists()) {
          await tempDir!.delete(recursive: true);
        }
      }
    });
  }

  testWidgets('轻功关(竹林)→ startBattle 挂 LightFootStrategy,地形烘焙进装配', (
    tester,
  ) async {
    final (left, right) = BattleDemo.mockTeams();
    final notifier = _RecordingBattleNotifier(
      BattleState.initial(leftTeam: left, rightTeam: right),
    );
    final probe = _FlowProbe();
    await driveFlow(tester, lightFootStage(), notifier, probe);

    final strategy = notifier.recordedStrategy;
    expect(strategy, isA<LightFootStrategy>(), reason: '轻功分支挂轻功 strategy');
    final lf = strategy! as LightFootStrategy;
    expect(lf.terrainBiome, TerrainBiome.bamboo, reason: '地形随关配置注入');
    expect(
      identical(lf.config, GameRepository.instance.numbers.lightFoot),
      isTrue,
      reason: 'config 来自 numbers.lightFoot',
    );
    expect(notifier.recordedLeft, isNotEmpty, reason: '真装配链产出玩家队');

    // 地形烘焙:strategy 首步把 bamboo modifier 烘进双方入口快照(地形中立)。
    final numbers = GameRepository.instance.numbers;
    var s = BattleState.initial(
      leftTeam: notifier.recordedLeft,
      rightTeam: notifier.recordedRight,
    );
    s = lf.stepOne(s, numbers);
    expect(
      s.leftTeam.first.attackPowerMultiplierSource,
      AttackPowerMultiplierSource.terrain,
      reason: '地形应烘焙进玩家队入口快照',
    );
  });

  testWidgets('普通主线关 → startBattle 不传 strategy(默认地面兜底)+ winCondition 透传', (
    tester,
  ) async {
    final (left, right) = BattleDemo.mockTeams();
    final notifier = _RecordingBattleNotifier(
      BattleState.initial(leftTeam: left, rightTeam: right),
    );
    final probe = _FlowProbe();
    await driveFlow(tester, groundStage(), notifier, probe);

    expect(
      notifier.recordedStrategy,
      isNull,
      reason: '默认分支不传 strategy → DefaultGroundStrategy 兜底',
    );
    expect(
      notifier.recordedWinCondition,
      isNull,
      reason: '本关未配 winCondition → null 透传(defeatAll 旧行为)',
    );
    expect(notifier.recordedLeft, isNotEmpty);
    expect(notifier.recordedRight.length, 1, reason: '右队按 enemyTeam 装配(非群战波次)');
  });
}

/// 录制 notifier(同 stage_entry_flow_formation_test 配方):`startBattle` 是
/// host 各 strategy 分支唯一出口,录入参即行为级观测点,不推进战斗。
class _RecordingBattleNotifier extends BattleNotifier {
  _RecordingBattleNotifier(this._initial);

  final BattleState _initial;

  var startCalled = false;
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
    startCalled = true;
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
}

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
          } catch (e) {
            widget.probe.error = e.toString();
          }
        },
        child: const Text('start'),
      ),
    );
  }
}
