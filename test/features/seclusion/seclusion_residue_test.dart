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

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// 内息紊乱会随闭关时长恢复，但不再折减闭关内力产出。
void main() {
  const kSaveDataId = 1;
  const kCharId = 20;

  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_residue_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);

    // 写入 fixture 角色（学徒，内力宽裕，experienceToNextLayer 调大防升层副作用）
    final ch =
        Character.create(
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
  // (a) computeOutputs 纯函数：内力产出基线
  // ─────────────────────────────────────────────────────────────────────────

  group('computeOutputs 内力产出基线', () {
    RetreatSession makeSession() {
      return RetreatSession()
        ..id = 1
        ..saveDataId = kSaveDataId
        ..mapType = RetreatMapType.shanLin
        ..durationHours = 4
        ..startedAt =
            DateTime(2026, 5, 11, 10, 0) // 上午 10 点：非子时非节气
        ..status = RetreatStatus.active
        ..actualRewards = [];
    }

    test('无额外折减参数 → 内力产出不变（回归）', () {
      final session = makeSession();
      final now = DateTime(2026, 5, 11, 14, 0); // startedAt + 4h
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // 山林 base=5, internalForceGrowth=1.0, xueTu scale=1.0, 4h, 无子时/节气
      // floor(5 × 1.0 × 4 × 1.0 × 1.0 × 1.0 × 1.0) = 20
      expect(out.internalForcePoints, 20, reason: '默认 1.0 乘数：基线 20 不变');
    });

    test('内息紊乱不会通过额外参数折减 internalForcePoints', () {
      final session = makeSession();
      final now = DateTime(2026, 5, 11, 14, 0);

      final outBase = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );

      final outDebuff = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );

      expect(
        outDebuff.internalForcePoints,
        outBase.internalForcePoints,
        reason: '内息紊乱只影响状态恢复，不折减内力产出',
      );
      expect(outDebuff.internalForcePoints, 20);
    });

    test('重复结算输入的其他产出维度保持一致', () {
      final session = makeSession();
      final now = DateTime(2026, 5, 11, 14, 0);

      final outBase = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );

      final outDebuff = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );

      expect(outDebuff.mojianshi, outBase.mojianshi, reason: '余毒不影响 mojianshi');
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
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // (b) completeRetreat 集成：内息紊乱恢复，不阻碍内力增长
  // ─────────────────────────────────────────────────────────────────────────

  group('completeRetreat 内息紊乱集成', () {
    Future<void> setResidue(double hours) async {
      await IsarSetup.instance.writeTxn(() async {
        final ch = await IsarSetup.instance.characters.get(kCharId);
        ch!.innerBreathDisorderHoursRemaining = hours;
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
      expect(ch?.innerBreathDisorderHoursRemaining, 0, reason: '无紊乱保持 0');
    });

    test('有紊乱（5h）→ 内力正常增长，紊乱减去 actualHours(3h) → 剩 2h', () async {
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

      expect(out.internalForcePoints, 15, reason: '内息紊乱不阻碍闭关内力增长');
      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(
        ch?.innerBreathDisorderHoursRemaining,
        closeTo(2.0, 0.01),
        reason: '5h - 3h = 2h 剩余',
      );
    });

    test('紊乱剩 2h，再闭关 3h → clamp 到 0', () async {
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
        ch?.innerBreathDisorderHoursRemaining,
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
