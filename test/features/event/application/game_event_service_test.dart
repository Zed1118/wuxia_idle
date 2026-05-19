import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/lore_loader.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/event/application/game_event_service.dart';

/// P1 #44 · 测试 helper:构造 LoreContent 池(直接传 text 列表)。
LoreContent _loreFor(
  String id, {
  List<String> obtained = const [],
  List<String> bossDefeated = const [],
}) =>
    LoreContent(
      id: id,
      name: id,
      defaultLore: const [],
      continuedLoreObtainedPool:
          obtained.map((t) => LoreSegment(text: t)).toList(),
      continuedLoreBossDefeatedPool:
          bossDefeated.map((t) => LoreSegment(text: t)).toList(),
      isPlaceholder: false,
    );

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

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 5 延续典故 hook case
  // ─────────────────────────────────────────────────────────────────────────

  test('#8 bossDefeated 传 warbornEquipment → 每件追加 lore isPreset=false',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final eq1 = Equipment.create(
      defId: 'sword_qiu_ji',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    final eq2 = Equipment.create(
      defId: 'armor_qiu_ji',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.armor,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.putAll([eq1, eq2]);
      await svc.recordBossDefeated(
        characterId: 10,
        stageId: 'stage_01_05',
        stageName: '夜袭山贼营',
        bossName: '黑面阎罗',
        warbornEquipment: [eq1, eq2],
      );
    });

    final after1 = await isar.equipments.get(eq1.id);
    final after2 = await isar.equipments.get(eq2.id);
    expect(after1!.lores, hasLength(1));
    expect(after2!.lores, hasLength(1));
    expect(after1.lores.first.isPreset, isFalse);
    expect(after1.lores.first.triggerEventDesc, contains('bossDefeated'));
    expect(after2.lores.first.isPreset, isFalse);
  });

  test('#8 bossDefeated 不传 warbornEquipment → 无 lore 副作用', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final eq = Equipment.create(
      defId: 'sword_qiu_ji',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
      await svc.recordBossDefeated(
        characterId: 10,
        stageId: 'stage_01_05',
        stageName: '夜袭山贼营',
        bossName: '黑面阎罗',
      );
    });
    final after = await isar.equipments.get(eq.id);
    expect(after!.lores, isEmpty);
  });

  test('#3 equipmentObtained 传 equipment → 追加首段延续 lore', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final eq = Equipment.create(
      defId: 'sword_xun_chang',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttack: 50,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
      await svc.recordEquipmentObtained(
        characterId: null,
        equipmentId: eq.id,
        equipmentDefId: 'sword_xun_chang',
        equipmentName: '寻常剑',
        source: '夜袭山贼营',
        equipment: eq,
      );
    });
    final after = await isar.equipments.get(eq.id);
    expect(after!.lores, hasLength(1));
    expect(after.lores.first.isPreset, isFalse);
    expect(after.lores.first.text.contains('寻常剑'), isTrue);
    expect(after.lores.first.text.contains('夜袭山贼营'), isTrue);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // P1 #44 · LoreLoader 池抽样 + fallback 兜底
  // ─────────────────────────────────────────────────────────────────────────

  test(
      'P1 #44 · equipmentObtained yaml 池命中 + 占位符替换(deterministic seed)',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(
      isar,
      loreLoader: (id) async => _loreFor(
        id,
        obtained: ['于「{source}」初见此剑,寒光乍现。'],
      ),
      random: Random(0),
    );
    final eq = Equipment.create(
      defId: 'sword_xun_chang',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttack: 50,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
      await svc.recordEquipmentObtained(
        characterId: null,
        equipmentId: eq.id,
        equipmentDefId: 'sword_xun_chang',
        equipmentName: '寻常剑',
        source: '夜袭山贼营',
        equipment: eq,
      );
    });
    final after = await isar.equipments.get(eq.id);
    expect(after!.lores, hasLength(1));
    expect(after.lores.first.text, '于「夜袭山贼营」初见此剑,寒光乍现。');
    expect(after.lores.first.text.contains('寻常剑'), isFalse,
        reason: 'yaml 按装备拆池,文案直接写"此剑",不用 {equip_name} 变量');
    expect(after.lores.first.isPreset, isFalse);
  });

  test('P1 #44 · bossDefeated 多件 warbornEquipment 各自抽各自 yaml 池',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(
      isar,
      loreLoader: (id) async {
        if (id == 'sword_a') {
          return _loreFor(id,
              bossDefeated: ['剑 A 见 {boss_name} 于 {stage_name}。']);
        }
        if (id == 'sword_b') {
          return _loreFor(id,
              bossDefeated: ['剑 B 战 {boss_name} 于 {stage_name}。']);
        }
        return LoreContent.placeholder(id);
      },
      random: Random(0),
    );
    final eq1 = Equipment.create(
      defId: 'sword_a',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    final eq2 = Equipment.create(
      defId: 'sword_b',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.putAll([eq1, eq2]);
      await svc.recordBossDefeated(
        characterId: 10,
        stageId: 'stage_01_05',
        stageName: '夜袭山贼营',
        bossName: '黑面阎罗',
        warbornEquipment: [eq1, eq2],
      );
    });
    final after1 = await isar.equipments.get(eq1.id);
    final after2 = await isar.equipments.get(eq2.id);
    expect(after1!.lores.first.text, '剑 A 见 黑面阎罗 于 夜袭山贼营。');
    expect(after2!.lores.first.text, '剑 B 战 黑面阎罗 于 夜袭山贼营。');
  });

  test('P1 #44 · yaml placeholder → fallback Dart 模板(equipmentObtained)',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(
      isar,
      loreLoader: (id) async => LoreContent.placeholder(id),
      random: Random(0),
    );
    final eq = Equipment.create(
      defId: 'sword_xun_chang',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttack: 50,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
      await svc.recordEquipmentObtained(
        characterId: null,
        equipmentId: eq.id,
        equipmentDefId: 'sword_xun_chang',
        equipmentName: '寻常剑',
        source: '夜袭山贼营',
        equipment: eq,
      );
    });
    final after = await isar.equipments.get(eq.id);
    expect(after!.lores, hasLength(1));
    expect(after.lores.first.text.contains('寻常剑'), isTrue,
        reason: 'fallback Dart 模板含 equipName');
    expect(after.lores.first.text.contains('夜袭山贼营'), isTrue,
        reason: 'fallback Dart 模板含 source');
  });

  test('P1 #44 · yaml non-placeholder 但目标池为空 → fallback(bossDefeated)',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(
      isar,
      // obtained 池非空、bossDefeated 池为空 → bossDefeated 走 fallback
      loreLoader: (id) async => _loreFor(id,
          obtained: ['不该被 bossDefeated 抽到。'], bossDefeated: const []),
      random: Random(0),
    );
    final eq = Equipment.create(
      defId: 'sword_qiu_ji',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
      await svc.recordBossDefeated(
        characterId: 10,
        stageId: 'stage_01_05',
        stageName: '夜袭山贼营',
        bossName: '黑面阎罗',
        warbornEquipment: [eq],
      );
    });
    final after = await isar.equipments.get(eq.id);
    expect(after!.lores, hasLength(1));
    expect(after.lores.first.text.contains('黑面阎罗'), isTrue,
        reason: 'fallback Dart 模板含 bossName');
    expect(after.lores.first.text.contains('不该被'), isFalse,
        reason: 'obtained 池不应被 bossDefeated 触发抽中');
  });

  test('多次 bossDefeated 同装备 → lore 累加(防刷由 caller 端 isFirstClear 兜底)',
      () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final eq = Equipment.create(
      defId: 'sword_qiu_ji',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      baseAttack: 100,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
    );
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
      for (var i = 0; i < 3; i++) {
        await svc.recordBossDefeated(
          characterId: 10,
          stageId: 'stage_01_05',
          stageName: '夜袭山贼营',
          bossName: '黑面阎罗',
          warbornEquipment: [eq],
        );
      }
    });
    final after = await isar.equipments.get(eq.id);
    // service 不防刷:3 次调用累加 3 段(caller 端 isFirstClear 防刷,见
    // stage_entry_flow / tower_entry_flow #8 hook 条件)。
    expect(after!.lores, hasLength(3));
    expect(after.lores.every((l) => !l.isPreset), isTrue);
  });
}
