import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/light_foot/application/light_foot_service.dart';
import 'package:wuxia_idle/features/light_foot/domain/light_foot_def.dart';

/// LightFootService 单测(1.0 P3.1 §12.3 Batch B.1):
///   - statusOf 三态 cleared/available/locked
///   - chain 起点 light_foot_01 unlock 依赖 stage_06_05(Ch6 末 Boss)
///   - chain 中间 light_foot_02..05 unlock 依赖 prev light_foot_xx
///   - orderedStageIds 返回 5 关顺序(unlock chain 拓扑序)
///   - fixture 兼容(空 config 时 locked 兜底)
void main() {
  group('LightFootService.statusOf 三态判定', () {
    test('cleared:stageId ∈ clearedStageIds', () {
      final config = _testConfig();
      final result = LightFootService.statusOf(
        stageId: 'stage_light_foot_01',
        config: config,
        clearedStageIds: {'stage_light_foot_01'},
      );
      expect(result, LightFootStageStatus.cleared);
    });

    test('chain 起点 light_foot_01 available 需 stage_06_05 cleared', () {
      final config = _testConfig();

      // stage_06_05 cleared → light_foot_01 available
      final available = LightFootService.statusOf(
        stageId: 'stage_light_foot_01',
        config: config,
        clearedStageIds: {'stage_06_05'},
      );
      expect(available, LightFootStageStatus.available);

      // stage_06_05 未通 → light_foot_01 locked
      final locked = LightFootService.statusOf(
        stageId: 'stage_light_foot_01',
        config: config,
        clearedStageIds: const {},
      );
      expect(locked, LightFootStageStatus.locked);
    });

    test('chain 中间 light_foot_02 available 需 light_foot_01 cleared', () {
      final config = _testConfig();

      final available = LightFootService.statusOf(
        stageId: 'stage_light_foot_02',
        config: config,
        clearedStageIds: {'stage_06_05', 'stage_light_foot_01'},
      );
      expect(available, LightFootStageStatus.available);

      final locked = LightFootService.statusOf(
        stageId: 'stage_light_foot_02',
        config: config,
        clearedStageIds: {'stage_06_05'},
      );
      expect(locked, LightFootStageStatus.locked);
    });

    test('chain 末端 light_foot_05 available 需 light_foot_04 cleared', () {
      final config = _testConfig();

      final fullProgress = {
        'stage_06_05',
        'stage_light_foot_01',
        'stage_light_foot_02',
        'stage_light_foot_03',
        'stage_light_foot_04',
      };

      final available = LightFootService.statusOf(
        stageId: 'stage_light_foot_05',
        config: config,
        clearedStageIds: fullProgress,
      );
      expect(available, LightFootStageStatus.available);
    });

    test('fixture 兼容:未配置 unlock trigger → locked 兜底', () {
      final emptyConfig = LightFootDef.empty();

      final result = LightFootService.statusOf(
        stageId: 'stage_light_foot_01',
        config: emptyConfig,
        clearedStageIds: {'stage_06_05'},
      );
      expect(result, LightFootStageStatus.locked);
    });
  });

  group('LightFootService.orderedStageIds', () {
    test('返回 5 关顺序(unlock chain 拓扑序)', () {
      final config = _testConfig();
      final ordered = LightFootService.orderedStageIds(config);

      expect(ordered, [
        'stage_light_foot_01',
        'stage_light_foot_02',
        'stage_light_foot_03',
        'stage_light_foot_04',
        'stage_light_foot_05',
      ]);
    });

    test('empty config → 空 list', () {
      final emptyConfig = LightFootDef.empty();
      final ordered = LightFootService.orderedStageIds(emptyConfig);
      expect(ordered, isEmpty);
    });
  });
}

LightFootDef _testConfig() => const LightFootDef(
      terrainModifiers: {},
      stageTerrain: {
        'stage_light_foot_01': TerrainBiome.water,
        'stage_light_foot_02': TerrainBiome.rooftop,
        'stage_light_foot_03': TerrainBiome.bamboo,
        'stage_light_foot_04': TerrainBiome.water,
        'stage_light_foot_05': TerrainBiome.rooftop,
      },
      unlockTriggers: {
        'stage_06_05': 'stage_light_foot_01',
        'stage_light_foot_01': 'stage_light_foot_02',
        'stage_light_foot_02': 'stage_light_foot_03',
        'stage_light_foot_03': 'stage_light_foot_04',
        'stage_light_foot_04': 'stage_light_foot_05',
      },
    );
