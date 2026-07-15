import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/character_occupancy_service.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_occupancy_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('无任何活动时占用为空', () async {
    final occ = await CharacterOccupancyService(IsarSetup.instance).snapshot();
    expect(occ.occupiedCharacterIds, isEmpty);
    expect(occ.reservedEquipmentIds, isEmpty);
    expect(occ.activityOf(1), isNull);
  });

  test('远征成员进占用与保留集，装备id 进 reservedEquipmentIds', () async {
    await IsarSetup.instance.writeTxn(() async {
      final run = ExpeditionRun()
        ..saveDataId = 1
        ..policy = ExpeditionPolicy.yanJingCaiYao
        ..seed = 1
        ..departedAt = DateTime(2026, 7, 15)
        ..members = [
          ActivityMemberSnapshot()
            ..characterId = 42
            ..reservedEquipmentIds = [100, 101]
            ..reservedTechniqueIds = [5],
        ];
      await IsarSetup.instance.expeditionRuns.put(run);
    });

    final occ = await CharacterOccupancyService(IsarSetup.instance).snapshot();
    expect(occ.occupiedCharacterIds, {42});
    expect(occ.reservedEquipmentIds, {100, 101});
    expect(occ.reservedTechniqueIds, {5});
    expect(occ.activityOf(42), ActivityKind.expedition);
  });

  test('闭关角色沿 currentRetreatSessionId 进占用（仅锁角色）', () async {
    await IsarSetup.instance.writeTxn(() async {
      final c = Character()
        ..name = '徒一'
        ..realmTier = RealmTier.xueTu
        ..realmLayer = RealmLayer.qiMeng
        ..attributes = Attributes()
        ..rarity = RarityTier.biaoZhun
        ..lineageRole = LineageRole.disciple
        ..createdAt = DateTime(2026, 7, 15)
        ..currentRetreatSessionId = 7;
      await IsarSetup.instance.characters.put(c);
    });
    final occ = await CharacterOccupancyService(IsarSetup.instance).snapshot();
    expect(occ.occupiedCharacterIds.length, 1);
    expect(occ.activityOf(occ.occupiedCharacterIds.first), ActivityKind.retreat);
    // 闭关只锁角色，不保留装备
    expect(occ.reservedEquipmentIds, isEmpty);
  });
}
