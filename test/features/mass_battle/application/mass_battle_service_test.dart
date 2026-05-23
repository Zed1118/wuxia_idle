import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/mass_battle/application/mass_battle_service.dart';
import 'package:wuxia_idle/features/mass_battle/domain/mass_battle_def.dart';

/// MassBattleService 单测(1.0 P3.2 §12.3 Batch 2.3):
///   - statusOf 三态 cleared/available/locked(沿 LightFootService 体例)
///   - chain 起点 mass_battle_01 unlock 依赖 stage_06_05(Ch6 末 Boss)
///   - chain 中间 mass_battle_02..05 unlock 依赖 prev mass_battle_xx
///   - orderedStageIds 返回 5 关顺序(unlock chain 拓扑序)
///   - formationFor 默认阵型查询 + 兜底 yanXing
///   - fixture 兼容(空 config 时 locked 兜底)
void main() {
  group('MassBattleService.statusOf 三态判定', () {
    test('cleared:stageId ∈ clearedStageIds', () {
      final config = _testConfig();
      final result = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_01',
        config: config,
        clearedStageIds: {'stage_mass_battle_01'},
      );
      expect(result, MassBattleStageStatus.cleared);
    });

    test('chain 起点 mass_battle_01 available 需 stage_06_05 cleared', () {
      final config = _testConfig();

      final available = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_01',
        config: config,
        clearedStageIds: {'stage_06_05'},
      );
      expect(available, MassBattleStageStatus.available);

      final locked = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_01',
        config: config,
        clearedStageIds: const {},
      );
      expect(locked, MassBattleStageStatus.locked);
    });

    test('chain 中间 mass_battle_02 available 需 mass_battle_01 cleared', () {
      final config = _testConfig();

      final available = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_02',
        config: config,
        clearedStageIds: {'stage_06_05', 'stage_mass_battle_01'},
      );
      expect(available, MassBattleStageStatus.available);

      final locked = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_02',
        config: config,
        clearedStageIds: {'stage_06_05'},
      );
      expect(locked, MassBattleStageStatus.locked);
    });

    test('chain 末端 mass_battle_05 available 需 mass_battle_04 cleared', () {
      final config = _testConfig();

      final fullProgress = {
        'stage_06_05',
        'stage_mass_battle_01',
        'stage_mass_battle_02',
        'stage_mass_battle_03',
        'stage_mass_battle_04',
      };

      final available = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_05',
        config: config,
        clearedStageIds: fullProgress,
      );
      expect(available, MassBattleStageStatus.available);
    });

    test('fixture 兼容:未配置 unlock trigger → locked 兜底', () {
      final emptyConfig = MassBattleDef.empty();

      final result = MassBattleService.statusOf(
        stageId: 'stage_mass_battle_01',
        config: emptyConfig,
        clearedStageIds: {'stage_06_05'},
      );
      expect(result, MassBattleStageStatus.locked);
    });
  });

  group('MassBattleService.orderedStageIds', () {
    test('返回 5 关顺序(unlock chain 拓扑序)', () {
      final config = _testConfig();
      final ordered = MassBattleService.orderedStageIds(config);

      expect(ordered, [
        'stage_mass_battle_01',
        'stage_mass_battle_02',
        'stage_mass_battle_03',
        'stage_mass_battle_04',
        'stage_mass_battle_05',
      ]);
    });

    test('empty config → 空 list', () {
      final emptyConfig = MassBattleDef.empty();
      final ordered = MassBattleService.orderedStageIds(emptyConfig);
      expect(ordered, isEmpty);
    });
  });

  group('MassBattleService.formationFor 默认阵型查询', () {
    test('config 配置 → 返回 stageFormations[stageId]', () {
      final config = _testConfig();
      // 沿 Batch 2.1 numbers.yaml stage_formations 默认决议
      expect(
        MassBattleService.formationFor(
          stageId: 'stage_mass_battle_01',
          config: config,
        ),
        Formation.yanXing,
        reason: '01 守村攻势启 yanXing',
      );
      expect(
        MassBattleService.formationFor(
          stageId: 'stage_mass_battle_02',
          config: config,
        ),
        Formation.baGua,
        reason: '02 守镇守势教 baGua',
      );
      expect(
        MassBattleService.formationFor(
          stageId: 'stage_mass_battle_03',
          config: config,
        ),
        Formation.fengShi,
        reason: '03 守县突击教 fengShi',
      );
      expect(
        MassBattleService.formationFor(
          stageId: 'stage_mass_battle_04',
          config: config,
        ),
        Formation.baGua,
        reason: '04 守关沉着守 baGua',
      );
      expect(
        MassBattleService.formationFor(
          stageId: 'stage_mass_battle_05',
          config: config,
        ),
        Formation.fengShi,
        reason: '05 守城突击破 fengShi',
      );
    });

    test('config 未配置 stageId → 兜底 yanXing(攻势启)', () {
      final emptyConfig = MassBattleDef.empty();
      expect(
        MassBattleService.formationFor(
          stageId: 'stage_mass_battle_99',
          config: emptyConfig,
        ),
        Formation.yanXing,
        reason: '未配置 fallback yanXing(Batch 2.1 numbers.yaml 默认决议)',
      );
    });
  });
}

MassBattleDef _testConfig() => const MassBattleDef(
      formations: {},
      waveIntermission: MassBattleWaveIntermission.defaults(),
      stageFormations: {
        'stage_mass_battle_01': Formation.yanXing,
        'stage_mass_battle_02': Formation.baGua,
        'stage_mass_battle_03': Formation.fengShi,
        'stage_mass_battle_04': Formation.baGua,
        'stage_mass_battle_05': Formation.fengShi,
      },
      unlockTriggers: {
        'stage_06_05': 'stage_mass_battle_01',
        'stage_mass_battle_01': 'stage_mass_battle_02',
        'stage_mass_battle_02': 'stage_mass_battle_03',
        'stage_mass_battle_03': 'stage_mass_battle_04',
        'stage_mass_battle_04': 'stage_mass_battle_05',
      },
    );
