import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/domain/rare_bonus_drop.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

/// 第八阶段 E·稀有彩头全方法集成测(真装备池:选中阶 → 返回该阶真装备实例)。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUpAll(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });
  tearDownAll(GameRepository.resetForTest);

  DropService svc() => DropService(
        equipmentDefLookup: GameRepository.instance.getEquipment,
      );

  List<dynamic> poolOf(EquipmentTier t) => GameRepository
      .instance.equipmentDefs.values
      .where((e) => e.tier == t)
      .toList();

  test('+1 阶 chance=1.0 → 返回 baseTier+1 阶的真装备实例', () {
    final eq = svc().rollRareBonus(
      baseTier: EquipmentTier.xunChang,
      config: const RareBonusDropConfig(
        enabled: true,
        tiers: [RareBonusTier(offset: 1, chance: 1.0, chanceNgPlus: 1.0)],
      ),
      rng: DefaultRng(seed: 3),
      poolForTier: (tier) => GameRepository.instance.equipmentDefs.values
          .where((e) => e.tier == tier)
          .toList(growable: false),
    );
    expect(eq, isNotNull);
    expect(eq!.tier, EquipmentTier.xiangYang); // 寻常货 +1
    // 该装备确实属于像样货阶池。
    expect(poolOf(EquipmentTier.xiangYang).any((d) => d.id == eq.defId), isTrue);
  });

  test('全 chance=0 → 不掉(null)', () {
    final eq = svc().rollRareBonus(
      baseTier: EquipmentTier.xunChang,
      config: const RareBonusDropConfig(
        enabled: true,
        tiers: [RareBonusTier(offset: 1, chance: 0.0, chanceNgPlus: 0.0)],
      ),
      rng: DefaultRng(seed: 3),
      poolForTier: (tier) => GameRepository.instance.equipmentDefs.values
          .where((e) => e.tier == tier)
          .toList(growable: false),
    );
    expect(eq, isNull);
  });

  // 周目平衡 2026-06-26:rollRareBonus 透传 cycle → 二周目用 chance_ng_plus。
  test('cycle=2:一周目 chance=0 不掉、二周目 chance_ng_plus=1.0 掉真装备', () {
    const config = RareBonusDropConfig(
      enabled: true,
      tiers: [RareBonusTier(offset: 1, chance: 0.0, chanceNgPlus: 1.0)],
    );
    pool(tier) => GameRepository.instance.equipmentDefs.values
        .where((e) => e.tier == tier)
        .toList(growable: false);
    expect(
      svc().rollRareBonus(
          baseTier: EquipmentTier.xunChang,
          config: config,
          rng: DefaultRng(seed: 3),
          poolForTier: pool,
          cycle: 1),
      isNull,
    );
    final ng = svc().rollRareBonus(
        baseTier: EquipmentTier.xunChang,
        config: config,
        rng: DefaultRng(seed: 3),
        poolForTier: pool,
        cycle: 2);
    expect(ng, isNotNull);
    expect(ng!.tier, EquipmentTier.xiangYang);
  });

  // 周目平衡 2026-06-26:真 numbers.yaml → config 契约(yaml key 打错会静默退化)。
  test('真 numbers.yaml:rare_bonus chance_ng_plus + cycle_drop_bonus 正确加载', () {
    final n = GameRepository.instance.numbers;
    expect(n.rareBonusDrop.tiers, hasLength(2));
    expect(n.rareBonusDrop.tiers[0].offset, 1);
    expect(n.rareBonusDrop.tiers[0].chance, closeTo(0.05, 1e-9));
    expect(n.rareBonusDrop.tiers[0].chanceNgPlus, closeTo(0.08, 1e-9),
        reason: '高 1 阶二周目 8%');
    expect(n.rareBonusDrop.tiers[1].chance, closeTo(0.015, 1e-9));
    expect(n.rareBonusDrop.tiers[1].chanceNgPlus, closeTo(0.03, 1e-9),
        reason: '高 2 阶二周目 3%');
    expect(n.cycleDropBonus.materialQtyMultNgPlus, closeTo(1.5, 1e-9),
        reason: '二周目材料数量 ×1.5');
  });
}
