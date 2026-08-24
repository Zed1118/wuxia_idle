import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/sect/application/sect_itinerary_provider.dart';

import '../../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sect_itinerary_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Character character(int id, String name, {int? retreatSessionId}) =>
      Character()
        ..id = id
        ..name = name
        ..realmTier = RealmTier.xueTu
        ..realmLayer = RealmLayer.qiMeng
        ..attributes = Attributes()
        ..rarity = RarityTier.biaoZhun
        ..lineageRole = id == 1 ? LineageRole.founder : LineageRole.disciple
        ..createdAt = DateTime(2026, 8, 25)
        ..currentRetreatSessionId = retreatSessionId;

  SaveData save({int? leaderId = 1}) => SaveData()
    ..saveVersion = '0.54'
    ..createdAt = DateTime(2026, 8, 25)
    ..lastSavedAt = DateTime(2026, 8, 25)
    ..lastOnlineAt = DateTime(2026, 8, 25)
    ..founderCharacterId = leaderId;

  test('聚合真实掌门、三类占用与 active 进度', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        character(1, '沈掌门'),
        character(2, '叶问舟', retreatSessionId: 17),
        character(3, '程青崖'),
        character(4, '顾长风'),
      ]);
      await isar.saveDatas.put(save());
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yanJingCaiYao
          ..seed = 7
          ..departedAt = DateTime(2026, 8, 25)
          ..currentNode = 6
          ..members = [ActivityMemberSnapshot()..characterId = 3],
      );
      await isar.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 9
          ..currentStage = 2
          ..sessionPhase = GauntletPhase.interlude
          ..members = [ActivityMemberSnapshot()..characterId = 4],
      );
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final summary = await container.read(sectItineraryProvider.future);

    expect(summary.leaderId, 1);
    expect(summary.leaderName, '沈掌门');
    expect(summary.occupiedMembers.map((member) => member.characterId), [
      2,
      3,
      4,
    ]);
    expect(summary.occupiedMembers.map((member) => member.activity), [
      ActivityKind.retreat,
      ActivityKind.expedition,
      ActivityKind.bossGauntlet,
    ]);
    expect(summary.expeditionDepth, 6);
    expect(summary.expeditionDefeated, isFalse);
    expect(summary.gauntletStage, 2);
    expect(summary.gauntletPhase, GauntletPhase.interlude);
  });

  test('掌门指针缺失时 fail closed，不回退角色 1', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(character(1, '旧祖师'));
      await isar.saveDatas.put(save(leaderId: null));
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(sectItineraryProvider.future),
      throwsA(isA<StateError>()),
    );
  });

  test('掌门指针悬空时 fail closed', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.saveDatas.put(save(leaderId: 99));
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(sectItineraryProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}
