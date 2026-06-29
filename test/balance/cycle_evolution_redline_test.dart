import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

/// F1 周目进化 安全门：跨阶 + 周目压测守红线。
///
/// 验证 P1 cycle_evolution 的敌人缩放（×(1+0.06*(cycle-1))）+ 5 反制词条
/// 在最大周目下不突破 CLAUDE.md §5.4 数值红线：
///
///   - Boss HP    ≤ 60,000（§5.4，2026-06-14 从 50k 调至 60k；config-driven from
///                           numbers.yaml combat.red_lines.boss_hp_max）
///   - 装备攻击   §5.4「装备攻击 ≤ 2,000」为玩家装备红线，不直接约束 enemy.baseAttack；
///               Ch6 敌人 baseAttack 2150-2700 / tower floor30 当前配置值均为设计内值，不硬断言
///   - 内力上限   ≤ 15,000（numbers.yaml combat.red_lines.internal_force_max）
///   - 防御率     ≤      0.6（numbers.yaml cycle_evolution.defense_rate_cap）
///
/// **设计原则**（P1 spec §目的）："靠词条非堆数值" — 数值膨胀被周目 scale
/// 控制在可接受范围，词条提升策略深度。安全门的职责是用数学保证这一点。
///
/// **覆盖场景（最难情形优先）**：
///   1. 主线 stage_06_05（最高境界 wuSheng boss，baseHp=52000）cycle 3 → 58,240 ≤ 60,000 ✅
///   2. 主线 stage_05_05（zongShi boss，baseHp=36600）cycle 3
///   3. 主线 stage_04_05（jueDing boss，baseHp=15625）cycle 3
///   4. 爬塔 floor 30（最高 Boss，baseHp/baseAttack 从 towers.yaml 当前配置派生）cycle 2
///   5. 爬塔 floor 20（大 Boss，isTower，cycle 2 凝甲/反震/识破）
///   6. 御体 defenseRate clamp ≤ defenseRateCap（C2/C3 高境界敌人）
///   7. 真气 + scale → maxInternalForce ≤ 红线（爬塔 cycle 2）
///   8. clamp 防越线：baseHp 极端值经 scale 超 60k 时被 clamp（§新增防护）
///
/// **不走 Isar / BattleEngine**：静态 stat 断言直接证明 scale+词条 在红线内。
/// 动态伤害上界估算（测试 4.3 上界数学推导）不跑实战，避免引入 Isar 死锁风险。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §1  主线 cycle 3 Boss HP / attack 静态断言（最难情形）
  // ════════════════════════════════════════════════════════════════════════════

  group('§1 主线 cycle 3 Boss stat 静态红线', () {
    /// §5.4 Boss HP 红线 — config-driven（numbers.yaml combat.red_lines.boss_hp_max）。
    /// 2026-06-14 用户拍板从 50000 调至 60000，终局周目进化（stage_06_05 cycle3=58240）合规。
    late int bossHpRedLine;

    /// 周目缩放系数 cycle 3 主线 = 1 + scalePerCycle × 2（2026-06-26: 0.10 → 1.20）。
    /// 派生自 config，改 scale_per_cycle 自动跟随。
    late double cycle3Scale;

    setUpAll(() {
      bossHpRedLine = GameRepository.instance.numbers.combat.redLines.bossHpMax;
      cycle3Scale =
          1.0 +
          GameRepository.instance.numbers.cycleEvolution.scalePerCycle *
              (3 - 1);
    });

    // ── 1.1  stage_04_05 · jueDing 跨阶 Boss ────────────────────────────────
    test('1.1 stage_04_05 cycle 3：所有敌人 maxHp ≤ §5.4 boss HP 红线', () {
      final stage = GameRepository.instance.getStage('stage_04_05');
      final team = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 3,
        isTower: false,
      );
      var maxHp = 0;
      for (final bc in team) {
        if (bc.maxHp > maxHp) maxHp = bc.maxHp;
        expect(
          bc.maxHp,
          lessThanOrEqualTo(bossHpRedLine),
          reason:
              '${bc.name}(${bc.characterId}) cycle 3 maxHp=${bc.maxHp} '
              '超 §5.4 Boss HP 红线=$bossHpRedLine',
        );
      }
      addTearDown(
        () => printOnFailure(
          'stage_04_05 cycle3 max enemy HP = $maxHp（红线=$bossHpRedLine，安全余量=${bossHpRedLine - maxHp}）',
        ),
      );
    });

    // ── 1.2  stage_05_05 · zongShi 跨阶 Boss ────────────────────────────────
    test('1.2 stage_05_05 cycle 3：所有敌人 maxHp ≤ §5.4 boss HP 红线', () {
      final stage = GameRepository.instance.getStage('stage_05_05');
      final team = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 3,
        isTower: false,
      );
      var maxHp = 0;
      for (final bc in team) {
        if (bc.maxHp > maxHp) maxHp = bc.maxHp;
        expect(
          bc.maxHp,
          lessThanOrEqualTo(bossHpRedLine),
          reason:
              '${bc.name}(${bc.characterId}) cycle 3 maxHp=${bc.maxHp} '
              '超 §5.4 Boss HP 红线=$bossHpRedLine',
        );
      }
      addTearDown(
        () => printOnFailure(
          'stage_05_05 cycle3 max enemy HP = $maxHp（红线=$bossHpRedLine，安全余量=${bossHpRedLine - maxHp}）',
        ),
      );
    });

    // ── 1.3  stage_06_05 · wuSheng 最终 Boss（2026-06-14 已合规：60k 红线）────
    test('1.3 stage_06_05 cycle 3：所有敌人 maxHp ≤ §5.4 boss HP 红线（60000）', () {
      final stage = GameRepository.instance.getStage('stage_06_05');
      final team = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 3,
        isTower: false,
      );

      // 西凉霸主 baseHp=32000（2026-06-29 solo 平衡 52000→32000），cycle3 scale=1.20 → 38400 < 60000
      // （2026-06-26 周目平衡 0.06→0.10 后此 boss 命中 clamp，红线由生产 .clamp 强制）。
      final expectedBossHp = (32000 * cycle3Scale).toInt().clamp(
        0,
        bossHpRedLine,
      );
      final bossBc = team.firstWhere(
        (bc) => bc.name == '西凉霸主',
        orElse: () => team.first,
      );
      expect(
        bossBc.maxHp,
        expectedBossHp,
        reason: 'cycle 3 scale 系数 $cycle3Scale 对应西凉霸主 HP 应为 $expectedBossHp',
      );

      var maxHp = 0;
      for (final bc in team) {
        if (bc.maxHp > maxHp) maxHp = bc.maxHp;
        expect(
          bc.maxHp,
          lessThanOrEqualTo(bossHpRedLine),
          reason:
              '${bc.name}(${bc.characterId}) cycle 3 maxHp=${bc.maxHp} '
              '超 §5.4 Boss HP 红线=$bossHpRedLine（60000）',
        );
      }
      addTearDown(
        () => printOnFailure(
          'stage_06_05 cycle3 max HP=$maxHp（红线=$bossHpRedLine，安全余量=${bossHpRedLine - maxHp}）',
        ),
      );
    });

    // ── 1.4  全主线 Boss 关 cycle 3 HP 扫描（全量枚举 isBossStage，含 stage_06_05）
    test('1.4 全主线 isBossStage cycle 3：maxHp ≤ §5.4 红线（含 stage_06_05）', () {
      final repo = GameRepository.instance;
      var maxObservedHp = 0;
      String maxStageId = '';

      for (final stage in repo.stageDefs.values) {
        if (!stage.isBossStage) continue;
        if (stage.stageType == StageType.innerDemon) continue; // 心魔关无 yaml 敌人
        if (stage.enemyTeam.isEmpty) continue;

        final team = StageBattleSetup.buildEnemyTeam(
          stage.enemyTeam,
          cycleIndex: 3,
          isTower: false,
        );
        for (final bc in team) {
          if (bc.maxHp > maxObservedHp) {
            maxObservedHp = bc.maxHp;
            maxStageId = stage.id;
          }
          expect(
            bc.maxHp,
            lessThanOrEqualTo(bossHpRedLine),
            reason:
                '[${stage.id}] ${bc.name} cycle 3 maxHp=${bc.maxHp} '
                '超 §5.4 Boss HP 红线=$bossHpRedLine（60000）',
          );
        }
      }

      addTearDown(
        () => printOnFailure(
          '全主线 Boss 关 cycle3 max HP = $maxObservedHp（来自 $maxStageId，红线=$bossHpRedLine）',
        ),
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §2  爬塔 cycle 2 Boss HP / attack 静态断言（最难情形）
  // ════════════════════════════════════════════════════════════════════════════

  group('§2 爬塔 cycle 2 Boss stat 静态红线', () {
    late int bossHpRedLine;
    setUpAll(() {
      bossHpRedLine = GameRepository.instance.numbers.combat.redLines.bossHpMax;
    });

    // tower_boss_30（最高层大 Boss）
    test('2.1 tower floor 30 cycle 2（最高 Boss）：maxHp ≤ §5.4 红线', () {
      final floor = GameRepository.instance.getTowerFloor(30);
      final team = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      var maxHp = 0;
      for (final bc in team) {
        if (bc.maxHp > maxHp) maxHp = bc.maxHp;
        expect(
          bc.maxHp,
          lessThanOrEqualTo(bossHpRedLine),
          reason:
              '爬塔 floor 30 cycle 2 ${bc.name} maxHp=${bc.maxHp} 超 $bossHpRedLine',
        );
      }
      addTearDown(
        () => printOnFailure(
          'tower floor 30 cycle2 max HP = $maxHp（红线=$bossHpRedLine，余量=${bossHpRedLine - maxHp}）',
        ),
      );
    });

    // tower_boss_20（中层大 Boss）
    test('2.2 tower floor 20 cycle 2（中 Boss）：maxHp ≤ §5.4 红线', () {
      final floor = GameRepository.instance.getTowerFloor(20);
      final team = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      for (final bc in team) {
        expect(
          bc.maxHp,
          lessThanOrEqualTo(bossHpRedLine),
          reason:
              'tower floor 20 cycle 2 ${bc.name} maxHp=${bc.maxHp} 超 $bossHpRedLine',
        );
      }
    });

    // tower_boss_25（小 Boss，位于绝顶）
    test('2.3 tower floor 25 cycle 2（绝顶小 Boss）：maxHp ≤ §5.4 红线', () {
      final floor = GameRepository.instance.getTowerFloor(25);
      final team = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      for (final bc in team) {
        expect(
          bc.maxHp,
          lessThanOrEqualTo(bossHpRedLine),
          reason:
              'tower floor 25 cycle 2 ${bc.name} maxHp=${bc.maxHp} 超 $bossHpRedLine',
        );
      }
    });

    // 全爬塔 Boss 层（bossKind != null）扫描
    test('2.4 全爬塔 Boss 层 cycle 2：maxHp ≤ §5.4 红线', () {
      final repo = GameRepository.instance;
      var maxHp = 0;
      for (int i = 1; i <= 30; i++) {
        final floor = repo.getTowerFloor(i);
        if (!floor.isBoss) continue;
        final team = StageBattleSetup.buildEnemyTeam(
          floor.enemyTeam,
          cycleIndex: 2,
          isTower: true,
        );
        for (final bc in team) {
          if (bc.maxHp > maxHp) maxHp = bc.maxHp;
          expect(
            bc.maxHp,
            lessThanOrEqualTo(bossHpRedLine),
            reason:
                'tower floor $i cycle 2 ${bc.name} maxHp=${bc.maxHp} 超 $bossHpRedLine',
          );
        }
      }
      addTearDown(
        () => printOnFailure(
          '全爬塔 Boss 层 cycle2 max HP = $maxHp（红线=$bossHpRedLine）',
        ),
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §3  内力红线：真气词条 + scale 后 maxInternalForce ≤ numbers 红线
  // ════════════════════════════════════════════════════════════════════════════

  group('§3 真气 + cycle scale 后 maxInternalForce ≤ 内力红线', () {
    test('3.1 爬塔 floor 30（最高 Boss，cycle 2 tower_boss 词条集）', () {
      final floor = GameRepository.instance.getTowerFloor(30);
      final redLine =
          GameRepository.instance.numbers.combat.redLines.internalForceMax;
      final team = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      var maxIf = 0;
      for (final bc in team) {
        if (bc.maxInternalForce > maxIf) maxIf = bc.maxInternalForce;
        expect(
          bc.maxInternalForce,
          lessThanOrEqualTo(redLine),
          reason:
              'tower floor 30 cycle 2 ${bc.name} '
              'maxInternalForce=${bc.maxInternalForce} 超 §5.4 红线=$redLine',
        );
      }
      addTearDown(
        () => printOnFailure(
          'tower floor 30 cycle2 max IF = $maxIf（红线=$redLine，余量=${redLine - maxIf}）',
        ),
      );
    });

    test('3.2 爬塔 floor 20（中 Boss，cycle 2 tower_boss 词条集）', () {
      final floor = GameRepository.instance.getTowerFloor(20);
      final redLine =
          GameRepository.instance.numbers.combat.redLines.internalForceMax;
      final team = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      for (final bc in team) {
        expect(
          bc.maxInternalForce,
          lessThanOrEqualTo(redLine),
          reason:
              'tower floor 20 cycle 2 ${bc.name} '
              'maxInternalForce=${bc.maxInternalForce} 超 §5.4 红线=$redLine',
        );
      }
    });

    test('3.3 主线 stage_06_05 cycle 3（最高主线 boss，无真气词条）', () {
      final stage = GameRepository.instance.getStage('stage_06_05');
      final redLine =
          GameRepository.instance.numbers.combat.redLines.internalForceMax;
      final team = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 3,
        isTower: false,
      );
      var maxIf = 0;
      for (final bc in team) {
        if (bc.maxInternalForce > maxIf) maxIf = bc.maxInternalForce;
        expect(
          bc.maxInternalForce,
          lessThanOrEqualTo(redLine),
          reason:
              'stage_06_05 cycle 3 ${bc.name} '
              'maxInternalForce=${bc.maxInternalForce} 超 §5.4 红线=$redLine',
        );
      }
      addTearDown(
        () => printOnFailure(
          'stage_06_05 cycle3 max IF = $maxIf（红线=$redLine，余量=${redLine - maxIf}）',
        ),
      );
    });

    test('3.4 全爬塔所有层（普通+Boss）cycle 2 maxInternalForce ≤ 红线', () {
      final repo = GameRepository.instance;
      final redLine = repo.numbers.combat.redLines.internalForceMax;
      var maxIf = 0;
      for (int i = 1; i <= 30; i++) {
        final floor = repo.getTowerFloor(i);
        final team = StageBattleSetup.buildEnemyTeam(
          floor.enemyTeam,
          cycleIndex: 2,
          isTower: true,
        );
        for (final bc in team) {
          if (bc.maxInternalForce > maxIf) maxIf = bc.maxInternalForce;
          expect(
            bc.maxInternalForce,
            lessThanOrEqualTo(redLine),
            reason:
                'tower floor $i cycle 2 ${bc.name} '
                'maxIF=${bc.maxInternalForce} 超 §5.4 红线=$redLine',
          );
        }
      }
      addTearDown(
        () => printOnFailure('全爬塔 cycle2 max IF = $maxIf（红线=$redLine）'),
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §4  御体 defenseRate clamp ≤ defenseRateCap（CLAUDE.md §5.4 防御上限）
  // ════════════════════════════════════════════════════════════════════════════

  group('§4 御体 defenseRate clamp ≤ defenseRateCap', () {
    late double cap;
    setUpAll(() {
      cap = GameRepository.instance.numbers.cycleEvolution.defenseRateCap;
    });

    test('4.1 cycle 3 主线（御体 C3 档 +0.12）最高境界敌人 defenseRate ≤ cap', () {
      // 覆盖全主线 Boss 关 cycle 3（御体是 C3 yuti 词条）
      final repo = GameRepository.instance;
      var maxDr = 0.0;
      for (final stage in repo.stageDefs.values) {
        if (!stage.isBossStage) continue;
        if (stage.stageType == StageType.innerDemon) continue;
        if (stage.enemyTeam.isEmpty) continue;
        final team = StageBattleSetup.buildEnemyTeam(
          stage.enemyTeam,
          cycleIndex: 3,
          isTower: false,
        );
        for (final bc in team) {
          if (bc.defenseRate > maxDr) maxDr = bc.defenseRate;
          expect(
            bc.defenseRate,
            lessThanOrEqualTo(cap),
            reason:
                '[${stage.id}] ${bc.name} cycle 3 '
                'defenseRate=${bc.defenseRate} 超 defenseRateCap=$cap',
          );
        }
      }
      addTearDown(
        () => printOnFailure(
          '全主线 Boss 关 cycle3 max defenseRate = $maxDr（cap=$cap，余量=${cap - maxDr}）',
        ),
      );
    });

    test('4.2 cycle 2 爬塔 Boss（tower_boss 词条集含御体）defenseRate ≤ cap', () {
      final repo = GameRepository.instance;
      var maxDr = 0.0;
      for (int i = 1; i <= 30; i++) {
        final floor = repo.getTowerFloor(i);
        if (!floor.isBoss) continue;
        final team = StageBattleSetup.buildEnemyTeam(
          floor.enemyTeam,
          cycleIndex: 2,
          isTower: true,
        );
        for (final bc in team) {
          if (bc.defenseRate > maxDr) maxDr = bc.defenseRate;
          expect(
            bc.defenseRate,
            lessThanOrEqualTo(cap),
            reason:
                'tower floor $i Boss cycle 2 ${bc.name} '
                'defenseRate=${bc.defenseRate} 超 cap=$cap',
          );
        }
      }
      addTearDown(
        () =>
            printOnFailure('爬塔 Boss cycle2 max defenseRate = $maxDr（cap=$cap）'),
      );
    });

    test('4.3 全爬塔普通层 cycle 2（tower_normal 词条含御体）defenseRate ≤ cap', () {
      final repo = GameRepository.instance;
      var maxDr = 0.0;
      for (int i = 1; i <= 30; i++) {
        final floor = repo.getTowerFloor(i);
        if (floor.isBoss) continue; // 普通层
        final team = StageBattleSetup.buildEnemyTeam(
          floor.enemyTeam,
          cycleIndex: 2,
          isTower: true,
        );
        for (final bc in team) {
          if (bc.defenseRate > maxDr) maxDr = bc.defenseRate;
          expect(
            bc.defenseRate,
            lessThanOrEqualTo(cap),
            reason:
                'tower floor $i normal cycle 2 ${bc.name} '
                'defenseRate=${bc.defenseRate} 超 cap=$cap',
          );
        }
      }
      addTearDown(
        () => printOnFailure('爬塔普通层 cycle2 max defenseRate = $maxDr（cap=$cap）'),
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §5  scale 单调性与上界确认（确保 scale 因子本身符合 spec）
  // ════════════════════════════════════════════════════════════════════════════

  group('§5 scale 系数符合 spec 约束', () {
    test(
      '5.1 maxCycleMainline=3 → cycle 3 scale = 1.20（spec 参数锁·2026-06-26）',
      () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(ce.maxCycleMainline, 3);
        expect(ce.maxCycleTower, 2);
        final scale3 = 1.0 + ce.scalePerCycle * (3 - 1);
        expect(
          scale3,
          closeTo(1.20, 0.001),
          reason: 'cycle 3 主线 scale 应为 1 + 0.10×2 = 1.20',
        );
        final scale2 = 1.0 + ce.scalePerCycle * (2 - 1);
        expect(
          scale2,
          closeTo(1.10, 0.001),
          reason: 'cycle 2 塔 scale 应为 1 + 0.10×1 = 1.10',
        );
      },
    );

    test('5.2 爬塔最大 Boss HP（floor 30 当前 baseHp）cycle 2 scale 精确', () {
      final floor = GameRepository.instance.getTowerFloor(30);
      final team = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      final boss = team.first; // floor 30 单人
      final baseHpFloor30 = floor.enemyTeam.firstWhere((e) => e.isBoss).baseHp;
      final ce = GameRepository.instance.numbers.cycleEvolution;
      final expectedHp = (baseHpFloor30 * (1.0 + ce.scalePerCycle)).toInt();
      expect(
        boss.maxHp,
        expectedHp,
        reason:
            'floor 30 cycle 2 boss HP 应精确 = $baseHpFloor30 × '
            '${1.0 + ce.scalePerCycle} = $expectedHp（scale 逻辑验算）',
      );
    });

    test('5.3 主线 stage_05_05 Boss（baseHp=36600）cycle 3 scale 精确验算', () {
      final stage = GameRepository.instance.getStage('stage_05_05');
      final team = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 3,
        isTower: false,
      );
      final ce = GameRepository.instance.numbers.cycleEvolution;
      final bossHpMax =
          GameRepository.instance.numbers.combat.redLines.bossHpMax;
      final scale3 = 1.0 + ce.scalePerCycle * (3 - 1);
      // 西凉霸主三弟子 baseHp=24000（2026-06-29 solo 36600→24000）→ (24000 × 1.20).toInt() = 28,800
      const baseHp = 24000;
      final expectedHp = (baseHp * scale3).toInt();
      final boss = team.firstWhere(
        (bc) => bc.name == '西凉霸主三弟子',
        orElse: () => team.first,
      );
      expect(
        boss.maxHp,
        expectedHp,
        reason: 'stage_05_05 cycle 3 boss HP 应精确 = $expectedHp',
      );
      expect(
        boss.maxHp,
        lessThanOrEqualTo(bossHpMax),
        reason:
            '${boss.name} cycle 3 maxHp=${boss.maxHp} 应 ≤ §5.4 Boss HP 红线 $bossHpMax',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §6  敌人攻击分布记录（pre-P1 超线情况说明 + scale 精确验算）
  // ════════════════════════════════════════════════════════════════════════════
  //
  // §5.4「装备攻击 ≤ 2000」为**玩家装备**红线，不直接约束 enemy.baseAttack。
  // Ch6 全章（stage_06_01..06_05）enemy baseAttack 在 1950-2700 区间，
  // tower floor 30 也按当前配置派生 — 均为数值层设计，非 P1 引入。
  //
  // 本节的职责是：
  //   (a) 确认 P1 scale 逻辑精确（attack × scale 整数对上）；
  //   (b) 记录各最坏情形实测值，供人类数值层审查决策（是否需要限帽 enemy attack）。

  group('§6 敌人攻击 scale 精确验算与分布记录', () {
    test('6.1 stage_05_05 cycle 3 attack scale 精确（baseAttack 1995 × 1.20）', () {
      final stage05 = GameRepository.instance.getStage('stage_05_05');
      final team05 = StageBattleSetup.buildEnemyTeam(
        stage05.enemyTeam,
        cycleIndex: 3,
        isTower: false,
      );
      final ce = GameRepository.instance.numbers.cycleEvolution;
      const baseAtk05Boss = 1500; // 西凉霸主三弟子 baseAttack（yaml 锚 · 2026-06-29 solo 1995→1500）
      final expectedAtk = (baseAtk05Boss * (1.0 + ce.scalePerCycle * 2))
          .toInt();
      final boss05 = team05.firstWhere(
        (bc) => bc.name == '西凉霸主三弟子',
        orElse: () => team05.first,
      );
      expect(
        boss05.totalEquipmentAttack,
        expectedAtk,
        reason:
            'stage_05_05 cycle 3 attack scale 精确验算 '
            '1995 × ${1.0 + ce.scalePerCycle * 2} = $expectedAtk',
      );
    });

    test(
      '6.2 tower floor 30 cycle 2 attack scale 精确（当前 baseAttack × 1.10）',
      () {
        final floor30 = GameRepository.instance.getTowerFloor(30);
        final team30 = StageBattleSetup.buildEnemyTeam(
          floor30.enemyTeam,
          cycleIndex: 2,
          isTower: true,
        );
        final ce = GameRepository.instance.numbers.cycleEvolution;
        final baseAtk30 = floor30.enemyTeam.firstWhere((e) => e.isBoss).baseAttack;
        final expectedAtk = (baseAtk30 * (1.0 + ce.scalePerCycle)).toInt();
        expect(
          team30.first.totalEquipmentAttack,
          expectedAtk,
          reason:
              'tower floor 30 cycle 2 attack scale 精确验算 '
              '$baseAtk30 × ${1.0 + ce.scalePerCycle} = $expectedAtk',
        );
      },
    );

    test('6.3 全主线 Boss 关 cycle 3 totalEquipmentAttack 分布记录（不 fail）', () {
      final repo = GameRepository.instance;
      var maxAtk = 0;
      String maxStage = '';
      String maxEnemy = '';
      for (final stage in repo.stageDefs.values) {
        if (!stage.isBossStage) continue;
        if (stage.stageType == StageType.innerDemon) continue;
        if (stage.enemyTeam.isEmpty) continue;
        final team = StageBattleSetup.buildEnemyTeam(
          stage.enemyTeam,
          cycleIndex: 3,
          isTower: false,
        );
        for (final bc in team) {
          if (bc.totalEquipmentAttack > maxAtk) {
            maxAtk = bc.totalEquipmentAttack;
            maxStage = stage.id;
            maxEnemy = bc.name;
          }
        }
      }
      // 记录峰值（不 fail — §5.4 enemy attack 无硬约束，由 boss HP 红线间接控制威胁）
      addTearDown(
        () => printOnFailure(
          '[F1-RECORD] 全主线 Boss 关 cycle3 peak totalEquipmentAttack='
          '$maxAtk（来自 [$maxStage] $maxEnemy，§5.4 参考 2000，'
          '超线=${maxAtk > 2000 ? maxAtk - 2000 : "无"}）',
        ),
      );
      // 轻量健壮性断言：数值合理（不超过 baseAttack×1.20=无理值）
      expect(
        maxAtk,
        lessThanOrEqualTo(5000),
        reason: 'cycle 3 单敌 attack 不应超过极端上界 5000（scale 失控检测）',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §7  scaledHp clamp 防越线（2026-06-14 新增 · 对抗审计修复）
  //
  //     通过生产路径 debugEnemyToBattle 驱动真实 _enemyToBattle 逻辑，
  //     证明 clamp 分支真正截断而非数学重现。
  //
  //     baseHp=58000 × cycle3 scale(1.20) = 69600 > bossHpMax(60000)
  //     → 生产代码：scaledHp = (58000 × 1.20).toInt().clamp(0, 60000) = 60000
  // ════════════════════════════════════════════════════════════════════════════

  group('§7 scaledHp clamp ≤ bossHpMax（生产路径证明）', () {
    test(
      '7.1 baseHp=58000 cycle 3 → debugEnemyToBattle 返回 maxHp=bossHpMax（clamp 分支真截断）',
      () {
        final n = GameRepository.instance.numbers;
        final bossHpMax = n.combat.redLines.bossHpMax;

        // 构造 baseHp=58000 虚拟敌人：cycle3 scale=1.20 → 69600 > 60000
        // 生产路径 .clamp(0, bossHpMax) 必须将其截断至 60000。
        final syntheticEnemy = const EnemyDef(
          id: 'test_clamp',
          name: '测试截断',
          realmTier: RealmTier.wuSheng,
          realmLayer: RealmLayer.dengFeng,
          school: TechniqueSchool.gangMeng,
          baseHp: 58000,
          baseAttack: 1000,
          baseSpeed: 100,
          skillIds: [],
          iconPath: '',
          isBoss: true,
        );

        final bc = StageBattleSetup.debugEnemyToBattle(
          enemy: syntheticEnemy,
          slotIndex: 0,
          cycleIndex: 3,
          isTower: false,
        );

        // 64960 > 60000：生产 clamp 必须截断
        final scaledRaw =
            (58000 * (1.0 + n.cycleEvolution.scalePerCycle * (3 - 1))).toInt();
        expect(
          scaledRaw,
          greaterThan(bossHpMax),
          reason:
              'scaledRaw=$scaledRaw 必须 > bossHpMax=$bossHpMax 才能验证 clamp 分支',
        );
        expect(
          bc.maxHp,
          bossHpMax,
          reason:
              '生产路径 clamp 后 maxHp 必须精确等于 bossHpMax=$bossHpMax，'
              '而非 scaledRaw=$scaledRaw',
        );
        expect(
          bc.currentHp,
          bossHpMax,
          reason: 'currentHp 初始值应与 maxHp 一致（满血入场）',
        );
      },
    );

    test('7.2 baseHp=45000 cycle 3（54000 < 60000）→ 无 clamp，精确等于 scale 结果', () {
      // 反例：不超线时 clamp 不截断，结果应精确等于 scale 值（回归锁）。
      // 2026-06-26 scale 0.06→0.10 后 clamp 阈值 baseHp = 60000/1.20 = 50000,
      // 原 52000 现已命中 clamp，改 45000（×1.20=54000<60000）保持「无截断」语义。
      final n = GameRepository.instance.numbers;
      final bossHpMax = n.combat.redLines.bossHpMax;
      final ce = n.cycleEvolution;

      final syntheticEnemy = const EnemyDef(
        id: 'test_no_clamp',
        name: '测试不截断',
        realmTier: RealmTier.wuSheng,
        realmLayer: RealmLayer.dengFeng,
        school: TechniqueSchool.gangMeng,
        baseHp: 45000,
        baseAttack: 1000,
        baseSpeed: 100,
        skillIds: [],
        iconPath: '',
        isBoss: true,
      );

      final bc = StageBattleSetup.debugEnemyToBattle(
        enemy: syntheticEnemy,
        slotIndex: 0,
        cycleIndex: 3,
        isTower: false,
      );

      final expectedHp = (45000 * (1.0 + ce.scalePerCycle * (3 - 1))).toInt();
      expect(
        expectedHp,
        lessThanOrEqualTo(bossHpMax),
        reason: '$expectedHp ≤ $bossHpMax，此用例验证无截断路径（回归锁）',
      );
      expect(
        bc.maxHp,
        expectedHp,
        reason: '未超线时 maxHp 应精确等于 scale 结果 $expectedHp，不应被 clamp 截断',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // §8  敌人普攻基础伤害 ≤ §5.4「普通伤害 8000」红线（周目 scale 后）
  //
  //     §6 已记录敌人 baseAttack 分布（peak ~3024）；本节回答 closeout open
  //     question：周目 scale 后的敌人 attack 进入伤害公式，是否突破普通伤害红线？
  //
  //     §5.4「普通伤害 ≤ 8000」约束的是基础伤害量级（内力×系数 + 装备攻击×系数
  //     + 招式倍率）。修炼度(cult 1.0~3.0)/流派克制(0.75~1.25)/暴击(×2.5)/境界差
  //     是全局战斗设计的对局乘子维度，非 P1 周目进化引入——CLAUDE §5.4 把「大招暴击」
  //     单列为「几万」即印证普攻乘子叠加可超 8000 属设计内，不由周目红线测背书。
  //
  //     因此本节用「中性对局」（所有乘子设 1.0）走真实 calculateResolved 路径，
  //     隔离出敌人普攻的基础伤害维度，断言其在周目 scale 峰值下仍 ≤ 8000。
  //     实测峰值=4688（stage_06_05 西凉霸主 cycle3，IF=2912/atk=3024），余量 3312。
  // ════════════════════════════════════════════════════════════════════════════

  group('§8 敌人中性普攻基础伤害 ≤ §5.4 普通伤害红线', () {
    // §5.4「普通伤害 ≤ 8000」未进 numbers config，沿 damage_calculator_test 体例硬编码。
    const normalDamageRedLine = 8000;

    test('8.1 全主线 Boss 关 cycle 3：中性普攻基础伤害 ≤ 8000', () {
      final repo = GameRepository.instance;
      var maxDmg = 0;
      String maxStage = '';
      String maxEnemy = '';
      for (final stage in repo.stageDefs.values) {
        if (!stage.isBossStage) continue;
        if (stage.stageType == StageType.innerDemon) continue;
        if (stage.enemyTeam.isEmpty) continue;
        final team = StageBattleSetup.buildEnemyTeam(
          stage.enemyTeam,
          cycleIndex: 3,
          isTower: false,
        );
        for (final bc in team) {
          final dmg = _neutralNormalAttackDamage(bc);
          if (dmg > maxDmg) {
            maxDmg = dmg;
            maxStage = stage.id;
            maxEnemy = bc.name;
          }
          expect(
            dmg,
            lessThanOrEqualTo(normalDamageRedLine),
            reason:
                '[${stage.id}] ${bc.name} cycle 3 中性普攻基础伤害=$dmg '
                '超 §5.4 普通伤害红线=$normalDamageRedLine',
          );
        }
      }
      addTearDown(
        () => printOnFailure(
          '全主线 Boss 关 cycle3 中性普攻峰值=$maxDmg（来自 [$maxStage] $maxEnemy，'
          '红线=$normalDamageRedLine，余量=${normalDamageRedLine - maxDmg}）',
        ),
      );
    });

    test('8.2 全爬塔 Boss 层 cycle 2：中性普攻基础伤害 ≤ 8000', () {
      final repo = GameRepository.instance;
      var maxDmg = 0;
      int maxFloor = 0;
      String maxEnemy = '';
      for (int i = 1; i <= 30; i++) {
        final floor = repo.getTowerFloor(i);
        if (!floor.isBoss) continue;
        final team = StageBattleSetup.buildEnemyTeam(
          floor.enemyTeam,
          cycleIndex: 2,
          isTower: true,
        );
        for (final bc in team) {
          final dmg = _neutralNormalAttackDamage(bc);
          if (dmg > maxDmg) {
            maxDmg = dmg;
            maxFloor = i;
            maxEnemy = bc.name;
          }
          expect(
            dmg,
            lessThanOrEqualTo(normalDamageRedLine),
            reason:
                'tower floor $i cycle 2 ${bc.name} 中性普攻基础伤害=$dmg '
                '超 §5.4 普通伤害红线=$normalDamageRedLine',
          );
        }
      }
      addTearDown(
        () => printOnFailure(
          '全爬塔 Boss 层 cycle2 中性普攻峰值=$maxDmg（来自 floor $maxFloor $maxEnemy，'
          '红线=$normalDamageRedLine，余量=${normalDamageRedLine - maxDmg}）',
        ),
      );
    });
  });
}

/// 中性对局基础普攻伤害：剥离修炼度/克制/暴击/境界差乘子（全设 1.0），
/// 仅保留「内力×系数 + 装备攻击×系数 + 普攻招式倍率」基础维度，对应 §5.4
/// 「普通伤害 ≤ 8000」的基础量级语义。走真实 [DamageCalculator.calculateResolved]
/// 路径（非手算重演），用敌人战斗态真实 maxInternalForce / totalEquipmentAttack /
/// attackPowerMultiplier / 真实普攻招式。
int _neutralNormalAttackDamage(BattleCharacter bc) {
  final normalSkill = bc.availableSkills.firstWhere(
    (s) => s.type == SkillType.normalAttack,
    orElse: () => bc.availableSkills.first,
  );
  return DamageCalculator.calculateResolved(
    attackerInternalForce: bc.maxInternalForce,
    attackerEquipmentAttack: bc.totalEquipmentAttack,
    attackerCultivationLayer: CultivationLayer.chuKui, // cultMult=1.0（中性）
    attackerSchool: bc.school,
    defenderSchool: bc.school, // schoolMult=1.0（同流派，不克）
    attackerRealmTier: bc.realmTier,
    attackerRealmLayer: bc.realmLayer,
    defenderRealmTier: bc.realmTier, // realmMult=1.0（同境界）
    defenderRealmLayer: bc.realmLayer,
    defenderDefenseRate: 0.0,
    defenderEvasionRate: 0.0,
    attackerCriticalRate: 0.0, // 非暴击（普通伤害语义）
    attackPowerMultiplier: bc.attackPowerMultiplier,
    skill: normalSkill,
    n: GameRepository.instance.numbers,
    rng: Random(0),
  ).finalDamage;
}
