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

/// P1 #42 补丁 · #4 lineageInherited 接口 placeholder + #9 路由 edge test。
///
/// 覆盖 game_event_service_test.dart 未细化的分支:
/// - A: #4 lineageInherited 接口 placeholder(Phase 5+ 激活,目前无实装)
/// - B: #9 founder 路由 realmBreakthrough 反向断言(不命中 disciplePromoted)
/// - C: #9 disciple 路由 disciplePromoted 反向断言(不命中 realmBreakthrough)
/// - D: #9 grandDisciple 兜底路由 → realmBreakthrough(非 disciple 第三枚举值)
/// - E: 多次 breakthrough 同角色 → events 累积且 eventType 各自正确
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lineage_edge_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ─── A · #4 lineageInherited placeholder ─────────────────────────────────

  test(
    '#4 lineageInherited 接口 placeholder — Phase 5+ 激活前 API 未实装',
    () {
      // 当前 GameEventService 无 recordLineageInherited 实现
      // (game_event_service.dart §注释 #4 techniqueLearned/lineageInherited 同批留接口)。
      // Phase 5+ 激活后取消 skip,补充如下断言:
      //   await isar.writeTxn(() => svc.recordLineageInherited(
      //         characterId: founderChar.id, discipleId: discipleChar.id));
      //   final e = (await isar.gameEvents.where().findAll()).single;
      //   expect(e.eventType, GameEventType.lineageInherited);
      //   expect(e.isRead, isFalse);
      expect(true, isTrue); // 占位断言,不影响 CI
    },
    skip: 'recordLineageInherited 未实装,Phase 5+ 师徒系统升级时解除 skip 并补断言',
  );

  // ─── B · #9 founder 反向断言 ───────────────────────────────────────────────

  test('#9 founder 路由 realmBreakthrough — 反向断言不命中 disciplePromoted', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final founder = Character.create(
      name: '开派祖师',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
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
    await isar.writeTxn(
        () => svc.recordRealmBreakthrough(character: founder, result: result));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.realmBreakthrough);
    expect(e.eventType, isNot(GameEventType.disciplePromoted));
    expect(e.summary.contains('开派祖师'), isTrue);
  });

  // ─── C · #9 disciple 反向断言 ──────────────────────────────────────────────

  test('#9 disciple 路由 disciplePromoted — 反向断言不命中 realmBreakthrough', () async {
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
      layersGained: 2,
      tierBefore: RealmTier.sanLiu,
      layerBefore: RealmLayer.dengFeng,
      tierAfter: RealmTier.erLiu,
      layerAfter: RealmLayer.ruMen,
      internalForceMaxBefore: 200,
      internalForceMaxAfter: 500,
    );
    await isar.writeTxn(
        () => svc.recordRealmBreakthrough(character: disciple, result: result));

    final e = (await isar.gameEvents.where().findAll()).single;
    expect(e.eventType, GameEventType.disciplePromoted);
    expect(e.eventType, isNot(GameEventType.realmBreakthrough));
    expect(e.title.contains('大弟子'), isTrue);
  });

  // ─── D · grandDisciple 兜底路由 ───────────────────────────────────────────

  test('#9 grandDisciple 兜底路由 → realmBreakthrough(非 disciple 第三枚举值)', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final grandDisciple = Character.create(
      name: '二代弟子',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.grandDisciple,
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
    await isar.writeTxn(() =>
        svc.recordRealmBreakthrough(character: grandDisciple, result: result));

    final e = (await isar.gameEvents.where().findAll()).single;
    // isDisciple 判断仅 == LineageRole.disciple;grandDisciple 走 else → realmBreakthrough
    expect(e.eventType, GameEventType.realmBreakthrough);
    expect(e.eventType, isNot(GameEventType.disciplePromoted));
  });

  // ─── E · 多次 breakthrough 累积 ──────────────────────────────────────────────

  test('多次 recordRealmBreakthrough 同 disciple → events 累积且 eventType 一致', () async {
    final isar = IsarSetup.instance;
    final svc = GameEventService(isar);
    final disciple = Character.create(
      name: '连升弟子',
      realmTier: RealmTier.sanLiu,
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
    await isar.writeTxn(() async {
      for (var i = 0; i < 3; i++) {
        await svc.recordRealmBreakthrough(character: disciple, result: result);
      }
    });

    final all = await isar.gameEvents.where().findAll();
    expect(all, hasLength(3));
    for (final e in all) {
      expect(e.eventType, GameEventType.disciplePromoted);
      expect(e.isRead, isFalse);
    }
  });
}
