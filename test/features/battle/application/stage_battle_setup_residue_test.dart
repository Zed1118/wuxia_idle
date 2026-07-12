import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import "../../../support/isar_test_support.dart";
import '../../../support/test_data.dart';

/// 内息紊乱降低有效内力和开场真气，不再使用通用输出乘数。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_battle_residue_test_',
    );
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

  test('内息紊乱在身 → 有效内力与开场真气下降', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final isar = IsarSetup.instance;

    int actualInnerForce = 0;
    await isar.writeTxn(() async {
      final ch = await isar.characters.get(1);
      actualInnerForce = ch!.internalForce;
      ch.innerBreathDisorderHoursRemaining =
          GameRepository.instance.numbers.innerBreathDisorder.maxHours;
      await isar.characters.put(ch);
    });

    final stage = GameRepository.instance.getStage('stage_01_01');
    final (left, _) = await StageBattleSetup(isar: isar).buildTeams(stage);

    expect(left.first.outputMultiplier, 1.0);
    expect(left.first.internalForce, lessThan(actualInnerForce));
    expect(left.first.currentQi, 20);
  });

  test(
    'M6 Task6：无余毒角色(residueHoursRemaining == 0) → outputMultiplier = 1.0',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      // P3 种子默认 innerDemonResidueHoursRemaining = 0，无需额外写入

      final stage = GameRepository.instance.getStage('stage_01_01');
      final (left, _) = await StageBattleSetup(
        isar: IsarSetup.instance,
      ).buildTeams(stage);

      expect(
        left.first.outputMultiplier,
        closeTo(1.0, 1e-9),
        reason: '无余毒角色 outputMultiplier 应为 1.0',
      );
    },
  );
}
