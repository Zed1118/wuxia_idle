import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/battle_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

/// Batch 2 Phase 4 · battle strategy 重构 e2e 全场景红线压测
///
/// 详 `docs/handoff/p0_battle_strategy_spec.md` §4 Phase 4 + §7。
///
/// 红线断言语义(memory `feedback_red_line_test_semantics` 实践):
/// - ✅ runToEnd 不抛 / result 有解 / 不撞 maxTicks
/// - ❌ 不写「finalState.tick == 某具体数」之类瞬时事实(数值层会随心法 /
///   装备 / 数值平衡漂移)
///
/// 4 组覆盖:
/// 1. 主线 30 关 e2e(P3 种子单角色对 stage 三敌人,2026-05-22 P2 Ch6 扩)
/// 2. 爬塔 30 层 e2e(同上 + buildTeamsForTower 路径)
/// 3. 心法相生 5 组合 e2e(VC18-A1 fixture 5 角色切 activeCharacterIds 各 1)
/// 4. backwards compat 5 case(BattleEngine facade 与 DefaultGroundStrategy
///    instance 行为等价)
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ────────────────────────────────────────────────────────────────────────
  // 组 1+2:50 战斗场景 e2e(主线 20 + 爬塔 30,共享 Isar + seedP3)
  // ────────────────────────────────────────────────────────────────────────

  group('50 战斗场景 e2e(主线 20 + 爬塔 30)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_strategy_e2e_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    });

    tearDownAll(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> assertBattleRedLine({
      required List<BattleCharacter> left,
      required List<BattleCharacter> right,
    }) async {
      final numbers = GameRepository.instance.numbers;
      final initial =
          BattleState.initial(leftTeam: left, rightTeam: right);

      late BattleState finalState;
      expect(
        () => finalState =
            BattleEngine.runToEnd(initial, numbers, rng: Random(42)),
        returnsNormally,
      );
      expect(finalState.result, isNotNull,
          reason: 'runToEnd 必写 result(leftWin / rightWin / draw)');
      expect(
        finalState.result,
        anyOf(BattleResult.leftWin, BattleResult.rightWin, BattleResult.draw),
      );
      expect(finalState.tick, lessThanOrEqualTo(1000),
          reason: 'tick 不超 maxTicks');
    }

    group('主线 30 关', () {
      const stageIds = [
        'stage_01_01', 'stage_01_02', 'stage_01_03', 'stage_01_04', 'stage_01_05',
        'stage_02_01', 'stage_02_02', 'stage_02_03', 'stage_02_04', 'stage_02_05',
        'stage_03_01', 'stage_03_02', 'stage_03_03', 'stage_03_04', 'stage_03_05',
        'stage_04_01', 'stage_04_02', 'stage_04_03', 'stage_04_04', 'stage_04_05',
        'stage_05_01', 'stage_05_02', 'stage_05_03', 'stage_05_04', 'stage_05_05',
        'stage_06_01', 'stage_06_02', 'stage_06_03', 'stage_06_04', 'stage_06_05',
      ];
      for (final stageId in stageIds) {
        test('$stageId runToEnd 不抛 + result 有解', () async {
          final stage = GameRepository.instance.getStage(stageId);
          final (left, right) =
              await StageBattleSetup(isar: IsarSetup.instance)
                  .buildTeams(stage);
          await assertBattleRedLine(left: left, right: right);
        });
      }
    });

    group('爬塔 30 层', () {
      for (var i = 1; i <= 30; i++) {
        test('floor $i runToEnd 不抛 + result 有解', () async {
          final floor = GameRepository.instance.towerFloors[i - 1];
          final (left, right) =
              await StageBattleSetup(isar: IsarSetup.instance)
                  .buildTeamsForTower(floor);
          await assertBattleRedLine(left: left, right: right);
        });
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 组 3:心法相生 5 组合 e2e(VC18-A1 fixture per-test seed)
  // ────────────────────────────────────────────────────────────────────────

  group('心法相生 5 组合 e2e(VC18-A1 fixture)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_synergy_e2e_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW18A1();
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // VC18-A1 fixture:5 角色全 yiLiu·qiMeng,每个角色对应 1 个 synergy:
    //   id=1 A·阴阳调和(gangMeng+yinRou,schoolPair)
    //   id=2 B·刚柔并济(gangMeng+lingQiao,schoolPair)
    //   id=3 C·阴影迅捷(yinRou+lingQiao,schoolPair)
    //   id=4 D·同流派精进(sameSchool)
    //   id=5 E·同辈互补(sameTier)
    const synergyCases = [
      (1, 'A·阴阳调和'),
      (2, 'B·刚柔并济'),
      (3, 'C·阴影迅捷'),
      (4, 'D·同流派精进'),
      (5, 'E·同辈互补'),
    ];
    for (final (charId, label) in synergyCases) {
      test('$label (id=$charId) 单兵 stage_01_05 runToEnd 不抛', () async {
        // 切 activeCharacterIds 单选该角色,让 buildTeams 只含 1 个左队角色
        // (synergy 注入仍在 character setup 时基于 main+assist tech 触发)。
        await IsarSetup.instance.writeTxn(() async {
          final s = await IsarSetup.instance.saveDatas.get(0);
          s!.activeCharacterIds = [charId];
          await IsarSetup.instance.saveDatas.put(s);
        });
        final stage = GameRepository.instance.getStage('stage_01_05');
        final (left, right) =
            await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
        expect(left.length, 1, reason: '$label fixture 单兵');

        final numbers = GameRepository.instance.numbers;
        final initial =
            BattleState.initial(leftTeam: left, rightTeam: right);

        late BattleState finalState;
        expect(
          () => finalState =
              BattleEngine.runToEnd(initial, numbers, rng: Random(42)),
          returnsNormally,
        );
        expect(finalState.result, isNotNull);
        expect(finalState.tick, greaterThan(0),
            reason: '战斗至少推进 1 tick');
        expect(finalState.tick, lessThanOrEqualTo(1000));
      });
    }
  });

  // ────────────────────────────────────────────────────────────────────────
  // 组 4:BattleEngine facade ↔ DefaultGroundStrategy instance 等价
  // ────────────────────────────────────────────────────────────────────────

  group('backwards compat:BattleEngine facade ↔ DefaultGroundStrategy', () {
    SkillDef normal(String id) => SkillDef(
          id: id,
          name: '普攻',
          description: '',
          type: SkillType.normalAttack,
          powerMultiplier: 500,
          internalForceCost: 0,
          cooldownTurns: 0,
          requiresManualTrigger: false,
          parentTechniqueDefId: null,
          visualEffect: '',
        );

    SkillDef ult(String id) => SkillDef(
          id: id,
          name: '大招',
          description: '',
          type: SkillType.ultimate,
          powerMultiplier: 5000,
          internalForceCost: 1000,
          cooldownTurns: 5,
          requiresManualTrigger: true,
          parentTechniqueDefId: null,
          visualEffect: '',
        );

    BattleCharacter chr({
      required int id,
      required int teamSide,
      required int slotIndex,
      required TechniqueSchool school,
      required List<SkillDef> skills,
    }) =>
        BattleCharacter(
          characterId: id,
          name: 'C$id',
          realmTier: RealmTier.erLiu,
          realmLayer: RealmLayer.yuanShu,
          school: school,
          maxHp: 10000,
          currentHp: 10000,
          maxInternalForce: 3000,
          currentInternalForce: 3000,
          speed: 200,
          criticalRate: 0.0,
          evasionRate: 0.05,
          defenseRate: 0.10,
          totalEquipmentAttack: 350,
          mainCultivationLayer: CultivationLayer.daCheng,
          availableSkills: skills,
          skillCooldowns: const {},
          activeBuffs: const [],
          actionPoint: 0,
          isAlive: true,
          teamSide: teamSide,
          slotIndex: slotIndex,
        );

    BattleState fixture() {
      final atk = normal('a');
      return BattleState.initial(
        leftTeam: [
          chr(
            id: 1,
            teamSide: 0,
            slotIndex: 0,
            school: TechniqueSchool.gangMeng,
            skills: [atk, ult('u')],
          ),
        ],
        rightTeam: [
          chr(
            id: 2,
            teamSide: 1,
            slotIndex: 0,
            school: TechniqueSchool.yinRou,
            skills: [atk],
          ),
        ],
      );
    }

    NumbersConfig numbers() => GameRepository.instance.numbers;

    test('BattleEngine.tick(s, n, rng: Random(42)) ≡ DefaultGroundStrategy().tick 同种子', () {
      const strategy = DefaultGroundStrategy();
      final s0 = fixture();
      final viaFacade = BattleEngine.tick(s0, numbers(), rng: Random(42));
      final viaStrategy = strategy.tick(s0, numbers(), rng: Random(42));
      expect(viaFacade.tick, viaStrategy.tick);
      expect(viaFacade.actionLog.length, viaStrategy.actionLog.length);
      expect(viaFacade.leftTeam.first.currentHp,
          viaStrategy.leftTeam.first.currentHp);
      expect(viaFacade.rightTeam.first.currentHp,
          viaStrategy.rightTeam.first.currentHp);
    });

    test('BattleEngine.runToEnd 同种子 ≡ DefaultGroundStrategy().runToEnd', () {
      const strategy = DefaultGroundStrategy();
      final s0 = fixture();
      final viaFacade =
          BattleEngine.runToEnd(s0, numbers(), rng: Random(42));
      final viaStrategy =
          strategy.runToEnd(s0, numbers(), rng: Random(42));
      expect(viaFacade.result, viaStrategy.result);
      expect(viaFacade.tick, viaStrategy.tick);
      expect(viaFacade.actionLog.length, viaStrategy.actionLog.length);
    });

    test('BattleEngine.requestUltimate ≡ DefaultGroundStrategy().requestUltimate', () {
      const strategy = DefaultGroundStrategy();
      final s0 = fixture();
      final viaFacade =
          BattleEngine.requestUltimate(s0, 1, ult('u'));
      final viaStrategy = strategy.requestUltimate(s0, 1, ult('u'));
      expect(viaFacade.pendingUltimates.keys,
          viaStrategy.pendingUltimates.keys);
      expect(viaFacade.pendingUltimates[1]?.id,
          viaStrategy.pendingUltimates[1]?.id);
    });

    test('DefaultGroundStrategy 是 const-canonicalized 单例(无 mutable state)', () {
      const a = DefaultGroundStrategy();
      const b = DefaultGroundStrategy();
      expect(identical(a, b), isTrue,
          reason: 'const ctor 应在 Dart 编译时 canonicalize 为同一实例');
      expect(a, isA<BattleStrategy>());
    });

    test('DefaultGroundStrategy 跨调用不持 mutable state(并发 tick 不污染)', () {
      const strategy = DefaultGroundStrategy();
      final s0 = fixture();
      // 跑两次 tick,确认第二次的输入不被第一次的输出污染
      final r1a = strategy.tick(s0, numbers(), rng: Random(42));
      final r1b = strategy.tick(s0, numbers(), rng: Random(42));
      expect(r1a.tick, r1b.tick,
          reason: '同输入同种子两次调用 → 同输出(strategy 无副作用)');
      expect(r1a.leftTeam.first.currentHp, r1b.leftTeam.first.currentHp);
      expect(r1a.rightTeam.first.currentHp, r1b.rightTeam.first.currentHp);
    });
  });
}
