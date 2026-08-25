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
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/lineup/application/disciple_scheduling_provider.dart';

import '../../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('disciple_scheduling_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Character character({
    required int id,
    required String name,
    required LineageRole role,
    bool founder = false,
    bool alive = true,
    bool active = false,
    int? masterId,
    int? retreatSessionId,
  }) => Character.create(
    name: name,
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: role,
    createdAt: DateTime(2026, 8, 25),
    isFounder: founder,
    isAlive: alive,
    isActive: active,
    masterId: masterId,
    currentRetreatSessionId: retreatSessionId,
  )..id = id;

  SaveData save({int? leaderId = 10, List<int> activeIds = const [10, 12]}) =>
      SaveData()
        ..saveVersion = '0.40.0'
        ..createdAt = DateTime(2026, 8, 25)
        ..lastSavedAt = DateTime(2026, 8, 25)
        ..lastOnlineAt = DateTime(2026, 8, 25)
        ..founderCharacterId = leaderId
        ..activeCharacterIds = activeIds
        ..recruitedDiscipleIds = [11, 12];

  test('只读聚合当代掌门、全体门人与三类真实活动状态', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        character(
          id: 1,
          name: '退隐太祖',
          role: LineageRole.founder,
          founder: true,
        ),
        character(
          id: 2,
          name: '旧代门人',
          role: LineageRole.disciple,
          masterId: 1,
          active: true,
        ),
        character(
          id: 10,
          name: '沈掌门',
          role: LineageRole.founder,
          founder: true,
          active: true,
        ),
        character(
          id: 11,
          name: '叶问舟',
          role: LineageRole.disciple,
          masterId: 10,
          retreatSessionId: 17,
        ),
        character(
          id: 12,
          name: '程青崖',
          role: LineageRole.disciple,
          active: true,
        ),
      ]);
      await isar.saveDatas.put(save(activeIds: const [10, 12, 2]));
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yanJingCaiYao
          ..seed = 7
          ..departedAt = DateTime(2026, 8, 25)
          ..currentNode = 6
          ..members = [ActivityMemberSnapshot()..characterId = 12],
      );
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final summary = await container.read(discipleSchedulingProvider.future);

    expect(summary.leaderId, 10);
    expect(summary.members.map((member) => member.characterId), [10, 11, 12]);
    expect(summary.members.map((member) => member.name), [
      '沈掌门',
      '叶问舟',
      '程青崖',
    ]);
    expect(summary.members[0].isLeader, isTrue);
    expect(summary.members[0].activity, isNull);
    expect(summary.members[1].activity, ActivityKind.retreat);
    expect(summary.members[2].activity, ActivityKind.expedition);

    final persisted = await isar.saveDatas.get(0);
    expect(persisted!.activeCharacterIds, [10, 12, 2]);
    expect((await isar.characters.get(11))!.isActive, isFalse);
  });

  test('同一角色被两类活动重复占用时 fail closed', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        character(
          id: 10,
          name: '沈掌门',
          role: LineageRole.founder,
          founder: true,
        ),
        character(
          id: 11,
          name: '叶问舟',
          role: LineageRole.disciple,
          masterId: 10,
          retreatSessionId: 17,
        ),
      ]);
      await isar.saveDatas.put(save(activeIds: const [10, 11]));
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yanJingCaiYao
          ..seed = 7
          ..departedAt = DateTime(2026, 8, 25)
          ..members = [ActivityMemberSnapshot()..characterId = 11],
      );
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await expectLater(
      container.read(discipleSchedulingProvider.future),
      throwsA(isA<StateError>()),
    );
  });

  test('悬空掌门或当代成员引用时 fail closed', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(
        character(
          id: 10,
          name: '沈掌门',
          role: LineageRole.founder,
          founder: true,
        ),
      );
      await isar.saveDatas.put(save(activeIds: const [10, 99]));
    });

    var container = ProviderContainer();
    await expectLater(
      container.read(discipleSchedulingProvider.future),
      throwsA(isA<StateError>()),
    );
    container.dispose();

    await isar.writeTxn(() async {
      await isar.saveDatas.put(save(leaderId: 77, activeIds: const [77]));
    });
    container = ProviderContainer();
    addTearDown(container.dispose);
    await expectLater(
      container.read(discipleSchedulingProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}
