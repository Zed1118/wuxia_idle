import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/equipment/application/enhancement_service.dart';
import 'package:wuxia_idle/shared/battle_shared/derived_stats.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../../support/test_data.dart';

void main() {
  setUp(() async {
    GameRepository.resetForTest();
    final numbers = parseYamlMap(await loadTestAsset('data/numbers.yaml'));
    final tiers = (numbers['realms'] as Map)['tiers'] as List;
    final wuSheng = tiers.cast<Map>().singleWhere(
      (tier) => tier['tier'] == 'wuSheng',
    );
    final dengFeng = (wuSheng['layers'] as List).cast<Map>().singleWhere(
      (layer) => layer['layer'] == 'dengFeng',
    );
    // 保留装载器要求的全部境界行，只在测试配置中降低绝对层数终点。
    dengFeng['absolute_level'] = 48;
    (numbers['progression'] as Map)['release_cap']['max_absolute_realm_level'] =
        48;
    final numbersOverride = jsonEncode(numbers);
    await GameRepository.loadAllDefs(
      loader: (path) async {
        if (path.endsWith('numbers.yaml')) return numbersOverride;
        return loadTestAsset(path);
      },
    );
  });

  tearDown(GameRepository.resetForTest);

  test('修改 realms 表后最大绝对层数随表降至 48', () {
    expect(RealmUtils.maxAbsoluteLevel, 48);
  });

  test('realms 上限 48 时展示等级 490 不能继续强化且不扣材料', () {
    final eq = Equipment.create(
      defId: 'test',
      tier: EquipmentTier.haoJiaHuo,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      enhanceLevel: 48,
      obtainedAt: DateTime(2026, 9, 20),
      obtainedFrom: 'test',
    );
    final config = GameRepository.instance.numbers.enhancement;
    final result = EnhancementService.tryEnhance(
      eq: eq,
      characterAbsoluteLevel: 490,
      rng: _SuccessRng(),
      currentMojianshi: config.mojianshiCostFor(eq.enhanceLevel + 1),
      currentDuancai: config.duancaiCostFor(eq.enhanceLevel + 1),
      config: config,
    );

    expect(result.outcome, EnhanceOutcome.capped);
    expect(eq.enhanceLevel, 48);
    expect(result.newLevel, 48);
    expect(result.mojianshiSpent, 0);
    expect(result.duancaiSpent, 0);
  });
}

class _SuccessRng implements Rng {
  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;

  @override
  T pick<T>(List<T> list) => list.first;
}
