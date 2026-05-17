import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/event/application/game_event_service.dart';

/// P1 #42 Phase 2 · GameEventService 7 type 写入红线契约。
///
/// 验证语义(memory feedback_red_line_test_semantics):
/// - eventType 正确路由
/// - relatedCharacterId / relatedEntityIds 入参回写
/// - isRead 默认 false
/// - 多次写入 occurredAt 单调递增
/// - 不开 writeTxn(caller 持锁,service 内部纯 put)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_event_svc_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7 type 写入 case
  // ─────────────────────────────────────────────────────────────────────────

  test('#1 retreatCompleted 写入 GameEvent + 字段回填', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() => svc.recordRetreatCompleted(
          characterId: 10,
          characterName: '试客',
          actualHours: 6,
          mapName: '山林',
        ));

    final all = await isar.gameEvents.where().findAll();
    expect(all, hasLength(1));
    final e = all.first;
    expect(e.eventType, GameEventType.retreatCompleted);
    expect(e.relatedCharacterId, 10);
    expect(e.isRead, isFalse);
    expect(e.title.isNotEmpty, isTrue);
    expect(e.summary.contains('试客'), isTrue);
    expect(e.summary.contains('山林'), isTrue);
  });

  test('#2 adventureTriggered 含 encounterId 入 relatedEntityIds', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() => svc.recordAdventureTriggered(
          characterId: 10,
          encounterId: 'bamboo_listen_rain',
          encounterTitle: '听雨悟剑',
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.adventureTriggered);
    expect(e.relatedEntityIds, contains('bamboo_listen_rain'));
    expect(e.title, '听雨悟剑');
  });

  test('#3 equipmentObtained 含 defId + id 双标识 + nullable characterId',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() => svc.recordEquipmentObtained(
          characterId: null,
          equipmentId: 42,
          equipmentDefId: 'sword_qiu_ji',
          equipmentName: '秋寂剑',
          source: '夜袭山贼营',
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.equipmentObtained);
    expect(e.relatedCharacterId, isNull);
    expect(e.relatedEntityIds, containsAll(['sword_qiu_ji', '42']));
    expect(e.summary.contains('秋寂剑'), isTrue);
    expect(e.summary.contains('夜袭山贼营'), isTrue);
  });

  test('#5 skillEnlightened 含 skillId 入 relatedEntityIds', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() => svc.recordSkillEnlightened(
          characterId: 10,
          skillId: 'ting_yu_jian',
          skillName: '听雨剑',
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.skillEnlightened);
    expect(e.relatedEntityIds, contains('ting_yu_jian'));
    expect(e.summary.contains('听雨剑'), isTrue);
  });

  test('#6 realmBreakthrough 主角(founder)路由', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final ch = Character.create(
      name: '主角',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
    );
    const result = AdvancementResult(
      layersGained: 1,
      tierBefore: RealmTier.xueTu,
      layerBefore: RealmLayer.dengFeng,
      tierAfter: RealmTier.sanLiu,
      layerAfter: RealmLayer.qiMeng,
      internalForceMaxBefore: 100,
      internalForceMaxAfter: 200,
    );
    await isar.writeTxn(() => svc.recordRealmBreakthrough(
          character: ch,
          result: result,
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.realmBreakthrough);
    expect(e.summary.contains('主角'), isTrue);
  });

  test('#6/#9 弟子(disciple)路由 disciplePromoted eventType', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final disciple = Character.create(
      name: '大弟子',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 1, 1),
    );
    const result = AdvancementResult(
      layersGained: 1,
      tierBefore: RealmTier.sanLiu,
      layerBefore: RealmLayer.dengFeng,
      tierAfter: RealmTier.erLiu,
      layerAfter: RealmLayer.qiMeng,
      internalForceMaxBefore: 200,
      internalForceMaxAfter: 400,
    );
    await isar.writeTxn(() => svc.recordRealmBreakthrough(
          character: disciple,
          result: result,
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.disciplePromoted);
    expect(e.title.contains('大弟子'), isTrue);
  });

  test('#7 resonanceUpgraded 含 equipmentId 入 relatedEntityIds', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() => svc.recordResonanceUpgraded(
          characterId: 10,
          equipmentId: 42,
          equipmentName: '秋寂剑',
          newStage: 3,
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.resonanceUpgraded);
    expect(e.relatedEntityIds, contains('42'));
    expect(e.summary.contains('秋寂剑'), isTrue);
    expect(e.summary.contains('3'), isTrue);
  });

  test('#8 bossDefeated 含 stageId 入 relatedEntityIds', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() => svc.recordBossDefeated(
          characterId: 10,
          stageId: 'stage_01_05',
          stageName: '夜袭山贼营',
          bossName: '黑面阎罗',
        ));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.bossDefeated);
    expect(e.relatedEntityIds, contains('stage_01_05'));
    expect(e.title.contains('黑面阎罗'), isTrue);
    expect(e.summary.contains('夜袭山贼营'), isTrue);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 边界 case
  // ─────────────────────────────────────────────────────────────────────────

  test('safety 网:realmBreakthrough layersGained <= 0 不写入', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final ch = Character.create(
      name: '试客',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
    );
    const noOp = AdvancementResult(
      layersGained: 0,
      tierBefore: RealmTier.xueTu,
      layerBefore: RealmLayer.qiMeng,
      tierAfter: RealmTier.xueTu,
      layerAfter: RealmLayer.qiMeng,
      internalForceMaxBefore: 100,
      internalForceMaxAfter: 100,
    );
    await isar.writeTxn(() => svc.recordRealmBreakthrough(
          character: ch,
          result: noOp,
        ));

    final all = await isar.gameEvents.where().findAll();
    expect(all, isEmpty);
  });

  test('多次写入 occurredAt 单调不减(同 microsecond 内允许 >=)', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    await isar.writeTxn(() async {
      await svc.recordRetreatCompleted(
        characterId: 10,
        characterName: '试客',
        actualHours: 1,
        mapName: '山林',
      );
      await svc.recordBossDefeated(
        characterId: 10,
        stageId: 'stage_01_05',
        stageName: '夜袭山贼营',
        bossName: '黑面阎罗',
      );
    });

    final all = await isar.gameEvents.where().sortByOccurredAt().findAll();
    expect(all, hasLength(2));
    expect(
      all[1].occurredAt.isAfter(all[0].occurredAt) ||
          all[1].occurredAt.isAtSameMomentAs(all[0].occurredAt),
      isTrue,
    );
  });
}
