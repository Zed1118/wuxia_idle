import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/inventory_item.dart';
import 'package:wuxia_idle/data/models/retreat_session.dart';
import 'package:wuxia_idle/services/seclusion_service.dart';

/// Phase 3 T48 · SeclusionService 真 Isar 落地测试。
void main() {
  late Directory tempDir;

  const kSaveDataId = 1;
  const kCharId = 10;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_seclusion_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);

    // 写入测试用 Character（境界学徒），用工厂方法确保 late 字段全初始化
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
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // canEnterMap
  // ─────────────────────────────────────────────────────────────────────────

  group('canEnterMap', () {
    test('学徒可进山林（学徒起步）', () {
      expect(
        SeclusionService.canEnterMap(
          mapType: RetreatMapType.shanLin,
          charRealmTier: RealmTier.xueTu,
          maps: GameRepository.instance.seclusionMaps,
        ),
        isTrue,
      );
    });

    test('学徒无法进断崖绝壁（宗师要求）', () {
      expect(
        SeclusionService.canEnterMap(
          mapType: RetreatMapType.duanYaJueBi,
          charRealmTier: RealmTier.xueTu,
          maps: GameRepository.instance.seclusionMaps,
        ),
        isFalse,
      );
    });

    test('宗师可进所有 5 张地图', () {
      for (final mt in RetreatMapType.values) {
        expect(
          SeclusionService.canEnterMap(
            mapType: mt,
            charRealmTier: RealmTier.zongShi,
            maps: GameRepository.instance.seclusionMaps,
          ),
          isTrue,
          reason: '${mt.name} 应对宗师开放',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // startRetreat
  // ─────────────────────────────────────────────────────────────────────────

  group('startRetreat', () {
    test('正常创建 active session，character.currentRetreatSessionId 同步', () async {
      final now = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );

      expect(session.mapType, RetreatMapType.shanLin);
      expect(session.durationHours, 4);
      expect(session.status, RetreatStatus.active);
      expect(session.startedAt, now);
      expect(session.completedAt, isNull);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.currentRetreatSessionId, session.id);
    });

    test('境界不足抛 StateError', () async {
      await expectLater(
        () => SeclusionService.startRetreat(
          mapType: RetreatMapType.duanYaJueBi,
          durationHours: 1,
          saveDataId: kSaveDataId,
          characterId: kCharId,
          charRealmTier: RealmTier.xueTu,
          maps: GameRepository.instance.seclusionMaps,
          now: DateTime.now(),
        ),
        throwsStateError,
      );
    });

    test('旧 active session 被 abandon，新 session 变 active', () async {
      final t1 = DateTime(2026, 5, 11, 10, 0);
      final s1 = await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: t1,
      );

      final t2 = DateTime(2026, 5, 11, 11, 0);
      final s2 = await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: t2,
      );

      final old = await IsarSetup.instance.retreatSessions.get(s1.id);
      expect(old?.status, RetreatStatus.abandoned);
      expect(s2.status, RetreatStatus.active);

      final count = await IsarSetup.instance.retreatSessions
          .filter()
          .statusEqualTo(RetreatStatus.active)
          .count();
      expect(count, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getActiveSession
  // ─────────────────────────────────────────────────────────────────────────

  group('getActiveSession', () {
    test('无活跃 session 时返回 null', () async {
      expect(await SeclusionService.getActiveSession(kSaveDataId), isNull);
    });

    test('startRetreat 后可取回 active session', () async {
      await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );
      final active = await SeclusionService.getActiveSession(kSaveDataId);
      expect(active, isNotNull);
      expect(active!.status, RetreatStatus.active);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // computeOutputs（纯函数，不写 Isar）
  // ─────────────────────────────────────────────────────────────────────────

  group('computeOutputs', () {
    RetreatSession makeSession({
      int durationHours = 4,
      required DateTime startedAt,
    }) {
      final s = RetreatSession()
        ..id = 1
        ..saveDataId = kSaveDataId
        ..mapType = RetreatMapType.shanLin
        ..durationHours = durationHours
        ..startedAt = startedAt
        ..status = RetreatStatus.active
        ..actualRewards = [];
      return s;
    }

    test('0 小时 → mojianshi=0', () {
      final now = DateTime(2026, 5, 11, 10, 0);
      final session = makeSession(startedAt: now);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.mojianshi, 0);
      expect(out.actualHours, closeTo(0.0, 0.01));
    });

    test('1 小时学徒山林 → mojianshi = floor(1.0 × 1 × 1.0 × dayBonus)', () {
      final start = DateTime(2026, 5, 11, 10, 0); // 上午 10 点，无时辰加成
      final now = start.add(const Duration(hours: 1));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.mojianshi, 1); // floor(1.0 × 1h × 1.0 × 1.0) = 1
      expect(out.actualHours, closeTo(1.0, 0.01));
    });

    test('72h 封顶：超过计划时长取 min(elapsed, plan, cap)', () {
      final start = DateTime(2026, 5, 11, 10, 0);
      // elapsed = 100h, plan = 4h, cap = 72h → actualHours = 4h
      final now = start.add(const Duration(hours: 100));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.actualHours, closeTo(4.0, 0.01));
    });

    test('cap=72h 封顶情况：plan=1000h 时 actualHours 不超 72', () {
      final start = DateTime(2026, 5, 11, 10, 0);
      final now = start.add(const Duration(hours: 200));
      final session = makeSession(durationHours: 1000, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.actualHours, closeTo(72.0, 0.01));
    });

    test('子时加成（23:00 开始）→ mojianshi 乘 1.2', () {
      final start = DateTime(2026, 5, 11, 23, 0); // 子时
      final now = start.add(const Duration(hours: 1));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.mojianshi, 1); // floor(1.0 × 1h × 1.0 × 1.2) = floor(1.2) = 1
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // completeRetreat
  // ─────────────────────────────────────────────────────────────────────────

  group('completeRetreat', () {
    test('收功后 session.status=completed + actualRewards 有 mojianshi', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: start,
      );

      final completeAt = start.add(const Duration(hours: 4));
      final out = await SeclusionService.completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: completeAt,
      );

      expect(out.mojianshi, greaterThan(0));

      final updated =
          await IsarSetup.instance.retreatSessions.get(session.id);
      expect(updated?.status, RetreatStatus.completed);
      expect(updated?.completedAt, completeAt);
      expect(updated?.actualRewards.isNotEmpty, isTrue);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.currentRetreatSessionId, isNull);
    });

    test('收功后 InventoryItem.moJianShi 数量增加', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: start,
      );
      await SeclusionService.completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 4)),
      );

      final item = await IsarSetup.instance.inventoryItems
          .filter()
          .itemTypeEqualTo(ItemType.moJianShi)
          .findFirst();
      expect(item, isNotNull);
      expect(item!.quantity, greaterThan(0));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // abandonRetreat
  // ─────────────────────────────────────────────────────────────────────────

  group('abandonRetreat', () {
    test('abandon 后 status=abandoned + 不发奖 + character id 清零', () async {
      final session = await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime(2026, 5, 11, 10, 0),
      );
      await SeclusionService.abandonRetreat(
        session: session,
        characterId: kCharId,
        now: DateTime(2026, 5, 11, 11, 0),
      );

      final updated =
          await IsarSetup.instance.retreatSessions.get(session.id);
      expect(updated?.status, RetreatStatus.abandoned);
      expect(updated?.actualRewards, isEmpty);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.currentRetreatSessionId, isNull);

      final item = await IsarSetup.instance.inventoryItems
          .filter()
          .itemTypeEqualTo(ItemType.moJianShi)
          .findFirst();
      expect(item, isNull, reason: 'abandon 不发磨剑石');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 隔离性：与 TowerProgress / MainlineProgress 无交叉
  // ─────────────────────────────────────────────────────────────────────────

  group('saveDataId 隔离', () {
    test('saveDataId=2 的 session 不干扰 saveDataId=1', () async {
      await SeclusionService.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: 2,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );
      final active1 = await SeclusionService.getActiveSession(1);
      expect(active1, isNull, reason: 'saveDataId=1 应无 active session');
    });
  });
}
