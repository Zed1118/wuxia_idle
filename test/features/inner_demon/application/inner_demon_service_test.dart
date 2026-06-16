import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';

/// Batch 2.2.A R1 单元:InnerDemonService.isLayerLocked 拦截判定。
///
/// spec: docs/handoff/p2_x_inner_demon_spec_2026-05-22.md §三 + numbers.yaml
/// inner_demon.required_realm_layer 7 配。

InnerDemonDef _fullDef() => const InnerDemonDef(
      mirrorBuffPerStage: {
        'stage_inner_demon_01': 0.10,
        'stage_inner_demon_02': 0.12,
        'stage_inner_demon_03': 0.14,
        'stage_inner_demon_04': 0.16,
        'stage_inner_demon_05': 0.18,
        'stage_inner_demon_06': 0.20,
        'stage_inner_demon_07': 0.40, // Batch 2.5.C 升档(+40% 单副本)
      },
      mirrorCaps: InnerDemonMirrorCaps(
        hpMax: 20000,
        internalForceMax: 15000,
        attackPowerMax: 6000,
      ),
      failurePenalty: InnerDemonFailurePenalty(
        internalForceMultiplier: 0.85,
        internalForceFloorPct: 0.50,
        mainCultivationMultiplier: 0.90,
        subCultivationMultiplier: 1.00,
        debuffId: 'inner_demon_residue',
        debuffClearViaRetreatHours: 8,
      ),
      residueDebuff: InnerDemonResidueDebuff(
        battleOutputMultiplier: 0.95,
        internalForceRecoveryMultiplier: 0.80,
      ),
      unlockTriggers: {
        'stage_06_05': 'stage_inner_demon_01',
        'stage_inner_demon_01': 'stage_inner_demon_02',
        'stage_inner_demon_02': 'stage_inner_demon_03',
        'stage_inner_demon_03': 'stage_inner_demon_04',
        'stage_inner_demon_04': 'stage_inner_demon_05',
        'stage_inner_demon_05': 'stage_inner_demon_06',
        'stage_inner_demon_06': 'stage_inner_demon_07',
      },
      // 拦截关 stage required_realm_layer = 玩家"当前所在 layer"(升 layer N→N+1
      // 时被 stage_inner_demon_N 拦截,N ∈ qiMeng..huaJing)。
      requiredRealmLayer: {
        'stage_inner_demon_01': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.qiMeng),
        'stage_inner_demon_02': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.ruMen),
        'stage_inner_demon_03': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.shuLian),
        'stage_inner_demon_04': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.jingTong),
        'stage_inner_demon_05': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.yuanShu),
        'stage_inner_demon_06': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.huaJing),
        'stage_inner_demon_07': RealmCoord(
            tier: RealmTier.wuSheng, layer: RealmLayer.dengFeng),
      },
    );

