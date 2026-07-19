import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_info_provider.dart';
import 'package:wuxia_idle/features/recruitment/application/recruitment_providers.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `lineageInfoProvider` 派生行为测（2026-07-19 夜批 coverage 补强，
/// 基线 0/24 行）。
///
/// 真 Isar + 真上游 provider 链（activeCharacterIds → characterById →
/// recruitedDiscipleIds → allEquipments），钉 P1.1 A1 E.1 视图语义：
///   - 空存档:founder null + 三段全空(UI 兜底空态)
///   - 祖师/出阵弟子/inactive 收徒弟子/师承遗物 四段分组与顺序
///   - 收徒 id 已在 active → 差集排除(不进 inactive 段)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lineage_info_');
    await IsarSetup.init(directory: tempDir, inspector: false);
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
    required int id,
    required String name,
    bool isFounder = false,
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
    )..id = id;
  }

  Equipment makeEquipment({required String defId, bool heritage = false}) {
    final e = Equipment.create(
      defId: defId,
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 7, 19),
      obtainedFrom: 'test',
    );
    if (heritage) e.inheritFrom(7, GameRepository.instance.numbers);
    return e;
  }

  Future<LineageInfo> readLineage(ProviderContainer container) async {
    // 上游均走 IsarSetup.instance,init 后 invalidate 触发重算。
    container
      ..invalidate(activeCharacterIdsProvider)
      ..invalidate(recruitedDiscipleIdsProvider)
      ..invalidate(allEquipmentsProvider);
    // 持订阅保活:autoDispose 下 lineageInfo 多段 await ref.watch,无监听
    // 时 build 中途被 dispose,后续 ref.watch 抛 Ref-after-dispose。
    final sub = container.listen(lineageInfoProvider.future, (_, _) {});
    addTearDown(sub.close);
    return container.read(lineageInfoProvider.future);
  }

  test('空存档:founder null + 三段全空', () async {
    final container = makeContainer();

    final info = await readLineage(container);

    expect(info.founder, isNull, reason: '无 founder 的异常存档 UI 兜底空态');
    expect(info.disciples, isEmpty);
    expect(info.inactiveDisciples, isEmpty);
    expect(info.heritageEquipments, isEmpty);
  });

  test('祖师/出阵弟子/inactive 弟子/遗物四段分组与顺序', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        makeChar(id: 1, name: '开派祖师', isFounder: true, isActive: true),
        makeChar(id: 2, name: '大弟子', isActive: true),
        makeChar(id: 3, name: '二弟子', isActive: true),
        makeChar(id: 4, name: '在册弟子'),
      ]);
      await isar.equipments.putAll([
        makeEquipment(defId: 'eq_heritage', heritage: true),
        makeEquipment(defId: 'eq_normal'),
      ]);
      final save = (await isar.saveDatas.get(0))!
        ..founderCharacterId = 1
        ..activeCharacterIds = [1, 2, 3]
        ..recruitedDiscipleIds = [4];
      await isar.saveDatas.put(save);
    });
    final container = makeContainer();

    final info = await readLineage(container);

    expect(info.founder?.id, 1);
    expect(
      info.disciples.map((c) => c.id).toList(),
      [2, 3],
      reason: '出阵弟子按 activeCharacterIds 原序(大弟子/二弟子)',
    );
    expect(
      info.inactiveDisciples.map((c) => c.id).toList(),
      [4],
      reason: 'recruited ∖ active = 在册未出阵',
    );
    expect(
      info.heritageEquipments.map((e) => e.defId).toList(),
      ['eq_heritage'],
      reason: '只收 isLineageHeritage,普通装备不进遗物段',
    );
  });

  test('收徒 id 已在 active → 差集排除不进 inactive 段', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        makeChar(id: 1, name: '开派祖师', isFounder: true, isActive: true),
        makeChar(id: 2, name: '大弟子', isActive: true),
      ]);
      final save = (await isar.saveDatas.get(0))!
        ..founderCharacterId = 1
        ..activeCharacterIds = [1, 2]
        ..recruitedDiscipleIds = [2]; // 收徒后又被提上阵
      await isar.saveDatas.put(save);
    });
    final container = makeContainer();

    final info = await readLineage(container);

    expect(info.inactiveDisciples, isEmpty, reason: '已出阵弟子不重复进 inactive');
    expect(info.disciples.map((c) => c.id).toList(), [2]);
  });
}
