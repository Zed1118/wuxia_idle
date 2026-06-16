import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

/// M6 Task 6：余毒在身玩家角色战斗快照 outputMultiplier = 0.95。
///
/// 红线 §5.6：数值从 numbers.innerDemon.residueDebuff.battleOutputMultiplier 读，不写死。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_battle_residue_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'M6 Task6：余毒在身角色(residueHoursRemaining > 0) → outputMultiplier = 0.95',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final isar = IsarSetup.instance;

      // 给角色打上余毒标记
      await isar.writeTxn(() async {
        final ch = await isar.characters.get(1);
        ch!.innerDemonResidueHoursRemaining = 4.0; // 剩余 4 小时余毒
        await isar.characters.put(ch);
      });

      final stage = GameRepository.instance.getStage('stage_01_01');
      final (left, _) = await StageBattleSetup(isar: isar).buildTeams(stage);

      final expected =
          GameRepository.instance.numbers.innerDemon.residueDebuff.battleOutputMultiplier;
      expect(
        left.first.outputMultiplier,
        closeTo(expected, 1e-9),
        reason:
            '余毒在身玩家角色 outputMultiplier 应等于 '
            'numbers.innerDemon.residueDebuff.battleOutputMultiplier (=$expected)',
      );
    },
  );

  test(
    'M6 Task6：无余毒角色(residueHoursRemaining == 0) → outputMultiplier = 1.0',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      // P3 种子默认 innerDemonResidueHoursRemaining = 0，无需额外写入

      final stage = GameRepository.instance.getStage('stage_01_01');
      final (left, _) =
          await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);

      expect(
        left.first.outputMultiplier,
        closeTo(1.0, 1e-9),
        reason: '无余毒角色 outputMultiplier 应为 1.0',
      );
    },
  );
}