void main() {
  group('InnerDemonService.isLayerLocked', () {
    test('R1.1 非 wuSheng tier 升迁 → false(不影响 Demo + Ch4-6)', () {
      final def = _fullDef();
      // 例:sanLiu·dengFeng → erLiu·qiMeng 跨 tier
      expect(
        InnerDemonService.isLayerLocked(
          nextTier: RealmTier.erLiu,
          nextLayer: RealmLayer.qiMeng,
          innerDemonDef: def,
          clearedStageIds: const {},
        ),
        isFalse,
      );
      // 例:zongShi·huaJing → zongShi·dengFeng 同 tier 内
      expect(
        InnerDemonService.isLayerLocked(
          nextTier: RealmTier.zongShi,
          nextLayer: RealmLayer.dengFeng,
          innerDemonDef: def,
          clearedStageIds: const {},
        ),
        isFalse,
      );
    });

    test('R1.2 zongShi·dengFeng → wuSheng·qiMeng 跨 tier 升 → false(Ch6 自动升)',
        () {
      final def = _fullDef();
      expect(
        InnerDemonService.isLayerLocked(
          nextTier: RealmTier.wuSheng,
          nextLayer: RealmLayer.qiMeng,
          innerDemonDef: def,
          clearedStageIds: const {}, // 一关都没通也不拦
        ),
        isFalse,
      );
    });

    test('R1.3 wuSheng 内 qiMeng → ruMen,inner_demon_01 未通 → true(拦)', () {
      final def = _fullDef();
      expect(
        InnerDemonService.isLayerLocked(
          nextTier: RealmTier.wuSheng,
          nextLayer: RealmLayer.ruMen,
          innerDemonDef: def,
          clearedStageIds: const {},
        ),
        isTrue,
      );
    });

    test('R1.4 inner_demon_01 已通 → qiMeng → ruMen 放行(false)', () {
      final def = _fullDef();
      expect(
        InnerDemonService.isLayerLocked(
          nextTier: RealmTier.wuSheng,
          nextLayer: RealmLayer.ruMen,
          innerDemonDef: def,
          clearedStageIds: const {'stage_inner_demon_01'},
        ),
        isFalse,
      );
    });

    test('R1.5 wuSheng 7 layer 阶梯锁:仅通 inner_demon_01..03 → 4-7 仍拦',
        () {
      final def = _fullDef();
      final cleared = {
        'stage_inner_demon_01',
        'stage_inner_demon_02',
        'stage_inner_demon_03',
      };
      // qiMeng → ruMen / ruMen → shuLian / shuLian → jingTong 全放行
      for (final next in [
        RealmLayer.ruMen,
        RealmLayer.shuLian,
        RealmLayer.jingTong,
      ]) {
        expect(
          InnerDemonService.isLayerLocked(
            nextTier: RealmTier.wuSheng,
            nextLayer: next,
            innerDemonDef: def,
            clearedStageIds: cleared,
          ),
          isFalse,
          reason: 'inner_demon_01..03 已通,$next 应放行',
        );
      }
      // jingTong → yuanShu / yuanShu → huaJing / huaJing → dengFeng 全拦
      for (final next in [
        RealmLayer.yuanShu,
        RealmLayer.huaJing,
        RealmLayer.dengFeng,
      ]) {
        expect(
          InnerDemonService.isLayerLocked(
            nextTier: RealmTier.wuSheng,
            nextLayer: next,
            innerDemonDef: def,
            clearedStageIds: cleared,
          ),
          isTrue,
          reason: 'inner_demon_04 之后未通,$next 应拦',
        );
      }
    });

    test('R1.6 empty def(fixture 兼容 / 配置无 required_realm_layer)→ false',
        () {
      final def = InnerDemonDef.empty();
      expect(
        InnerDemonService.isLayerLocked(
          nextTier: RealmTier.wuSheng,
          nextLayer: RealmLayer.ruMen,
          innerDemonDef: def,
          clearedStageIds: const {},
        ),
        isFalse,
        reason: 'empty def → unlockTriggers/requiredRealmLayer 全空,不拦',
      );
    });
  });

  group('InnerDemonDef.fromYaml', () {
    test('完整 yaml 段解析正确', () {
      final y = <String, dynamic>{
        'mirror_buff_per_stage': {
          'stage_inner_demon_01': 0.10,
          'stage_inner_demon_07': 0.20,
        },
        'mirror_caps': {
          'hp_max': 20000,
          'internal_force_max': 15000,
          'attack_power_max': 6000,
        },
        'failure_penalty': {
          'internal_force_multiplier': 0.85,
          'main_cultivation_multiplier': 0.90,
          'sub_cultivation_multiplier': 1.00,
          'debuff_id': 'inner_demon_residue',
          'debuff_clear_via_retreat_hours': 8,
        },
        'residue_debuff': {
          'battle_output_multiplier': 0.95,
          'internal_force_recovery_multiplier': 0.80,
        },
        'unlock_triggers': {
          'stage_06_05': 'stage_inner_demon_01',
        },
        'required_realm_layer': {
          'stage_inner_demon_01': {'tier': 'wuSheng', 'layer': 'qiMeng'},
          'stage_inner_demon_07': {'tier': 'wuSheng', 'layer': 'dengFeng'},
        },
      };
      final def = InnerDemonDef.fromYaml(y);
      expect(def.mirrorBuffPerStage['stage_inner_demon_01'], 0.10);
      expect(def.mirrorBuffPerStage['stage_inner_demon_07'], 0.20);
      expect(def.mirrorCaps.hpMax, 20000);
      expect(def.failurePenalty.internalForceMultiplier, 0.85);
      expect(def.failurePenalty.debuffId, 'inner_demon_residue');
      expect(def.residueDebuff.battleOutputMultiplier, 0.95);
      expect(def.unlockTriggers['stage_06_05'], 'stage_inner_demon_01');
      expect(
        def.requiredRealmLayer['stage_inner_demon_01'],
        const RealmCoord(tier: RealmTier.wuSheng, layer: RealmLayer.qiMeng),
      );
      expect(
        def.requiredRealmLayer['stage_inner_demon_07'],
        const RealmCoord(tier: RealmTier.wuSheng, layer: RealmLayer.dengFeng),
      );
    });

    test('null yaml → empty def(fixture 兼容)', () {
      final def = InnerDemonDef.fromYaml(null);
      expect(def.mirrorBuffPerStage, isEmpty);
      expect(def.unlockTriggers, isEmpty);
      expect(def.requiredRealmLayer, isEmpty);
      // 默认值合理
      expect(def.mirrorCaps.hpMax, 20000);
      expect(def.failurePenalty.internalForceMultiplier, 0.85);
    });
  });

  // ===========================================================================
  // Batch 2.2.B R2-R3:buildMirrorEnemyTeam 镜像 enemy 构造
  // ===========================================================================
  group('InnerDemonService.buildMirrorEnemyTeam', () {
    test('R2.1 镜像数值 ×(1+buff)+ 字段重置(stage_inner_demon_01 +10%)', () {
      final player = _mockPlayer(
        slotIndex: 0,
        characterId: 100,
        name: '玩家·主角',
        maxHp: 12000,
        maxInternalForce: 10000,
        totalEquipmentAttack: 1500,
      );
      final def = _fullDef();
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: [player],
        stageId: 'stage_inner_demon_01',
        innerDemonDef: def,
      );
      expect(mirrors, hasLength(1));
      final m = mirrors[0];
      expect(m.maxHp, 13200, reason: '12000 ×1.10');
      expect(m.currentHp, 13200, reason: '开战满血');
      expect(m.maxInternalForce, 11000, reason: '10000 ×1.10');
      expect(m.currentInternalForce, 11000, reason: '开战满内力');
      expect(m.totalEquipmentAttack, 1650, reason: '1500 ×1.10');
      // 字段重置
      expect(m.characterId, -1, reason: 'slotIndex=0 → -1 negative id 防冲突');
      expect(m.name, '心魔·玩家·主角');
      expect(m.teamSide, 1, reason: '右队');
      expect(m.slotIndex, 0);
      expect(m.actionPoint, 0);
      expect(m.isAlive, isTrue);
      expect(m.skillCooldowns, isEmpty);
      expect(m.activeBuffs, isEmpty);
      expect(m.internalInjury, isNull);
      expect(m.iconPath, isNull);
      // 保留字段:realm / school / speed / crit / mainCultivationLayer
      expect(m.realmTier, player.realmTier);
      expect(m.realmLayer, player.realmLayer);
      expect(m.school, player.school);
      expect(m.speed, player.speed);
      expect(m.criticalRate, player.criticalRate);
      expect(m.mainCultivationLayer, player.mainCultivationLayer);
    });

    test('R2.2 3v3 镜像:slot/id 各自正确', () {
      final players = [
        _mockPlayer(slotIndex: 0, characterId: 100, name: '主角'),
        _mockPlayer(slotIndex: 1, characterId: 101, name: '徒弟甲'),
        _mockPlayer(slotIndex: 2, characterId: 102, name: '徒弟乙'),
      ];
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: players,
        stageId: 'stage_inner_demon_06',
        innerDemonDef: _fullDef(),
      );
      expect(mirrors, hasLength(3));
      expect(mirrors[0].characterId, -1);
      expect(mirrors[1].characterId, -2);
      expect(mirrors[2].characterId, -3);
      expect(mirrors[0].name, '心魔·主角');
      expect(mirrors[1].name, '心魔·徒弟甲');
      expect(mirrors[2].name, '心魔·徒弟乙');
      expect(mirrors[0].slotIndex, 0);
      expect(mirrors[1].slotIndex, 1);
      expect(mirrors[2].slotIndex, 2);
      for (final m in mirrors) {
        expect(m.teamSide, 1);
      }
    });

    test('R2.3 def 无该 stage_id 配置 → buff=0 镜像保持原样', () {
      final player = _mockPlayer(
        maxHp: 12000,
        totalEquipmentAttack: 1500,
      );
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: [player],
        stageId: 'stage_unknown',
        innerDemonDef: _fullDef(),
      );
      expect(mirrors[0].maxHp, 12000, reason: 'buff=0 → 不强化');
      expect(mirrors[0].totalEquipmentAttack, 1500);
    });

    test('R2.4 playerTeam > 3 → 最多 3 镜像(BattleState slot 限制)', () {
      final players = List.generate(
        5,
        (i) => _mockPlayer(slotIndex: i % 3, characterId: 100 + i, name: 'p$i'),
      );
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: players,
        stageId: 'stage_inner_demon_01',
        innerDemonDef: _fullDef(),
      );
      expect(mirrors, hasLength(3));
    });

    test('R3.1 §5.4 红线 cap:player 接近上限 + buff → 镜像不破红线', () {
      // 玩家 wuSheng·dengFeng 满 build,HP/IF/Attack 接近 cap 上限
      // (Batch 2.5.C: attack_power_max 2000 → 6000,纠 §5.4 维度锚错。
      //  §5.4 装备攻击 2000 是单件 cap,镜像 totalEquipmentAttack 是 3 件
      //  求和;cap 6000 = 3 × §5.4 单件 2000。fullDef stage_inner_demon_07
      //  buff +40% Batch 2.5.C 升档。)
      final player = _mockPlayer(
        maxHp: 19800,
        maxInternalForce: 14500,
        totalEquipmentAttack: 5500,
      );
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: [player],
        stageId: 'stage_inner_demon_07',
        innerDemonDef: _fullDef(),
      );
      final m = mirrors[0];
      // 19800 ×1.40 = 27720 → cap 20000
      expect(m.maxHp, 20000, reason: '§5.4 玩家血上限 cap');
      expect(m.currentHp, 20000);
      // 14500 ×1.40 = 20300 → cap 15000
      expect(m.maxInternalForce, 15000, reason: '§5.4 内力上限 cap');
      expect(m.currentInternalForce, 15000);
      // 5500 ×1.40 = 7700 → cap 6000(3 × §5.4 单件 2000)
      expect(m.totalEquipmentAttack, 6000,
          reason: 'Batch 2.5.C: 镜像 totalEquipmentAttack cap '
              '(3 × §5.4 单件 2000 = 6000)');
    });

    test('R3.2 player 远低于 cap + 高 buff → 数值未触 cap 不变形', () {
      final player = _mockPlayer(
        maxHp: 5000,
        maxInternalForce: 3000,
        totalEquipmentAttack: 800,
      );
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: [player],
        stageId: 'stage_inner_demon_07', // +40%(Batch 2.5.C 升档)
        innerDemonDef: _fullDef(),
      );
      final m = mirrors[0];
      expect(m.maxHp, 7000, reason: '5000 ×1.40,未达 20000 cap');
      expect(m.maxInternalForce, 4200);
      expect(m.totalEquipmentAttack, 1120);
    });

    test('R3.3 empty def(fixture 兼容)→ 0 buff 镜像保持原样不破', () {
      final player = _mockPlayer(maxHp: 12000, totalEquipmentAttack: 1500);
      final mirrors = InnerDemonService.buildMirrorEnemyTeam(
        playerTeam: [player],
        stageId: 'stage_inner_demon_01',
        innerDemonDef: InnerDemonDef.empty(),
      );
      expect(mirrors[0].maxHp, 12000);
      expect(mirrors[0].totalEquipmentAttack, 1500);
    });
  });
}

