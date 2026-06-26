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
        tiers: [RareBonusTier(offset: 1, chance: 1.0)],
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
        tiers: [RareBonusTier(offset: 1, chance: 0.0)],
      ),
      rng: DefaultRng(seed: 3),
      poolForTier: (tier) => GameRepository.instance.equipmentDefs.values
          .where((e) => e.tier == tier)
          .toList(growable: false),
    );
    expect(eq, isNull);
  });
}
