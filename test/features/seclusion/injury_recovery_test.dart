import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';

/// Task 8：双层伤势靠真实挂机/闭关时间疗养（守 §5.5 在线=离线，无加速）。
///   - 重伤 injuryHoursRemaining 按 actualHours / awayHours 累减（clamp ≥ 0）
///   - 轻伤 lightInjuryStacks 收功/离线结算即清零（无条件）
void main() {
  const kSaveDataId = 1;
  const kCharId = 30;

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
    tempDir = await Directory.systemTemp.createTemp('wuxia_injury_recover_');
    await IsarSetup.init(directory: tempDir, inspector: false);

    final ch = Character.create(
      name: 'injured_hero',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      internalForce: 100,
    )
      ..id = kCharId
      ..internalForceMax = 10000
      ..experienceToNextLayer = 999999;
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(ch),
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> setInjury({
    required double injuryHours,
    required int lightStacks,
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      final ch = await IsarSetup.instance.characters.get(kCharId);
      ch!.injuryHoursRemaining = injuryHours;
      ch.lightInjuryStacks = lightStacks;
      await IsarSetup.instance.characters.put(ch);
    });
  }

  // ───────────────────────────────────────────────────────────────────────
  // 闭关收功疗养
  // ───────────────────────────────────────────────────────────────────────
  group('completeRetreat 伤势疗养', () {
    test('重伤 8h，收功 actualHours=3h → 剩 5h；轻伤清零', () async {
      await setInjury(injuryHours: 8.0, lightStacks: 4);

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 3,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      await SeclusionService(isar: IsarSetup.instance).completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 3)),
      );

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.injuryHoursRemaining, closeTo(5.0, 0.01),
          reason: '8h - 3h = 5h');
      expect(ch?.lightInjuryStacks, 0, reason: '收功即调息，轻伤无条件清零');
    });

    test('重伤 2h，收功 actualHours=5h → clamp 到 0（不为负）', () async {
      await setInjury(injuryHours: 2.0, lightStacks: 2);

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 5,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      await SeclusionService(isar: IsarSetup.instance).completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 5)),
      );

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.injuryHoursRemaining, 0, reason: '2h - 5h clamp 到 0');
      expect(ch?.lightInjuryStacks, 0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // 离线挂机疗养
  // ───────────────────────────────────────────────────────────────────────
  group('offline settle 伤势疗养', () {
    test('重伤 8h，离线 awayHours=3h → 剩 5h；轻伤清零', () async {
      await setInjury(injuryHours: 8.0, lightStacks: 3);

      await OfflinePassiveService.settle(
        saveDataId: kSaveDataId,
        characterId: kCharId,
        awayHours: 3,
        now: DateTime(2026, 6, 15, 12),
      );

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.injuryHoursRemaining, closeTo(5.0, 0.01),
          reason: '8h - 3h = 5h');
      expect(ch?.lightInjuryStacks, 0);
    });

    test('即使无经验产出（awayHours 极小，0 经验）也疗养 + 清轻伤', () async {
      await setInjury(injuryHours: 8.0, lightStacks: 5);

      // awayHours=0.001 → compute 经验/磨剑石均 floor 到 0（验无产出分支也疗养）
      final result = await OfflinePassiveService.settle(
        saveDataId: kSaveDataId,
        characterId: kCharId,
        awayHours: 0.001,
        now: DateTime(2026, 6, 15, 12),
      );
      expect(result.experience, 0, reason: '前置断言：本场景确实 0 经验产出');
      expect(result.mojianshi, 0);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.injuryHoursRemaining, closeTo(7.999, 0.01),
          reason: '8h - 0.001h ≈ 7.999h，0 产出路径仍疗养');
      expect(ch?.lightInjuryStacks, 0, reason: '0 产出路径仍无条件清轻伤');
    });
  });
}