/// 构造测试用 BattleCharacter(skipping fromCharacter 全 pipeline)。
BattleCharacter _mockPlayer({
  int slotIndex = 0,
  int characterId = 100,
  String name = '玩家',
  int maxHp = 12000,
  int maxInternalForce = 10000,
  int totalEquipmentAttack = 1500,
  RealmTier realmTier = RealmTier.wuSheng,
  RealmLayer realmLayer = RealmLayer.qiMeng,
  TechniqueSchool school = TechniqueSchool.gangMeng,
}) =>
    BattleCharacter(
      characterId: characterId,
      name: name,
      realmTier: realmTier,
      realmLayer: realmLayer,
      school: school,
      maxHp: maxHp,
      currentHp: maxHp,
      maxInternalForce: maxInternalForce,
      currentInternalForce: maxInternalForce,
      speed: 250,
      criticalRate: 0.15,
      evasionRate: 0.05,
      defenseRate: 0.35,
      totalEquipmentAttack: totalEquipmentAttack,
      mainCultivationLayer: CultivationLayer.jiJing,
      availableSkills: const <SkillDef>[],
      skillCooldowns: const {'skill_a': 2}, // 验证镜像清空 CD
      activeBuffs: const ['founder_buff'],   // 验证镜像清空 buff
      actionPoint: 500, // 验证镜像归零
      isAlive: true,
      teamSide: 0,
      slotIndex: slotIndex,
    );
