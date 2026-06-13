import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// B2 + D1 fix:_enemyToBattle cycleIndex scale + 词条注入 + buildEnemyTeamsPerWave cycleIndex 传递测试。
///
/// 复用 GameRepository.loadAllDefs 加载真实 numbers（含 cycle_evolution 段），
/// 通过 @visibleForTesting debugEnemyToBattle 直接测 _enemyToBattle，
/// 不需要 Isar（纯静态方法）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── 共用 EnemyDef fixture（普通主线敌人，无自带蓄力技）─────────────────────
  const normalEnemy = EnemyDef(
    id: 'test_enemy_normal',
    name: '测试敌人',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 1000,
    baseAttack: 500,
    baseSpeed: 100,
    skillIds: [],
    iconPath: 'assets/enemies/stub.png',
    isBoss: false,
  );

  // ── 高境界敌人（基础防御率已较高，用于测 defenseRate clamp）──────────────
  const highRealmEnemy = EnemyDef(
    id: 'test_enemy_high_realm',
    name: '高境界敌人',
    realmTier: RealmTier.zongShi,
    realmLayer: RealmLayer.dengFeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 20000,
    baseAttack: 1800,
    baseSpeed: 150,
    skillIds: [],
    iconPath: 'assets/enemies/stub.png',
    isBoss: false,
  );

  // ── 自带蓄力技的 Boss（用于测识破不覆盖）────────────────────────────────
  const bossWithCharge = EnemyDef(
    id: 'test_boss_charge',
    name: '测试Boss',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 10000,
    baseAttack: 800,
    baseSpeed: 120,
    skillIds: [],
    iconPath: 'assets/enemies/stub.png',
    isBoss: true,
    chargeSkillId: 'skill_own_charge',
  );

  // ══════════════════════════════════════════════════════════════════════════
  // cycle 1 = 零变化（回归：不破既有行为）
  // ══════════════════════════════════════════════════════════════════════════
  group('cycle 1 回归（与旧行为一致）', () {
    late BattleCharacter c1;
    setUp(() {
      c1 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 1,
        isTower: false,
      );
    });

    test('activeBuffs 为空', () {
      expect(c1.activeBuffs, isEmpty,
          reason: 'cycle 1 不应注入任何周目词条');
    });

    test('chargeSkillId 保持 null（无自带）', () {
      expect(c1.chargeSkillId, isNull);
    });

    test('hp/attack 不变（scale=1.0）', () {
      expect(c1.maxHp, 1000);
      expect(c1.totalEquipmentAttack, 500);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // cycle 3 主线：hp/attack ×1.12 + 御体 + 反震 + 识破 词条
  // ══════════════════════════════════════════════════════════════════════════
  group('cycle 3 主线敌人', () {
    late BattleCharacter c1;
    late BattleCharacter c3;

    setUp(() {
      c1 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 1,
        isTower: false,
      );
      c3 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 3,
        isTower: false,
      );
    });

    test('hp × scale(1.12)', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      final scale = 1 + ce.scalePerCycle * (3 - 1); // 1 + 0.06 * 2 = 1.12
      expect(c3.maxHp, (1000 * scale).toInt());
      expect(c3.currentHp, c3.maxHp, reason: 'currentHp = maxHp（满血进战斗）');
    });

    test('attack × scale(1.12)', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      final scale = 1 + ce.scalePerCycle * (3 - 1);
      expect(c3.totalEquipmentAttack, (500 * scale).toInt());
    });

    test('御体：defenseRate 高于 cycle 1', () {
      expect(c3.defenseRate, greaterThan(c1.defenseRate),
          reason: '御体词条应提升防御率');
    });

    test('识破：chargeSkillId = config 指定值（敌无自带时）', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      expect(c3.chargeSkillId, ce.traits.shipo.chargeSkillId,
          reason: '敌无自带蓄力技，识破注入 config.chargeSkillId');
    });

    test('activeBuffs 含 cycle_yuti / cycle_fanzhen / cycle_shipo', () {
      expect(c3.activeBuffs,
          containsAll(['cycle_yuti', 'cycle_fanzhen', 'cycle_shipo']),
          reason: 'cycle 3 主线：yuti + fanzhen + shipo 词条标签全部注入');
    });

    test('activeBuffs 不含 cycle_zhenqi（主线 assignment 不分配）', () {
      expect(c3.activeBuffs, isNot(contains('cycle_zhenqi')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // cycle 2 主线：只有御体（c2 档加成）
  // ══════════════════════════════════════════════════════════════════════════
  group('cycle 2 主线', () {
    late BattleCharacter c2;
    late BattleCharacter c3;

    setUp(() {
      c2 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 2,
        isTower: false,
      );
      c3 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 3,
        isTower: false,
      );
    });

    test('activeBuffs 只含 cycle_yuti', () {
      expect(c2.activeBuffs, containsAll(['cycle_yuti']));
      expect(c2.activeBuffs, isNot(contains('cycle_fanzhen')));
      expect(c2.activeBuffs, isNot(contains('cycle_shipo')));
    });

    test('c2 御体 defenseRateBonusC2 < c3 defenseRateBonusC3', () {
      // c2 用 defenseRateBonusC2(0.08)，c3 用 defenseRateBonusC3(0.12)
      expect(c3.defenseRate, greaterThan(c2.defenseRate),
          reason: 'c3 御体档位加成（0.12）大于 c2（0.08）');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 御体叠加后 defenseRate ≤ defenseRateCap
  // ══════════════════════════════════════════════════════════════════════════
  test('御体叠加后 defenseRate clamp ≤ defenseRateCap', () {
    final c3 = StageBattleSetup.debugEnemyToBattle(
      enemy: highRealmEnemy,
      slotIndex: 0,
      cycleIndex: 3,
      isTower: false,
    );
    final ce = GameRepository.instance.numbers.cycleEvolution;
    expect(c3.defenseRate, lessThanOrEqualTo(ce.defenseRateCap),
        reason: '防御率不应超过 defenseRateCap=${ce.defenseRateCap}');
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 爬塔普通关 cycle 2：真气 + 御体
  // ══════════════════════════════════════════════════════════════════════════
  group('爬塔普通关 cycle 2（tower_normal）', () {
    late BattleCharacter c1;
    late BattleCharacter c2;

    setUp(() {
      c1 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 1,
        isTower: true,
      );
      c2 = StageBattleSetup.debugEnemyToBattle(
        enemy: normalEnemy,
        slotIndex: 0,
        cycleIndex: 2,
        isTower: true,
      );
    });

    test('maxInternalForce > cycle 1（scale + 真气 pct 双重叠加）', () {
      expect(c2.maxInternalForce, greaterThan(c1.maxInternalForce),
          reason: 'scale + 真气 pct 双重叠加后 IF 应更高');
    });

    test('activeBuffs 含 cycle_yuti 和 cycle_zhenqi', () {
      expect(c2.activeBuffs, containsAll(['cycle_yuti', 'cycle_zhenqi']));
    });

    test('无 cycle_shipo / cycle_fanzhen（tower_normal c2 不分配）', () {
      expect(c2.activeBuffs, isNot(contains('cycle_shipo')));
      expect(c2.activeBuffs, isNot(contains('cycle_fanzhen')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 识破：敌有自带蓄力技时不覆盖
  // ══════════════════════════════════════════════════════════════════════════
  test('识破：敌已有 chargeSkillId 时保留自身不覆盖', () {
    // tower_boss c2: [yuti, fanzhen, shipo, ningjia]，有 shipo 词条
    // 但 bossWithCharge 自带 chargeSkillId='skill_own_charge'，应保留
    final c2 = StageBattleSetup.debugEnemyToBattle(
      enemy: bossWithCharge,
      slotIndex: 0,
      cycleIndex: 2,
      isTower: true,
    );
    expect(c2.chargeSkillId, 'skill_own_charge',
        reason: '敌有自带蓄力技时，识破不覆盖，保留 skill_own_charge');
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 真气红线：internalForce clamp ≤ red line
  // ══════════════════════════════════════════════════════════════════════════
  test('真气 + scale 叠加后 maxInternalForce ≤ 内力红线', () {
    final c2 = StageBattleSetup.debugEnemyToBattle(
      enemy: highRealmEnemy,
      slotIndex: 0,
      cycleIndex: 2,
      isTower: true,
    );
    final redLine =
        GameRepository.instance.numbers.combat.redLines.internalForceMax;
    expect(c2.maxInternalForce, lessThanOrEqualTo(redLine),
        reason: '真气 + scale 后 IF 不应突破 §5.4 红线=$redLine');
  });

  // ══════════════════════════════════════════════════════════════════════════
  // D1 fix 回归：buildEnemyTeamsPerWave 传入 cycleIndex 后 wave 敌人随周目 scale
  // ══════════════════════════════════════════════════════════════════════════
  group('buildEnemyTeamsPerWave cycleIndex scale（D1 fix 回归）', () {
    // 最小 massBattle StageDef：2 波 × 各 2 敌
    const massBattleStage = StageDef(
      id: 'test_mass_battle_scale',
      name: '测试群战关',
      stageType: StageType.massBattle,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [normalEnemy],
      isBossStage: false,
      dropEquipmentDefIds: [],
      dropItemDefIds: [],
      baseExpReward: 0,
      difficultyMultiplier: 1.0,
      massBattleWaveCount: 2,
      massBattleEnemyCounts: [2, 2],
    );

    test('cycleIndex:1 → cycleIndex:2 wave 敌人 hp/attack 各 ×1.06', () {
      final waves1 =
          StageBattleSetup.buildEnemyTeamsPerWave(massBattleStage,
              cycleIndex: 1);
      final waves2 =
          StageBattleSetup.buildEnemyTeamsPerWave(massBattleStage,
              cycleIndex: 2);

      expect(waves1, hasLength(2), reason: '应有 2 波');
      expect(waves2, hasLength(2));

      final ce = GameRepository.instance.numbers.cycleEvolution;
      final scale = 1 + ce.scalePerCycle * (2 - 1); // 1.06

      for (var w = 0; w < 2; w++) {
        for (var i = 0; i < waves1[w].length; i++) {
          expect(
            waves2[w][i].maxHp,
            (waves1[w][i].maxHp * scale).toInt(),
            reason: 'wave=$w enemy=$i hp 应 ×$scale',
          );
          expect(
            waves2[w][i].totalEquipmentAttack,
            (waves1[w][i].totalEquipmentAttack * scale).toInt(),
            reason: 'wave=$w enemy=$i attack 应 ×$scale',
          );
        }
      }
    });
  });
}
