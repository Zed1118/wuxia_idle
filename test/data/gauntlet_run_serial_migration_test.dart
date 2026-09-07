import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';

import '../fixtures/legacy_gauntlet_save_data.dart';
import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_serial_');
  });
  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  for (final seed in [0, 3, 8202]) {
    test('真实缺少序号字段的 0.46 旧档升级并重开，持久化 seed=$seed 不重算', () async {
      expect(
        LegacyGauntletSaveDataSchema.properties,
        isNot(contains('gauntletRunSerial')),
      );
      expect(
        LegacyBossGauntletRunSchema.properties,
        isNot(contains('cycleSeedEnabled')),
      );
      final legacy = await Isar.open(
        [LegacyGauntletSaveDataSchema, LegacyBossGauntletRunSchema],
        directory: tempDir.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      final savedAt = DateTime.utc(2026, 9, 6);
      late int runId;
      try {
        await legacy.writeTxn(() async {
          await legacy.collection<LegacyGauntletSaveData>().put(
            LegacyGauntletSaveData()
              ..createdAt = savedAt
              ..lastSavedAt = savedAt
              ..lastOnlineAt = savedAt,
          );
          runId = await legacy.collection<LegacyBossGauntletRun>().put(
            LegacyBossGauntletRun()..seed = seed,
          );
        });
      } finally {
        await legacy.close();
      }

      for (var reopen = 0; reopen < 2; reopen++) {
        await IsarSetup.init(directory: tempDir, inspector: false);
        final save = (await IsarSetup.currentSaveData())!;
        expect(save.saveVersion, '0.48.0');
        expect(save.gauntletRunSerial, 0);
        expect(save.expeditionRunSerial, 17);
        expect(save.lastOnlineAt, savedAt.toLocal());
        final service = GauntletService(IsarSetup.instance);
        expect(
          await service.recover(
            config: GameRepository.instance.bossGauntletConfig,
          ),
          GauntletRecoveryOutcome.resumed,
        );
        final run = (await service.activeRun())!;
        expect(run.id, runId);
        expect(run.seed, seed);
        expect(run.cycleSeedEnabled, isFalse);
        expect(run.cycleIndex, 2);
        expect(run.currentStage, 2);
        await IsarSetup.close();
      }
    });
  }
}
