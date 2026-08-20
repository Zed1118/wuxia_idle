import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_gate.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../../support/test_data.dart';

/// Phase 1 纵切切片 2 红测(拍板 α 主线入口灰度开关):
/// ① 灰度门:默认关 + testOverride + 关型过滤(只含 mainline);
/// ② roster.fromMapping:真实 Ch1 内容 → 玩家灰盒立绘/敌人 iconPath 零口径
///    复制 + 空 asset fail-fast;
/// ③ host 集成:注入玩家角色 + 固定 seed 真跑 stage_01_01 → victory 回调;
///    极弱玩家 → defeat 回调 + 自 pop;
/// ④ runStageFlow 灰度分支:门开走 phase0a 注入器(胜利链/战败重试),
///    门关 phase0a 注入器零消费。

BattleCharacter _makeCh1Player(NumbersConfig numbers) => BattleCharacter(
  characterId: 1,
  name: '纵切玩家',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 15000,
  currentHp: 15000,
  internalForce: 600,
  maxQi: 100,
  currentQi: 100,
  speed: 100,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0.0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0.0,
  totalEquipmentAttack: 130,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 0,
  slotIndex: 0,
);

StageDef _flowStage() => const StageDef(
  id: 'stage_test_phase0a_gate',
  name: '灰度门测试关',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: false,
  baseExpReward: 0,
  difficultyMultiplier: 1.0,
);

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  tearDown(() {
    Phase0aMainlineGate.testOverride = null;
  });

  group('Phase0aMainlineGate 灰度门', () {
    test('测试环境 dart-define 未注入 → 默认关', () {
      expect(Phase0aMainlineGate.enabled, isFalse);
    });

    test('testOverride 开/还原', () {
      Phase0aMainlineGate.testOverride = true;
      expect(Phase0aMainlineGate.enabled, isTrue);
      Phase0aMainlineGate.testOverride = null;
      expect(Phase0aMainlineGate.enabled, isFalse);
    });

    test('shouldUsePhase0a: 门开只放行主线关型', () {
      Phase0aMainlineGate.testOverride = true;
      expect(Phase0aMainlineGate.shouldUsePhase0a(_flowStage()), isTrue);
      const towerStage = StageDef(
        id: 'stage_test_tower',
        name: '塔测试关',
        stageType: StageType.tower,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: [],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );
      expect(Phase0aMainlineGate.shouldUsePhase0a(towerStage), isFalse);
      Phase0aMainlineGate.testOverride = false;
      expect(Phase0aMainlineGate.shouldUsePhase0a(_flowStage()), isFalse);
    });
  });

  group('Phase0aVisualRoster.fromMapping(真实 Ch1 内容)', () {
    test('stage_01_01: 玩家灰盒立绘 + 敌人 iconPath 零口径复制', () {
      final stage = repo.getStage('stage_01_01');
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerCharacter: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      final roster = Phase0aVisualRoster.fromMapping(mapping);

      final player = roster.visualFor('player');
      expect(player.assetPath, 'assets/characters/battle_founder_v2.png');
      expect(player.name, '纵切玩家');

      final enemy = roster.visualFor('enemy_xueTu_thug_a');
      // iconPath 与 stages.yaml EnemyDef 同值,零口径复制。
      expect(enemy.assetPath, stage.enemyTeam.single.iconPath);
      expect(enemy.name, stage.enemyTeam.single.name);
      expect(enemy.isElite, isFalse);
    });

    test('stage_01_03 三敌: 全部 actor 登记且名字来自 EnemyDef', () {
      final stage = repo.getStage('stage_01_03');
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerCharacter: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      final roster = Phase0aVisualRoster.fromMapping(mapping);
      for (final combatant in mapping.combatants) {
        expect(roster.visualFor(combatant.actorId).name, isNotEmpty);
      }
    });

    test('敌人 iconPath 空串 → fail-fast', () {
      final stage = repo.getStage('stage_01_01');
      final broken = StageDef(
        id: stage.id,
        name: stage.name,
        stageType: stage.stageType,
        requiredRealm: stage.requiredRealm,
        enemyTeam: [
          const EnemyDef(
            id: 'enemy_broken',
            name: '无图敌人',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.gangMeng,
            baseHp: 1500,
            baseAttack: 80,
            baseSpeed: 100,
            skillIds: [],
            iconPath: '',
          ),
        ],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );
      final mapping = Phase0aStageContentMapper.map(
        stage: broken,
        playerCharacter: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      expect(() => Phase0aVisualRoster.fromMapping(mapping), throwsStateError);
    });
  });

  group('Phase0aMainlineBattleHost 集成(注入玩家角色,真跑 0A flow)', () {
    testWidgets('stage_01_01 固定 seed → 键盘驾驶至 victory 回调', (tester) async {
      var victoryCalled = false;
      CombatSettlementSnapshot? victorySettlement;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Phase0aMainlineBattleHost(
              stage: repo.getStage('stage_01_01'),
              playerCharacterForTest: _makeCh1Player(repo.numbers),
              seedForTest: 20260819,
              onVictory: (settlement) {
                victoryCalled = true;
                victorySettlement = settlement;
              },
              onDefeat: (_) {},
            ),
          ),
        ),
      );
      // 装配在 postFrameCallback;先泵一帧完成 setup。
      await tester.pump();
      // 宿主接真人输入 adapter(非 bot):测试模拟玩家连按 J 普攻驾驶战斗。
      var simulatedSeconds = 0;
      while (!victoryCalled && simulatedSeconds < 180) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.pump(const Duration(seconds: 1));
        simulatedSeconds += 1;
      }
      expect(
        victoryCalled,
        isTrue,
        reason:
            'stage_01_01 键盘驾驶应在模拟 180s 内取胜'
            '(切片 1 headless bot 25/25 全胜同口径)',
      );
      expect(victorySettlement!.result, BattleResult.leftWin);
      expect(victorySettlement!.totalDamage, greaterThan(0));
      expect(victorySettlement!.participantFor(1)!.currentHp, greaterThan(0));
    });

    testWidgets('极弱玩家 → defeat 回调且宿主自 pop', (tester) async {
      var defeatCalled = false;
      final weakPlayer = _makeCh1Player(repo.numbers);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => Phase0aMainlineBattleHost(
                      stage: repo.getStage('stage_01_01'),
                      playerCharacterForTest: const BattleCharacter(
                        characterId: 1,
                        name: '脆皮玩家',
                        realmTier: RealmTier.xueTu,
                        realmLayer: RealmLayer.qiMeng,
                        school: TechniqueSchool.gangMeng,
                        maxHp: 1,
                        currentHp: 1,
                        internalForce: 0,
                        maxQi: 0,
                        currentQi: 0,
                        speed: 100,
                        criticalRate: 0,
                        evasionRate: 0,
                        defenseRate: 0,
                        totalEquipmentAttack: 0,
                        mainCultivationLayer: CultivationLayer.chuKui,
                        availableSkills: [],
                        skillCooldowns: {},
                        activeBuffs: [],
                        actionPoint: 0,
                        isAlive: true,
                        teamSide: 0,
                        slotIndex: 0,
                      ),
                      seedForTest: 20260819,
                      onVictory: (_) {},
                      onDefeat: (settlement) {
                        defeatCalled = true;
                        expect(settlement.result, BattleResult.rightWin);
                        expect(settlement.participantFor(1)!.currentHp, 0);
                      },
                    ),
                  ),
                ),
                child: const Text('enter'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('enter'));
      await tester.pump();
      var simulatedSeconds = 0;
      while (!defeatCalled && simulatedSeconds < 60) {
        await tester.pump(const Duration(seconds: 1));
        simulatedSeconds += 1;
      }
      expect(defeatCalled, isTrue, reason: 'HP=1 玩家应迅速战败');
      // 战败宿主自 pop → 回到 enter 页。
      await tester.pumpAndSettle();
      expect(find.text('enter'), findsOneWidget);
      expect(weakPlayer.name, '纵切玩家'); // fixture 锚点,防误删
    });
  });

  group('runStageFlow 灰度分支', () {
    testWidgets('门开 + phase0a 注入器 victory → 进度记录链被调用', (tester) async {
      Phase0aMainlineGate.testOverride = true;
      String? recordedStageId;
      await tester.pumpWidget(
        _gateHarness(
          phase0aBattleOutcome: () async =>
              (won: true, surrendered: false, settlement: null),
          victoryRecorder: (stageId) async => recordedStageId = stageId,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect(recordedStageId, equals('stage_test_phase0a_gate'));
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('门开 + phase0a 注入器 defeat 不重试 → 进度链零消费', (tester) async {
      Phase0aMainlineGate.testOverride = true;
      var victoryCalled = false;
      await tester.pumpWidget(
        _gateHarness(
          phase0aBattleOutcome: () async =>
              (won: false, surrendered: false, settlement: null),
          victoryRecorder: (_) async => victoryCalled = true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect(victoryCalled, isFalse);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('门关 → phase0a 注入器零消费(旧 battleOutcome 生效)', (tester) async {
      var phase0aConsumed = false;
      var oldConsumed = false;
      await tester.pumpWidget(
        _gateHarness(
          battleOutcome: () async {
            oldConsumed = true;
            return (won: true, surrendered: false);
          },
          phase0aBattleOutcome: () async {
            phase0aConsumed = true;
            return (won: true, surrendered: false, settlement: null);
          },
          victoryRecorder: (_) async {},
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect(oldConsumed, isTrue);
      expect(phase0aConsumed, isFalse);
    });
  });
}

/// 灰度分支专用 harness(沿 stage_entry_flow_test 体例):battleRunner/
/// battleOutcome 均可缺省,只喂需要验证的注入器。
Widget _gateHarness({
  Future<({bool won, bool surrendered})> Function()? battleOutcome,
  Future<MainlineBattleExit> Function()? phase0aBattleOutcome,
  Future<void> Function(String stageId)? victoryRecorder,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: _GateHarnessPage(
        battleOutcome: battleOutcome,
        phase0aBattleOutcome: phase0aBattleOutcome,
        victoryRecorder: victoryRecorder ?? (_) async {},
      ),
    ),
  );
}

class _GateHarnessPage extends ConsumerStatefulWidget {
  const _GateHarnessPage({
    required this.battleOutcome,
    required this.phase0aBattleOutcome,
    required this.victoryRecorder,
  });

  final Future<({bool won, bool surrendered})> Function()? battleOutcome;
  final Future<MainlineBattleExit> Function()? phase0aBattleOutcome;
  final Future<void> Function(String stageId) victoryRecorder;

  @override
  ConsumerState<_GateHarnessPage> createState() => _GateHarnessPageState();
}

class _GateHarnessPageState extends ConsumerState<_GateHarnessPage> {
  String _status = 'idle';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_status),
          TextButton(
            onPressed: () async {
              setState(() => _status = 'running');
              try {
                await runStageFlow(
                  context: context,
                  ref: ref,
                  stage: _flowStage(),
                  battleOutcomeForTest: widget.battleOutcome,
                  phase0aBattleOutcomeForTest: widget.phase0aBattleOutcome,
                  stageRetryDeciderForTest: () async => false,
                  victoryRecorderForTest: widget.victoryRecorder,
                  bossDefeatPenaltyForTest: (_) async =>
                      const <DefeatLossEntry>[],
                );
                if (mounted) setState(() => _status = 'done');
              } catch (e) {
                if (mounted) setState(() => _status = 'error: $e');
              }
            },
            child: const Text('start'),
          ),
        ],
      ),
    );
  }
}
