import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';

/// Batch 2.2.A R1 单元:InnerDemonService.isLayerLocked 拦截判定。
///
/// spec: docs/handoff/p2_x_inner_demon_spec_2026-05-22.md §三 + numbers.yaml
/// inner_demon.required_realm_layer 7 配。

InnerDemonDef _fullDef() => const InnerDemonDef(
      mirrorBuffPerStage: {},
      mirrorCaps: InnerDemonMirrorCaps(
        hpMax: 20000,
        internalForceMax: 15000,
        attackPowerMax: 2000,
      ),
      failurePenalty: InnerDemonFailurePenalty(
        internalForceMultiplier: 0.85,
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
          'attack_power_max': 2000,
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
}
