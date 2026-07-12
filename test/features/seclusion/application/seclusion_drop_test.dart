import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

const kSaveDataId = 1;
const kCharId = 10;

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_seclusion_drop_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final ch = Character.create(
      name: 'test_hero',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      internalForce: 500,
    )..id = kCharId;
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(ch),
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('红线：5 图 dropTable 装备 tier == 压一阶目标 tier（守 §5.3 锁步）', () {
    const expected = <RetreatMapType, EquipmentTier>{
      RetreatMapType.shanLin: EquipmentTier.xunChang, // xueTu 边界压不动
      RetreatMapType.guJianZhong: EquipmentTier.xunChang, // sanLiu→压
      RetreatMapType.cangJingGe: EquipmentTier.xunChang,
      RetreatMapType.xuanYaPuBu: EquipmentTier.xiangYang, // erLiu→压
      RetreatMapType.duanYaJueBi: EquipmentTier.zhongQi, // zongShi→压
    };
    for (final m in GameRepository.instance.seclusionMaps) {
      expect(m.dropTable, isNotEmpty, reason: '${m.mapType} 应有 dropTable');
      for (final entry in m.dropTable.whereType<EquipmentDrop>()) {
        final def = GameRepository.instance.getEquipment(entry.equipmentDefId);
        expect(
          def.tier,
          expected[m.mapType],
          reason: '${m.mapType} 的 ${entry.equipmentDefId} tier 越界',
        );
      }
    }
  });

  RetreatSession shanLinSession(int id) => RetreatSession()
    ..id = id
    ..saveDataId = kSaveDataId
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 0
    ..realmTierAtStart = RealmTier.xueTu
    ..startedAt = DateTime(2026, 5, 11, 10, 0)
    ..status = RetreatStatus.active
    ..actualRewards = [];

  test('computeOutputs：同一 session 的 6 个节点结果可稳定复现', () {
    final now = DateTime(2026, 5, 14, 10, 0); // start + 72h
    final dropSvc = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.dropSourceSeclusion,
      now: () => now,
    );
    RetreatOutputs calculate(int id) => SeclusionService.computeOutputs(
      session: shanLinSession(id),
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
      dropService: dropSvc,
    );
    final hitId = List.generate(
      1000,
      (index) => index + 1,
    ).firstWhere((id) => calculate(id).equipmentDrops.isNotEmpty);
    final first = calculate(hitId);
    final second = calculate(hitId);

    expect(
      second.equipmentDrops.map((equipment) => equipment.defId),
      first.equipmentDrops.map((equipment) => equipment.defId),
    );
    expect(first.equipmentDrops.length, lessThanOrEqualTo(6));
    expect(
      first.equipmentDrops.every(
        (equipment) => equipment.obtainedFrom == UiStrings.dropSourceSeclusion,
      ),
      isTrue,
    );

    final allMissId = List.generate(
      1000,
      (index) => index + 1,
    ).firstWhere((id) => calculate(id).equipmentDrops.isEmpty);
    expect(
      calculate(allMissId).equipmentDrops,
      isEmpty,
      reason: '六次判定仍可全部落空，不设保底',
    );
  });

  test('computeOutputs：不传 dropService → equipDrops 恒空(零回归)', () {
    final now = DateTime(2026, 5, 14, 10, 0);
    final out = SeclusionService.computeOutputs(
      session: shanLinSession(51),
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
    );
    expect(out.equipmentDrops, isEmpty);
  });

  test('completeRetreat：收功后掉落装备真入 isar.equipments + obtainedFrom 闭关', () async {
    final start = DateTime(2026, 5, 11, 10, 0);
    final completeAt = start.add(const Duration(hours: 72));
    final dropSvc = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.dropSourceSeclusion,
      now: () => completeAt,
    );
    final hitId = List.generate(1000, (index) => index + 1).firstWhere((id) {
      final candidate = shanLinSession(id);
      return SeclusionService.computeOutputs(
        session: candidate,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: completeAt,
        dropService: dropSvc,
      ).equipmentDrops.isNotEmpty;
    });
    final session = RetreatSession()
      ..id = hitId
      ..saveDataId = kSaveDataId
      ..mapType = RetreatMapType.shanLin
      ..durationHours = 0
      ..realmTierAtStart = RealmTier.xueTu
      ..startedAt = start
      ..status = RetreatStatus.active
      ..actualRewards = [];
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.retreatSessions.put(session),
    );

    await SeclusionService(isar: IsarSetup.instance).completeRetreat(
      session: session,
      characterId: kCharId,
      charRealmTier: RealmTier.xueTu,
      config: GameRepository.instance.numbers.retreat,
      maps: GameRepository.instance.seclusionMaps,
      now: completeAt,
    );

    final eqs = await IsarSetup.instance.equipments.where().findAll();
    expect(eqs, isNotEmpty);
    expect(eqs.length, lessThanOrEqualTo(6));
    expect(eqs.first.obtainedFrom, UiStrings.dropSourceSeclusion);
  });
}
