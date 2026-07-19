import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/ascension/application/ascend_service_providers.dart';
import 'package:wuxia_idle/features/ascension/domain/ascension_models.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `ascend_service_providers` 行为测（2026-07-19 夜批 coverage 补强，
/// 基线 4/13 行）。
///
/// 真 Isar + 真 GameRepository + ProviderContainer 真读（生产入口 =
/// LineagePanel 飞升按钮 / AscensionScreen 下拉与选件 UI），钉：
///   - service nullable propagation(Isar 未 init → null)
///   - eligibility:无 founder → blocked;seed founder → 真聚合返回
///   - heritageCandidates:founder 不存在 → 空;有装备 → 全量返回
///   - discipleTargets:active 内弟子入选,founder 排除
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_ascend_prov_');
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Character makeChar({
    required String name,
    required bool isFounder,
    bool isActive = false,
  }) {
    final realm = GameRepository.instance.getRealm(
      RealmTier.xueTu,
      RealmLayer.qiMeng,
    );
    return Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
      createdAt: DateTime(2026, 7, 19),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: isFounder,
      isActive: isActive,
    );
  }

  test('service:Isar 未 init → null;init → 非 null', () async {
    final container = makeContainer();
    expect(container.read(ascendServiceProvider), isNull);

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(container.read(ascendServiceProvider), isNotNull);
  });

  test('eligibility:无 founder → blocked;seed founder → 真聚合', () async {
    final container = makeContainer();
    expect(
      await container.read(ascensionEligibilityProvider.future),
      AscensionEligibility.blocked,
      reason: 'service null → blocked 兜底',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(
      await container.read(ascensionEligibilityProvider.future),
      AscensionEligibility.blocked,
      reason: 'SaveData 无 founderId → blocked',
    );

    late int founderId;
    await IsarSetup.instance.writeTxn(() async {
      founderId = await IsarSetup.instance.characters.put(
        makeChar(name: '祖师', isFounder: true, isActive: true),
      );
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..founderCharacterId = founderId
        ..activeCharacterIds = [founderId];
      await IsarSetup.instance.saveDatas.put(save);
    });
    container.invalidate(ascensionEligibilityProvider);
    final eligibility = await container.read(
      ascensionEligibilityProvider.future,
    );
    expect(eligibility.inActiveCharacters, isTrue, reason: 'founder 在阵');
    expect(eligibility.realmAtPeak, isFalse, reason: 'xueTu 未达化境');
    expect(eligibility.hasDiscipleTarget, isFalse, reason: '尚无弟子');
  });

  test('heritageCandidates:founder 不存在 → 空;有装备 → 全量返回', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final container = makeContainer();
    expect(
      await container.read(heritageCandidatesProvider(1).future),
      isEmpty,
      reason: 'service null → 空 list',
    );

    container.invalidate(isarProvider);
    expect(
      await container.read(heritageCandidatesProvider(999).future),
      isEmpty,
      reason: 'founder 不存在 → 空 list',
    );

    late int founderId;
    await IsarSetup.instance.writeTxn(() async {
      founderId = await IsarSetup.instance.characters.put(
        makeChar(name: '祖师', isFounder: true),
      );
      await IsarSetup.instance.equipments.put(
        Equipment.create(
          defId: 'eq_test_heritage',
          tier: EquipmentTier.liQi,
          slot: EquipmentSlot.weapon,
          obtainedAt: DateTime(2026, 7, 19),
          obtainedFrom: 'test',
          ownerCharacterId: founderId,
        ),
      );
    });
    container.invalidate(heritageCandidatesProvider(founderId));
    final candidates = await container.read(
      heritageCandidatesProvider(founderId).future,
    );
    expect(candidates, hasLength(1));
    expect(candidates.single.ownerCharacterId, founderId);
  });

  test('discipleTargets:active 弟子入选,founder/非 active 排除', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final container = makeContainer();
    expect(
      await container.read(ascensionDiscipleTargetsProvider.future),
      isEmpty,
      reason: 'service null → 空 list',
    );

    container.invalidate(isarProvider);
    late int founderId, discipleId, reserveId;
    await IsarSetup.instance.writeTxn(() async {
      founderId = await IsarSetup.instance.characters.put(
        makeChar(name: '祖师', isFounder: true, isActive: true),
      );
      discipleId = await IsarSetup.instance.characters.put(
        makeChar(name: '大弟子', isFounder: false, isActive: true),
      );
      reserveId = await IsarSetup.instance.characters.put(
        makeChar(name: '替补弟子', isFounder: false),
      );
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..founderCharacterId = founderId
        ..activeCharacterIds = [founderId, discipleId];
      await IsarSetup.instance.saveDatas.put(save);
    });
    container.invalidate(ascensionDiscipleTargetsProvider);
    final targets = await container.read(
      ascensionDiscipleTargetsProvider.future,
    );
    expect(
      targets.map((c) => c.id).toList(),
      [discipleId],
      reason: 'founder 与未上阵替补($reserveId)都排除,active 序保留',
    );
  });
}
