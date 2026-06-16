import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

/// M6 Task 7：余毒在身时闭关内力产出 ×0.80，累计满 8h 清余毒。
void main() {
  const kSaveDataId = 1;
  const kCharId = 20;

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
    tempDir = await Directory.systemTemp.createTemp('wuxia_residue_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);

    // 写入 fixture 角色（学徒，内力宽裕，experienceToNextLayer 调大防升层副作用）
    final ch = Character.create(
      name: 'residue_hero',
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

  // ─────────────────────────────────────────────────────────────────────────
  // (a) computeOutputs 纯函数：residueInternalForceMultiplier 参数
  // ─────────────────────────────────────────────────────────────────────────

  group('computeOutputs residueInternalForceMultiplier', () {
    RetreatSession makeSession() {
      return RetreatSession()
        ..id = 1
        ..saveDataId = kSaveDataId
        ..mapType = RetreatMapType.shanLin
        ..durationHours = 4
        ..startedAt = DateTime(2026, 5, 11, 10, 0) // 上午 10 点：非子时非节气
        ..status = RetreatStatus.active
        ..actualRewards = [];
    }

    test('默认 residueInternalForceMultiplier=1.0 → 内力产出不变（回归）', () {
      final session = makeSession();
      final now = DateTime(2026, 5, 11, 14, 0); // startedAt + 4h
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
        // 不传 residueInternalForceMultiplier → 默认 1.0
      );
      // 山林 base=5, internalForceGrowth=1.0, xueTu scale=1.0, 4h, 无子时/节气
      // floor(5 × 1.0 × 4 × 1.0 × 1.0 × 1.0 × 1.0) = 20
      expect(out.internalForcePoints, 20, reason: '默认 1.0 乘数：基线 20 不变');
    });

    test(
      'residueInternalForceMultiplier=0.80 → internalForcePoints = floor(基线 × 0.80)',
      () {
        final session = makeSession();
        final now = DateTime(2026, 5, 11, 14, 0);

        final outBase = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
          residueInternalForceMultiplier: 1.0,
        );

        final outDebuff = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
          residueInternalForceMultiplier: 0.80,
        );

        expect(
          outDebuff.internalForcePoints,
          (outBase.internalForcePoints * 0.80).floor(),
          reason: '余毒 ×0.80 → floor(20 × 0.80) = 16',
        );
        expect(outDebuff.internalForcePoints, 16);
      },
    );

    test(
      'residueInternalForceMultiplier=0.80 不影响 mojianshi / experiencePoints / techniqueLearnPoints',
      () {
        final session = makeSession();
        final now = DateTime(2026, 5, 11, 14, 0);

        final outBase = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
          residueInternalForceMultiplier: 1.0,
        );

        final outDebuff = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
          residueInternalForceMultiplier: 0.80,
        );

        expect(
          outDebuff.mojianshi,
          outBase.mojianshi,
          reason: '余毒不影响 mojianshi',
        );
        expect(
          outDebuff.experiencePoints,
          outBase.experiencePoints,
          reason: '余毒不影响 experiencePoints',
        );
        expect(
          outDebuff.techniqueLearnPoints,
          outBase.techniqueLearnPoints,
          reason: '余毒不影响 techniqueLearnPoints',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // (b) completeRetreat 集成：余毒累减 + 内力 debuff
  // ─────────────────────────────────────────────────────────────────────────

  group('completeRetreat 余毒集成', () {
    Future<void> setResidue(double hours) async {
      await IsarSetup.instance.writeTxn(() async {
        final ch = await IsarSetup.instance.characters.get(kCharId);
        ch!.innerDemonResidueHoursRemaining = hours;
        await IsarSetup.instance.characters.put(ch);
      });
    }

    test('无余毒（=0）→ internalForce 产出为满额（不受 debuff）', () async {
      // 默认 fixture 角色余毒=0

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      // 无余毒 → 满额 20 点
      expect(out.internalForcePoints, 20, reason: '无余毒不受 0.80 debuff');
      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(
        ch?.innerDemonResidueHoursRemaining,
        0,
        reason: '无余毒不累减',
      );
    });

    test('有余毒（5h）→ 内力 ×0.80，余毒减去 actualHours(3h) → 剩 2h', () async {
      await setResidue(5.0);

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
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 3)),
          );

      // 山林 3h，×0.80：floor(5 × 1.0 × 3 × 1.0 × 1.0 × 1.0 × 1.0 × 0.80) = floor(12.0) = 12
      expect(
        out.internalForcePoints,
        12,
        reason: '余毒在身 ×0.80：3h 基础 15 × 0.80 = 12',
      );
      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(
        ch?.innerDemonResidueHoursRemaining,
        closeTo(2.0, 0.01),
        reason: '5h - 3h = 2h 剩余',
      );
    });

    test('余毒剩 2h，再闭关 3h → 余毒 clamp 到 0（满 8h 累计清）', () async {
      await setResidue(2.0);

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
      expect(
        ch?.innerDemonResidueHoursRemaining,
        0,
        reason: '2h - 3h = -1h → clamp 到 0（余毒清除）',
      );
    });

    test('余毒清除后 internalForce 产出恢复满额（下次闭关不再受 debuff）', () async {
      // 先设余毒=0（已由 completeRetreat 清除，这里直接 seed 为 0 验回复路径）
      // 此测 side-by-side：余毒=0 产出应等于基线
      await setResidue(0.0);

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      expect(out.internalForcePoints, 20, reason: '余毒清除后恢复满额 20');
    });
  });
}
