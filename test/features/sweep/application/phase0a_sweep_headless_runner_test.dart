import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase0a_sweep_runner_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final save = await IsarSetup.instance.saveDatas.get(0);
    final firstCharacter = await IsarSetup.instance.characters
        .where()
        .findFirst();
    await IsarSetup.instance.writeTxn(() async {
      save!.founderCharacterId = firstCharacter!.id;
      await IsarSetup.instance.saveDatas.put(save);
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('真实 Ch1/Ch21、cycle 2 与代表塔层含机制 Boss 均终局，正 id 参与者只有祖师', () async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final founderId = save!.founderCharacterId!;
    final results = <Phase0aSweepRunResult>[];
    for (var index = 1; index <= 5; index++) {
      results.add(
        await Phase0aSweepHeadlessRunner(
          isar: isar,
          numbers: GameRepository.instance.numbers,
          rng: Random(20260822 + index),
        ).runMainline(
          stage: GameRepository.instance.getStage('stage_01_0$index'),
          cycleIndex: 1,
        ),
      );
    }
    // 扩面：真实 Ch1 二周目(cycle 2)与 Ch21(武圣收官章)主线均须跑至终局。
    results.add(
      await Phase0aSweepHeadlessRunner(
        isar: isar,
        numbers: GameRepository.instance.numbers,
        rng: Random(20260822),
      ).runMainline(
        stage: GameRepository.instance.getStage('stage_01_01'),
        cycleIndex: 2,
      ),
    );
    results.add(
      await Phase0aSweepHeadlessRunner(
        isar: isar,
        numbers: GameRepository.instance.numbers,
        rng: Random(20260822),
      ).runMainline(
        stage: GameRepository.instance.getStage('stage_21_01'),
        cycleIndex: 1,
      ),
    );
    for (final floorIndex in [1, 25, 30, 49]) {
      results.add(
        await Phase0aSweepHeadlessRunner(
          isar: isar,
          numbers: GameRepository.instance.numbers,
          rng: Random(20260822 + floorIndex),
        ).runTower(
          floor: GameRepository.instance.towerFloors.firstWhere(
            (floor) => floor.floorIndex == floorIndex,
          ),
          cycleIndex: 1,
        ),
      );
    }

    for (final result in results) {
      expect(result.timedOut, isFalse);
      expect(result.settlement?.isFinished, isTrue);
      expect(result.settlement!.participantCharacterIds.where((id) => id > 0), {
        founderId,
      });
    }
  });

  test('祖师已在远征时拒绝双占用，不进入战斗与结算', () async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final founderId = save!.founderCharacterId!;
    await isar.writeTxn(() async {
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yiZhanLiXing
          ..seed = 1
          ..departedAt = DateTime(2026, 8, 22)
          ..members = [ActivityMemberSnapshot()..characterId = founderId],
      );
    });
    final runner = Phase0aSweepHeadlessRunner(
      isar: isar,
      numbers: GameRepository.instance.numbers,
      rng: Random(1),
    );

    await expectLater(
      runner.runMainline(
        stage: GameRepository.instance.getStage('stage_01_01'),
        cycleIndex: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
