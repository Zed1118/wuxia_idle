import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

/// Phase 3 Week 4 T57 师徒系统 3v3 默认入阵 + 战斗集成测试。
///
/// 目的：复核 [Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple] 落地后，
/// [StageBattleSetup(isar: IsarSetup.instance).buildTeams] → [BattleState.initial] → [BattleEngine.runToEnd]
/// 全链路能正确装配 3 师徒（境界/装备/心法/师承遗物 buff），战斗可推进到 victory/defeat
/// 终态而不挂起或抛异常。
///
/// **不验平衡**（spec §1478）：大弟子/二弟子 vs stage_01_01 流民境界差很大，必胜；
/// defeat case 用 copyWith 人工把左队 HP 压到 1 强制反败，仅验装配链不阻塞 defeat path。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('wuxia_master_disciple_battle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ── 装配正确性 ────────────────────────────────────────────────────────

  test('P5 seed → buildTeams(stage_01_01) → 左队 3 师徒装配完整',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left.length, 3, reason: '3 师徒（祖师 + 大弟子 + 二弟子）全部入阵');
    expect(right.length, 3, reason: 'stage_01_01 三敌');

    // characterId 与 P5 种子约定锁死：祖师 id=1 / 大弟子 id=2 / 二弟子 id=3
    expect(left[0].characterId, 1);
    expect(left[1].characterId, 2);
    expect(left[2].characterId, 3);

    // slotIndex 顺序按 activeCharacterIds 索引
    for (var i = 0; i < 3; i++) {
      expect(left[i].slotIndex, i);
      expect(left[i].teamSide, 0);
      expect(left[i].isAlive, isTrue);
    }
  });

  test('P5 seed → 左队境界对齐 masters.yaml（祖师 yiLiu / 大弟子 erLiu / 二弟子 sanLiu）',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    expect(left[0].realmTier, RealmTier.yiLiu, reason: '祖师一流（方案 A）');
    expect(left[1].realmTier, RealmTier.erLiu, reason: '大弟子二流');
    expect(left[2].realmTier, RealmTier.sanLiu, reason: '二弟子三流');
  });

  test('P5 seed → 3 师徒装备攻击 + 主修招式 + 内力上限均正确装配',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

    for (final bc in left) {
      expect(bc.totalEquipmentAttack, greaterThan(0),
          reason: '${bc.name} 装备攻击应非零（startingEquipmentIds 至少 1 件）');
      expect(bc.availableSkills, isNotEmpty,
          reason: '${bc.name} 主修招式应非空');
      expect(bc.maxHp, greaterThan(0));
      expect(bc.maxInternalForce, greaterThan(0));
    }
  });

  test('P5 seed → 祖师 maxInternalForce 含师承遗物 +10% buff（T55 战斗路径补齐验证）',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, _) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
    final founder = left[0];

    // 祖师持久化字段（character.internalForceMax）是 base，BattleCharacter 应
    // 含 lineage +10%（2 件 isLineageHeritage 遗物）。
    final founderChar = await IsarSetup.instance.characters.get(1);
    final baseIfMax = founderChar!.internalForceMax;
    expect(founder.maxInternalForce, greaterThan(baseIfMax),
        reason: '祖师 BattleCharacter maxInternalForce 必须含 lineage buff');
    // 两件遗物各 +5% → ≈ × 1.10（int 截断后差 0-1）
    expect(founder.maxInternalForce, baseIfMax + (baseIfMax * 0.10).toInt());
  });

  // ── BattleEngine 端到端 ────────────────────────────────────────────────

  test('P5 victory：3 师徒 vs stage_01_01 流民 → runToEnd result=leftWin',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
    final s0 = BattleState.initial(leftTeam: left, rightTeam: right);

    final s = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 1000,
      rng: Random(42),
    );

    expect(s.isFinished, isTrue);
    expect(s.result, BattleResult.leftWin,
        reason: '3 师徒一流/二流/三流 vs 学徒流民境界压制必胜');
    expect(s.actionLog, isNotEmpty, reason: '战斗推进至少 1 个 action');
    // 3 师徒至少 1 个存活
    expect(s.leftTeam.where((c) => c.isAlive).length, greaterThan(0));
  });

  test('P5 装配链产物：人造 left 全员阵亡 → runToEnd 不抛、isFinished、非 leftWin',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    final (originalLeft, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
    // 装配链产物按 buildTeams 全量生成，仅 copyWith 把 left 三人翻死，验证
    // BattleEngine 跑到 isFinished 终态（draw 或 rightWin 皆可），不挂起不抛。
    // 注：BattleEngine 不主动检查 initial state，需要某 actor 行动后才判胜负；
    // left 全死 + right 找不到目标 → 双方都不动 → maxTicks 兜底 draw。
    final deadLeft = originalLeft
        .map((c) => c.copyWith(maxHp: 1, currentHp: 0, isAlive: false))
        .toList();
    final s0 = BattleState.initial(leftTeam: deadLeft, rightTeam: right);

    final s = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 200,
      rng: Random(7),
    );

    expect(s.isFinished, isTrue, reason: 'runToEnd 必须收敛到终态');
    expect(s.result, isNot(BattleResult.leftWin),
        reason: 'left 全员阵亡时绝不能判定 leftWin');
    expect(s.leftTeam.where((c) => c.isAlive).length, 0);
    // 装配链产物字段在 defeat path 仍完整可读（不被 BattleEngine 改坏）
    for (final bc in s.leftTeam) {
      expect(bc.availableSkills, isNotEmpty,
          reason: '${bc.name} availableSkills 应原样保留');
    }
  });
}
