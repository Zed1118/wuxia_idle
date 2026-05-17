import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

/// P0.1 #38 base maxHp 7 阶极值红线压测(spec §6 验收红线 + spec §5 矩阵)。
///
/// **设计目标**(spec §2):每阶 dengFeng + const 10 + 装备 hp_max 满
/// 派生 base maxHp ≤ 16667,让心法相生 hpPct 0.20 加成后 ≤ 20000
/// §5.4 玩家血量红线,**自然兜底不靠 applySynergy cap**。
///
/// **写法**(memory `feedback_red_line_test_semantics`):
///   - 7 阶主红线 case 写「≤ 16667」约束语义,不锁具体数字
///   - 单独 1 个销账锚点 case 锁 wushen 极值 == 16550 防数值漂移
///
/// **不走 Isar**:Character + Equipment 直接构造,公式纯函数 maxHp 调用。
/// **走真实 yaml**:GameRepository.loadAllDefs 读 data/*.yaml 实测 hp_max。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  /// 构造 7 阶 dengFeng 极限角色 + 该阶 hp_max 满装备 3 件(weapon/armor/accessory)。
  ({Character character, List<Equipment> equipped}) buildExtremum(
      RealmTier tier) {
    final repo = GameRepository.instance;
    final realmDef = repo.getRealm(tier, RealmLayer.dengFeng);
    final eqTier = realmDef.equipmentTierCap;

    EquipmentDef defOf(EquipmentSlot slot) => repo.equipmentDefs.values
        .firstWhere((d) => d.tier == eqTier && d.slot == slot);

    Equipment buildEq(EquipmentSlot slot) {
      final def = defOf(slot);
      return Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 1, 1),
        obtainedFrom: 'test_extremum',
        baseHealth: def.baseHealthMax,
      );
    }

    final character = Character.create(
      name: 'extremum_${tier.name}',
      realmTier: tier,
      realmLayer: RealmLayer.dengFeng,
      attributes: Attributes()
        ..constitution = 10
        ..enlightenment = 10
        ..agility = 10
        ..fortune = 10,
      rarity: RarityTier.jueShi,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 1, 1),
      internalForce: realmDef.internalForceMax,
      internalForceMax: realmDef.internalForceMax,
    );

    return (
      character: character,
      equipped: [
        buildEq(EquipmentSlot.weapon),
        buildEq(EquipmentSlot.armor),
        buildEq(EquipmentSlot.accessory),
      ],
    );
  }

  group('P0.1 #38 base maxHp 7 阶极值红线', () {
    // 7 阶主红线 case(约束语义不写具体数字)
    for (final tier in RealmTier.values) {
      test('${tier.name}·dengFeng base maxHp ≤ 16667(spec §2 目标)',
          () async {
        await GameRepository.loadAllDefs(loader: fileLoader);
        final (:character, :equipped) = buildExtremum(tier);
        final maxHp = CharacterDerivedStats.maxHp(
          character,
          equipped,
          GameRepository.instance.numbers,
        );
        expect(maxHp, lessThanOrEqualTo(16667),
            reason: '${tier.name}·dengFeng + const 10 + 装备 hp_max 满 '
                '极值 $maxHp 必 ≤ 16667 spec §2 目标'
                '(hpPct 0.20 加成后 ≤ 20000 §5.4 红线)');
      });
    }

    // 销账锚点 case(锁固定数字防数值漂移,memory 配套:锚点单独写)
    test('销账锚点·wushen·dengFeng 极值 == 16550(P0.1 #38 方案 D 决议)',
        () async {
      await GameRepository.loadAllDefs(loader: fileLoader);
      final (:character, :equipped) = buildExtremum(RealmTier.wuSheng);
      final maxHp = CharacterDerivedStats.maxHp(
        character,
        equipped,
        GameRepository.instance.numbers,
      );
      // 公式实测:1000 + 15000×0.5 + 10×400 + (350+2300+1400)
      //       = 1000 + 7500 + 4000 + 4050 = 16550
      expect(maxHp, 16550,
          reason: 'P0.1 #38 方案 D 决议锚点:wushen 极值精准 16550 '
              '(numbers.yaml IF×0.5 + const×400 + shenWu hp_max 1750-2300/1000-1400/150-350 装备)');
    });
  });
}
