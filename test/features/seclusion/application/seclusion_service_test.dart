import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/application/progression_gate_service.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/domain/seclusion_map_def.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// Phase 3 T48 · SeclusionService 真 Isar 落地测试。
void main() {
  late Directory tempDir;

  const kSaveDataId = 1;
  const kCharId = 10;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
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
    test('开放式闭关固化开始境界且不再需要计划时长', () async {
      final now = DateTime(2026, 7, 12, 8);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.erLiu,
            maps: GameRepository.instance.seclusionMaps,
            now: now,
          );

      expect(session.realmTierAtStart, RealmTier.erLiu);
      expect(session.durationHours, 0, reason: '旧字段仅用于存档兼容');
    });

    test('正常创建 active session，character.currentRetreatSessionId 同步', () async {
      final now = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: now,
          );

      expect(session.mapType, RetreatMapType.shanLin);
      expect(session.durationHours, 0, reason: '开放式闭关不再保存计划时长');
      expect(session.realmTierAtStart, RealmTier.xueTu);
      expect(session.status, RetreatStatus.active);
      expect(session.startedAt, now);
      expect(session.completedAt, isNull);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.currentRetreatSessionId, session.id);
    });

    test('境界不足抛 StateError', () async {
      await expectLater(
        () => SeclusionService(isar: IsarSetup.instance).startRetreat(
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
      final s1 = await SeclusionService(isar: IsarSetup.instance).startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: t1,
      );

      final t2 = DateTime(2026, 5, 11, 11, 0);
      final s2 = await SeclusionService(isar: IsarSetup.instance).startRetreat(
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
      expect(
        await SeclusionService(
          isar: IsarSetup.instance,
        ).getActiveSession(kSaveDataId),
        isNull,
      );
    });

    test('startRetreat 后可取回 active session', () async {
      await SeclusionService(isar: IsarSetup.instance).startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );
      final active = await SeclusionService(
        isar: IsarSetup.instance,
      ).getActiveSession(kSaveDataId);
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

    test(
      '1 小时学徒山林 → mojianshi = floor(perHour × hours × scale × solarBonus)',
      () {
        final start = DateTime(2026, 5, 11, 10, 0); // 上午 10 点非子时非节气
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
      },
    );

    test('地图路径常驻，事件记录按 actualHours 阈值触发', () {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = makeSession(durationHours: 12, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 4)),
      );

      expect(out.routeSteps, hasLength(3));
      expect(out.routeSteps.first, contains('旧樵径'));
      expect(out.mapEvents, hasLength(2));
      expect(out.mapEvents.map((e) => e.kind), [
        RetreatMapEventKind.harvest,
        RetreatMapEventKind.trace,
      ]);
      expect(out.mapEvents.last.hourMark, 4.0);
    });

    test('0 小时时不触发地图事件记录', () {
      final now = DateTime(2026, 5, 11, 10, 0);
      final session = makeSession(startedAt: now);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );

      expect(out.routeSteps, hasLength(3));
      expect(out.mapEvents, isEmpty);
    });

    test('72h 完整闭关封顶：旧计划时长不再截断结算', () {
      final start = DateTime(2026, 5, 11, 10, 0);
      // elapsed = 100h, legacy plan = 4h, cap = 72h → actualHours = 72h
      final now = start.add(const Duration(hours: 100));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.actualHours, closeTo(72.0, 0.01));
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

    test('子时加成（23:00 开始）只乘 internalForcePoints，不影响 mojianshi', () {
      // W15 #30 语义修正：原 `_timeDayBonus` 子时×1.2 全产出加成是 bug，
      // yaml 实际 effect: internal_force_growth 只乘内力维度。
      final start = DateTime(2026, 5, 11, 23, 0); // 子时
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // mojianshi 山林 perHour=1.0,xueTu scale=1.0,无节气 → floor(1.0×4×1.0)=4
      // 子时不参与 mojianshi 公式 → 4 而非 floor(4×1.2)=4(此处 floor 巧合相同，
      // 用 experiencePoints 反例更明确)
      expect(out.mojianshi, 4);
      // experience 山林 perHour=3,无节气 → floor(3×4×1.0)=12。
      // 子时同样不参与 experience 公式。
      expect(out.experiencePoints, 12);
      // internalForce 山林 base=5,internalForceGrowth=1.0,xueTu scale=1.0,
      // 子时×1.2 → floor(5×1.0×4×1.0×1.0×1.2)=floor(24.0)=24
      expect(out.internalForcePoints, 24);
    });

    test('平时（非子时）internalForcePoints 不受子时加成', () {
      final start = DateTime(2026, 5, 11, 10, 0); // 上午 10 点非子时
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // floor(5×1.0×4×1.0×1.0×1.0)=20
      expect(out.internalForcePoints, 20);
    });

    // W18-A1.2 心法相生 internalForceGrowthPct 注入 internalForcePoints 维度
    test(
      'W18-A1.2 synergyInternalForceGrowthPct=0.10 → internalForcePoints × 1.10',
      () {
        final start = DateTime(2026, 5, 11, 10, 0); // 上午 10 点非子时
        final now = start.add(const Duration(hours: 4));
        final session = makeSession(durationHours: 4, startedAt: start);
        final out = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
          synergyInternalForceGrowthPct: 0.10, // 组合 5 同辈互补 yaml 数值
        );
        // floor(5×1.0×4×1.0×1.0×1.0×1.0×1.10)=floor(22.0)=22
        expect(
          out.internalForcePoints,
          22,
          reason: '相生 internalForceGrowthPct=0.10 → 内力产出 20 → 22',
        );
      },
    );

    test(
      'W18-A1.2 synergyInternalForceGrowthPct=0.0(默认参数)→ internalForcePoints 不变',
      () {
        final start = DateTime(2026, 5, 11, 10, 0);
        final now = start.add(const Duration(hours: 4));
        final session = makeSession(durationHours: 4, startedAt: start);
        // 不显式传 synergyInternalForceGrowthPct → 默认 0.0
        final out = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
        );
        expect(
          out.internalForcePoints,
          20,
          reason: '默认参数 0.0 → (1 + 0.0) = 1.0 倍,与回归基线一致',
        );
      },
    );

    test(
      'W18-A1.2 synergyInternalForceGrowthPct 仅影响 internalForcePoints,不影响其他 3 维度',
      () {
        final start = DateTime(2026, 5, 11, 10, 0);
        final now = start.add(const Duration(hours: 4));
        final session = makeSession(durationHours: 4, startedAt: start);
        final out = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: RealmTier.xueTu,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
          synergyInternalForceGrowthPct: 0.10,
        );
        // mojianshi / experience / techniqueLearn 公式中不含 synergyGrowthPct
        // 项,数值与基线一致(回归断言)
        expect(out.mojianshi, 4, reason: 'mojianshi 不受相生 growth 影响');
        expect(out.experiencePoints, 12, reason: 'experience 不受相生 growth 影响');
      },
    );

    test('节气日（立春 2026-02-04 上午 10:00）→ 全产出 ×1.30', () {
      // 节气日 +30% 应用到所有 4 维度，子时此时未触发
      final start = DateTime(2026, 2, 4, 10, 0);
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // mojianshi floor(1.0×4×1.0×1.30)=5
      expect(out.mojianshi, 5);
      // experience floor(3×4×1.0×1.30)=15
      expect(out.experiencePoints, 15);
      // internalForce floor(5×1.0×4×1.0×1.30×1.0)=26
      expect(out.internalForcePoints, 26);
    });

    test('节气日 + 子时叠加（冬至 2026-12-22 23:00）→ 内力维度全乘', () {
      final start = DateTime(2026, 12, 22, 23, 0); // 冬至子时
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // internalForce floor(5×1.0×4×1.0×1.30×1.20)=floor(31.2)=31
      expect(out.internalForcePoints, 31);
      // mojianshi 不受子时加成，仅节气 floor(1.0×4×1.0×1.30)=5
      expect(out.mojianshi, 5);
    });

    test('藏经阁 techniqueLearnRate=1.5 → techniqueLearnPoints 翻 1.5 倍', () {
      // 藏经阁 base techniqueLearnRate=1.5，对比山林 1.0
      final start = DateTime(2026, 5, 11, 10, 0); // 非节气非子时
      final now = start.add(const Duration(hours: 4));
      final cangJingSession = RetreatSession()
        ..id = 2
        ..saveDataId = kSaveDataId
        ..mapType = RetreatMapType.cangJingGe
        ..durationHours = 4
        ..startedAt = start
        ..status = RetreatStatus.active
        ..actualRewards = [];
      // 藏经阁要 sanLiu 境界，scale=1.3
      final out = SeclusionService.computeOutputs(
        session: cangJingSession,
        charRealmTier: RealmTier.sanLiu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // techniqueLearn floor(0.5×1.5×4×1.3×1.0)=floor(3.9)=3
      expect(out.techniqueLearnPoints, 3);
      // 山林 sanLiu 对照：floor(0.5×1.0×4×1.3×1.0)=floor(2.6)=2
    });

    test('悬崖瀑布 internalForceGrowth=1.5 → internalForcePoints 翻 1.5 倍', () {
      final start = DateTime(2026, 5, 11, 10, 0);
      final now = start.add(const Duration(hours: 4));
      final xuanYaSession = RetreatSession()
        ..id = 3
        ..saveDataId = kSaveDataId
        ..mapType = RetreatMapType.xuanYaPuBu
        ..durationHours = 4
        ..startedAt = start
        ..status = RetreatStatus.active
        ..actualRewards = [];
      // 悬崖瀑布要 erLiu 境界,scale=1.3^2=1.69
      final out = SeclusionService.computeOutputs(
        session: xuanYaSession,
        charRealmTier: RealmTier.erLiu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // internalForce floor(5×1.5×4×1.69×1.0×1.0)=floor(50.7)=50
      expect(out.internalForcePoints, 50);
    });

    test('§12.1 #7 正午 + 刚猛 → internalForcePoints ×1.2', () {
      // 正午 11:00,刚猛角色,xueTu,山林:internalForce floor(5×1.0×4×1.0×1.0×1.0×1.2)=24
      final start = DateTime(2026, 5, 11, 11, 0); // 正午
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
        charSchool: TechniqueSchool.gangMeng,
      );
      expect(
        out.internalForcePoints,
        24,
        reason: '正午 + 刚猛 → internalForcePoints ×1.2',
      );
      // 其他维度不受 zhengWu 加成
      expect(out.mojianshi, 4, reason: '正午 mojianshi 不加成');
      expect(out.experiencePoints, 12, reason: '正午 experience 不加成');
    });

    test('§12.1 #7 正午但非刚猛 → internalForcePoints 不加成', () {
      final start = DateTime(2026, 5, 11, 11, 0);
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      // 非刚猛(灵巧)
      final outLq = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
        charSchool: TechniqueSchool.lingQiao,
      );
      expect(outLq.internalForcePoints, 20, reason: '灵巧角色正午不享受阳刚加成,基准 20');
      // null(老 caller 没传 school)
      final outNull = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(
        outNull.internalForcePoints,
        20,
        reason: '不传 charSchool 默认 null → 不加成,沿老体例兼容',
      );
    });

    test('§12.1 #7 刚猛但非正午 → internalForcePoints 不加成', () {
      final start = DateTime(2026, 5, 11, 10, 0); // 上午 10 点非正午
      final now = start.add(const Duration(hours: 4));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
        charSchool: TechniqueSchool.gangMeng,
      );
      expect(out.internalForcePoints, 20, reason: '刚猛在非正午不享受 zhengWu 加成,基准 20');
    });

    test('cap 72h 边界 + 断崖宗师全 buff 不超 999999 红线', () {
      // 断崖绝壁 zongShi 72h cap + 子时 + 节气：极限场景验红线 clamp
      final start = DateTime(2026, 2, 4, 23, 0); // 立春 + 子时
      final now = start.add(const Duration(hours: 200)); // 远超 cap
      final session = RetreatSession()
        ..id = 4
        ..saveDataId = kSaveDataId
        ..mapType = RetreatMapType.duanYaJueBi
        ..durationHours = 1000
        ..startedAt = start
        ..status = RetreatStatus.active
        ..actualRewards = [];
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.zongShi,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.actualHours, closeTo(72.0, 0.01));
      // internalForce floor(5×1.5×72×3.713×1.30×1.20)=floor(3126.6)=3126
      expect(out.internalForcePoints, lessThan(999999));
      expect(out.internalForcePoints, greaterThan(3000));
    });

    // P4 材料经济 P1：银两产出 ──────────────────────────────────────────────

    test('1 小时山林 silver = floor(silverPerHour × 1h × scale × solarBonus)', () {
      final start = DateTime(2026, 5, 11, 10, 0); // 非子时非节气
      final now = start.add(const Duration(hours: 1));
      final session = makeSession(durationHours: 4, startedAt: start);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      // 山林(唯一 xueTu 图) silver_per_hour × xueTu scale(1.0) × 1h × 无节气(1.0)。
      // 读 config 不硬编码:T6 调 silver_per_hour 后测自动跟随(约束语义非瞬时值)。
      final shanLin = GameRepository.instance.seclusionMaps.firstWhere(
        (m) => m.requiredRealm == RealmTier.xueTu,
      );
      expect(out.silver, (shanLin.silverPerHour * 1.0 * 1.0).floor());
    });

    test('五张闭关地图均配置轻量特色产出，且引用现有 item def', () {
      const expected = <RetreatMapType, Set<String>>{
        RetreatMapType.shanLin: {'item_yaocao'},
        RetreatMapType.guJianZhong: {'item_duancai'},
        RetreatMapType.cangJingGe: {'item_kaifeng_fucai'},
        RetreatMapType.xuanYaPuBu: {'item_lingquanshui'},
        RetreatMapType.duanYaJueBi: {
          'item_yaocao',
          'item_lingquanshui',
          'item_duancai',
          'item_kaifeng_fucai',
        },
      };

      for (final map in GameRepository.instance.seclusionMaps) {
        expect(
          map.itemOutputsPerHour.keys.toSet(),
          expected[map.mapType],
          reason: '${map.mapName} 应有专属小产出配置',
        );
        for (final itemId in map.itemOutputsPerHour.keys) {
          expect(
            GameRepository.instance.itemDefs.containsKey(itemId),
            isTrue,
            reason: '${map.mapName} 引用不存在的道具 $itemId',
          );
        }
      }
    });

    test('4 小时五图特色产出均进入 itemRewards', () {
      final start = DateTime(2026, 5, 11, 10, 0);
      final now = start.add(const Duration(hours: 4));
      const tiers = <RetreatMapType, RealmTier>{
        RetreatMapType.shanLin: RealmTier.xueTu,
        RetreatMapType.guJianZhong: RealmTier.sanLiu,
        RetreatMapType.cangJingGe: RealmTier.sanLiu,
        RetreatMapType.xuanYaPuBu: RealmTier.erLiu,
        RetreatMapType.duanYaJueBi: RealmTier.zongShi,
      };

      for (final map in GameRepository.instance.seclusionMaps) {
        final session = RetreatSession()
          ..id = 20 + map.mapType.index
          ..saveDataId = kSaveDataId
          ..mapType = map.mapType
          ..durationHours = 4
          ..startedAt = start
          ..status = RetreatStatus.active
          ..actualRewards = [];
        final out = SeclusionService.computeOutputs(
          session: session,
          charRealmTier: tiers[map.mapType]!,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: now,
        );

        for (final itemId in map.itemOutputsPerHour.keys) {
          expect(
            out.itemRewards[itemId],
            greaterThan(0),
            reason: '${map.mapName} 4h 应产出 $itemId',
          );
        }
      }
    });

    test('0 小时 → silver=0', () {
      final now = DateTime(2026, 5, 11, 10, 0);
      final session = makeSession(startedAt: now);
      final out = SeclusionService.computeOutputs(
        session: session,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: now,
      );
      expect(out.silver, 0);
      expect(out.itemRewards, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // completeRetreat
  // ─────────────────────────────────────────────────────────────────────────

  group('completeRetreat', () {
    test('10 天合并 72h 闭关 + 168h 挂机经验只应用一次且旧账不变', () async {
      await IsarSetup.instance.writeTxn(() async {
        final character = await IsarSetup.instance.characters.get(kCharId);
        character!
          ..level = 77
          ..levelExp = 4321;
        await IsarSetup.instance.characters.put(character);
      });
      final start = DateTime(2026, 5, 1, 10);
      final completeAt = start.add(const Duration(days: 10));
      final service = SeclusionService(isar: IsarSetup.instance);
      final session = await service.startRetreat(
        mapType: RetreatMapType.shanLin,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: start,
      );

      final result = await service.completeRetreat(
        session: session,
        characterId: kCharId,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: completeAt,
      );

      expect(result.elapsedHours, 240);
      expect(result.retreatHours, 72);
      expect(result.passiveHours, 168);
      expect(result.passive.experience, 504);
      expect(result.experiencePoints, 720, reason: '216 闭关 + 504 普通挂机');
      expect(result.passive.mojianshi, 42);
      expect((await IsarSetup.currentSaveData())!.lastOnlineAt, completeAt);

      final expected = Character.create(
        name: 'single_apply_reference',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
        internalForce: 500,
      );
      final expectedAdvancement = CharacterAdvancementService.applyExperience(
        expected,
        result.experiencePoints,
        realmLookup: GameRepository.instance.getRealm,
        isLayerLocked: (tier, layer) => ProgressionGateService.isLayerLocked(
          nextTier: tier,
          nextLayer: layer,
          releaseCap: GameRepository.instance.numbers.progressionReleaseCap,
          realmLookup: GameRepository.instance.getRealm,
          innerDemonDef: GameRepository.instance.numbers.innerDemon,
          clearedStageIds: const {},
        ),
      );
      final character = await IsarSetup.instance.characters.get(kCharId);
      expect(character!.realmTier, expected.realmTier);
      expect(character.realmLayer, expected.realmLayer);
      expect(character.experience, expected.experience);
      expect(
        result.advancement?.layersGained,
        expectedAdvancement.layersGained,
        reason: '最终层位与余量必须等于合并经验单次入账',
      );
      expect(character.level, 77);
      expect(character.levelExp, 4321);

      final quantityBefore =
          (await IsarSetup.instance.inventoryItems.getByDefId(
            'item_mojianshi',
          ))!.quantity;
      await expectLater(
        () => service.completeRetreat(
          session: session,
          characterId: kCharId,
          config: GameRepository.instance.numbers.retreat,
          maps: GameRepository.instance.seclusionMaps,
          now: completeAt,
        ),
        throwsStateError,
      );
      expect(
        (await IsarSetup.instance.inventoryItems.getByDefId(
          'item_mojianshi',
        ))!.quantity,
        quantityBefore,
      );
    });

    test('收功后 session.status=completed + actualRewards 有 mojianshi', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );

      final completeAt = start.add(const Duration(hours: 4));
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: completeAt,
          );

      expect(out.mojianshi, greaterThan(0));

      final updated = await IsarSetup.instance.retreatSessions.get(session.id);
      expect(updated?.status, RetreatStatus.completed);
      expect(updated?.completedAt, completeAt);
      expect(updated?.actualRewards.isNotEmpty, isTrue);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.currentRetreatSessionId, isNull);
    });

    test('收功 merge 既有 item_mojianshi 行（防 defId 分裂回归）', () async {
      // 预先写入与 Phase2SeedService / tower drop 同体系的 defId='item_mojianshi'
      final now = DateTime(2026, 5, 12, 9, 0);
      final seeded = InventoryItem()
        ..defId = 'item_mojianshi'
        ..itemType = ItemType.moJianShi
        ..quantity = 10
        ..firstObtainedAt = now
        ..lastObtainedAt = now;
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.inventoryItems.put(seeded),
      );

      final start = DateTime(2026, 5, 12, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      // 必须仍只有 1 行 moJianShi（不能新建 'mojianshi' 那种分裂行）
      final all = await IsarSetup.instance.inventoryItems
          .filter()
          .itemTypeEqualTo(ItemType.moJianShi)
          .findAll();
      expect(all.length, 1, reason: '同 ItemType 不可分裂多 defId 行');
      expect(all.first.defId, 'item_mojianshi');
      expect(all.first.quantity, 10 + out.mojianshi);
    });

    test('收功后 InventoryItem.moJianShi 数量增加', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      await SeclusionService(isar: IsarSetup.instance).completeRetreat(
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

    test('收功后地图特色产出入库并写入 actualRewards', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.cangJingGe,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.sanLiu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );

      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.sanLiu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      expect(out.itemRewards['item_kaifeng_fucai'], 3);
      final fucai = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_kaifeng_fucai',
      );
      expect(fucai?.quantity, 3);
      expect(fucai?.itemType, ItemType.miscMaterial);
      final updated = await IsarSetup.instance.retreatSessions.get(session.id);
      expect(
        updated?.actualRewards
            .where((r) => r.rewardKey == 'item_kaifeng_fucai')
            .single
            .quantity,
        3,
      );
    });

    // W15 #30 第 2 期消费层接入 ──────────────────────────────────────────────

    test('收功后 Character.internalForce 累加 internalForcePoints', () async {
      // 把 fixture 角色 internalForce 重置低位 + max 抬高,留出累加空间
      await IsarSetup.instance.writeTxn(() async {
        final ch = await IsarSetup.instance.characters.get(kCharId);
        ch!.internalForce = 100;
        ch.internalForceMax = 10000;
        await IsarSetup.instance.characters.put(ch);
      });

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      expect(out.internalForcePoints, greaterThan(0));
      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.internalForce, 100 + out.internalForcePoints);
    });

    test('收功心法相生会检测第 2/3 辅修槽并注入内力产出', () async {
      await IsarSetup.instance.writeTxn(() async {
        final ch = (await IsarSetup.instance.characters.get(kCharId))!;
        ch.internalForce = 100;
        ch.internalForceMax = 10000;

        final main = Technique.create(
          defId: 'tech_lingqiao_menpai',
          ownerCharacterId: kCharId,
          tier: TechniqueTier.menPaiJueXue,
          school: TechniqueSchool.lingQiao,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026),
        )..id = 701;
        final miss = Technique.create(
          defId: 'tech_yinrou_changlian',
          ownerCharacterId: kCharId,
          tier: TechniqueTier.changLianGong,
          school: TechniqueSchool.yinRou,
          role: TechniqueRole.assist,
          learnedAt: DateTime(2026),
        )..id = 702;
        final hit = Technique.create(
          defId: 'tech_yinrou_menpai',
          ownerCharacterId: kCharId,
          tier: TechniqueTier.menPaiJueXue,
          school: TechniqueSchool.yinRou,
          role: TechniqueRole.assist,
          learnedAt: DateTime(2026),
        )..id = 703;
        await IsarSetup.instance.techniques.putAll([main, miss, hit]);

        ch.mainTechniqueId = main.id;
        ch.assistTechniqueIds = [miss.id, hit.id];
        await IsarSetup.instance.characters.put(ch);
      });

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      expect(
        out.internalForcePoints,
        22,
        reason: '第 2 辅修同 tier 命中同辈互补，20 点基础内力 ×1.10 = 22',
      );
      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.internalForce, 122);
    });

    test('收功后 Character.insightPoints 累加 techniqueLearnPoints', () async {
      // 山林 techniqueLearnRate=1.0,base=0.5/hr,xueTu scale=1.0
      // 4h → floor(0.5×1.0×4×1.0)=2,需要 cangJingGe 才更高
      // cangJingGe requiredRealm=sanLiu,先把 fixture 角色境界升上去
      await IsarSetup.instance.writeTxn(() async {
        final ch = await IsarSetup.instance.characters.get(kCharId);
        ch!.realmTier = RealmTier.sanLiu;
        await IsarSetup.instance.characters.put(ch);
      });

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.cangJingGe,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.sanLiu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final before = await IsarSetup.instance.characters.get(kCharId);
      final beforePts = before!.insightPoints;

      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.sanLiu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      expect(out.techniqueLearnPoints, greaterThan(0));
      final after = await IsarSetup.instance.characters.get(kCharId);
      expect(after?.insightPoints, beforePts + out.techniqueLearnPoints);
    });

    test('internalForce 累加 clamp 至 internalForceMax 上限', () async {
      // 把 fixture 内力顶到 max(500=500),收功后 internalForce 应仍为 max
      // (fixture setUp 默认 internalForce=500 internalForceMax=500,直接复用)
      //
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      expect(out.internalForcePoints, greaterThan(0), reason: '前置:闭关确实算出内力增长');
      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.internalForce, lessThanOrEqualTo(ch!.internalForceMax));
      expect(ch.internalForce, 500, reason: '结算时按升层前内力上限截断');
    });

    // W15 #30 第 3 期 experiencePoints 消费层接入 ───────────────────────────

    test('收功后 Character.experience 累加，心魔节点保留溢出经验', () async {
      // 50 + 80 后到达熟练；首个心魔阻止进入精通。
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final result = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 72)),
          );

      expect(result.experiencePoints, 216);
      expect(result.advancement, isNotNull);
      expect(result.advancement!.didAdvance, isTrue);
      // 216 EXP - 50 - 80 = 86，低于熟练层的 120 门槛。
      expect(result.advancement!.layersGained, 2);
      expect(result.advancement!.tierAfter, RealmTier.xueTu);
      expect(result.advancement!.layerAfter, RealmLayer.shuLian);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.realmLayer, RealmLayer.shuLian);
      expect(ch?.experience, 86);
      // shuLian yaml experience_to_next=120 / internalForceMax=700
      expect(ch?.experienceToNextLayer, 120);
      expect(ch?.internalForceMax, 700);
    });

    test('收功 EXP 累加但不足以升层 → advancement.didAdvance=false', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final result = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(minutes: 20)),
          );

      expect(result.experiencePoints, 1);
      expect(result.advancement, isNotNull);
      expect(result.advancement!.didAdvance, isFalse);
      expect(result.advancement!.layersGained, 0);

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.experience, 1, reason: 'EXP 累加但不升层');
      expect(ch?.realmLayer, RealmLayer.qiMeng);
      expect(ch?.internalForceMax, 500);
    });

    // ── P1.y · step 6 hook ─────────────────────────────────────────

    test('Lv100 发布上限阻止旧档继续升层，tutorialStep 不推进', () async {
      await IsarSetup.instance.writeTxn(() async {
        final ch = await IsarSetup.instance.characters.get(kCharId);
        ch!
          ..realmTier = RealmTier.erLiu
          ..realmLayer = RealmLayer.dengFeng
          ..experience = 9100
          ..experienceToNextLayer = 9500;
        await IsarSetup.instance.characters.put(ch);
      });

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.erLiu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      await SeclusionService(isar: IsarSetup.instance).completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.erLiu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 4)),
      );

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.realmTier, RealmTier.erLiu, reason: '高于发布上限的旧档保留当前境界');
      expect(ch?.realmLayer, RealmLayer.dengFeng);

      final tutorialSvc = TutorialService(IsarSetup.instance);
      expect(
        await tutorialSvc.getCurrentStep(),
        0,
        reason: '未进入一流，不触发未来内容的 step 6',
      );
    });

    test('Lv100 发布上限对 disciple 同样生效', () async {
      await IsarSetup.instance.writeTxn(() async {
        final ch = await IsarSetup.instance.characters.get(kCharId);
        ch!
          ..realmTier = RealmTier.erLiu
          ..realmLayer = RealmLayer.dengFeng
          ..experience = 9100
          ..experienceToNextLayer = 9500
          ..lineageRole = LineageRole.disciple;
        await IsarSetup.instance.characters.put(ch);
      });

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.erLiu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      await SeclusionService(isar: IsarSetup.instance).completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.erLiu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 4)),
      );

      final ch = await IsarSetup.instance.characters.get(kCharId);
      expect(ch?.realmTier, RealmTier.erLiu);
      expect(ch?.realmLayer, RealmLayer.dengFeng);

      final tutorialSvc = TutorialService(IsarSetup.instance);
      expect(await tutorialSvc.getCurrentStep(), 0, reason: '未进入一流，不触发 step 6');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // abandonRetreat
  // ─────────────────────────────────────────────────────────────────────────

  group('abandonRetreat', () {
    test('abandon 后 status=abandoned + 不发奖 + character id 清零', () async {
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: DateTime(2026, 5, 11, 10, 0),
          );
      await SeclusionService(isar: IsarSetup.instance).abandonRetreat(
        session: session,
        characterId: kCharId,
        now: DateTime(2026, 5, 11, 11, 0),
      );

      final updated = await IsarSetup.instance.retreatSessions.get(session.id);
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
  // C-W14-2:idle tick hook 喂 biome/weather 累计给奇遇
  // ─────────────────────────────────────────────────────────────────────────

  group('C-W14-2 idle tick → EncounterProgress', () {
    test('完成 4 小时闭关 → 喂 biome/weather × 240min', () async {
      final encSvc = EncounterService(isar: IsarSetup.instance);
      final svc = SeclusionService(
        isar: IsarSetup.instance,
        encounterService: encSvc,
      );
      // numbers.yaml 已配 shanLin biome=mountainForest weather=clear,
      // 但 weather=clear 也会被喂(只要 biome/weather 任一非 null)
      final session = await svc.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime(2026, 5, 14, 12, 0),
      );

      await svc.completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        // 4h 整满
        now: DateTime(2026, 5, 14, 16, 0),
      );

      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(kSaveDataId)
          .findFirst();
      expect(p, isNotNull, reason: 'idle tick 应 ensure getOrCreate');
      expect(p!.biomeMinutes.minutesOf(EncounterBiome.mountainForest), 240);
      expect(p.weatherMinutes.minutesOf(EncounterWeather.clear), 240);
    });

    test('encounterService=null → 无 idle tick 副作用', () async {
      // 不注入 encounterService(默认 null)
      final svc = SeclusionService(isar: IsarSetup.instance);
      final session = await svc.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime(2026, 5, 14, 12, 0),
      );
      await svc.completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime(2026, 5, 14, 13, 0),
      );
      // EncounterProgress 行根本未创建(idle tick 短路)
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(kSaveDataId)
          .findFirst();
      expect(p, isNull, reason: 'encounterService 未注入 → idle tick 短路');
    });

    test('actualHours=0(start 与 now 同刻)→ 无 idle tick', () async {
      final encSvc = EncounterService(isar: IsarSetup.instance);
      final svc = SeclusionService(
        isar: IsarSetup.instance,
        encounterService: encSvc,
      );
      final start = DateTime(2026, 5, 14, 12, 0);
      final session = await svc.startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 4,
        saveDataId: kSaveDataId,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: start,
      );
      // 立即收功(actualHours = 0)
      await svc.completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start,
      );
      final p = await IsarSetup.instance.encounterProgress
          .filter()
          .saveDataIdEqualTo(kSaveDataId)
          .findFirst();
      // actualHours=0 → minutes=0 → _feedEncounterIdleMinutes 短路,
      // 不会调 getOrCreate → 进度未建
      expect(p, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 隔离性：与 TowerProgress / MainlineProgress 无交叉
  // ─────────────────────────────────────────────────────────────────────────

  group('saveDataId 隔离', () {
    test('saveDataId=2 的 session 不干扰 saveDataId=1', () async {
      await SeclusionService(isar: IsarSetup.instance).startRetreat(
        mapType: RetreatMapType.shanLin,
        durationHours: 1,
        saveDataId: 2,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        maps: GameRepository.instance.seclusionMaps,
        now: DateTime.now(),
      );
      final active1 = await SeclusionService(
        isar: IsarSetup.instance,
      ).getActiveSession(1);
      expect(active1, isNull, reason: 'saveDataId=1 应无 active session');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // B1 根因A:闭关挂机喂出战装备 battleCount(人剑合一离线推进)
  // ─────────────────────────────────────────────────────────────────────────
  group('B1 闭关喂共鸣度 battleCount(根因A)', () {
    Future<int> seedEquippedWeapon() async {
      final eq = Equipment.create(
        defId: 'weapon_test',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        obtainedAt: DateTime(2026, 1, 1),
        obtainedFrom: 'test',
        battleCount: 0,
      );
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.equipments.put(eq),
      );
      final ch = await IsarSetup.instance.characters.get(kCharId);
      ch!.equippedWeaponId = eq.id;
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.characters.put(ch),
      );
      return eq.id;
    }

    test('闭关 10h → 出战武器 battleCount += floor(10 × 5)=50', () async {
      final eqId = await seedEquippedWeapon();
      final rate =
          GameRepository.instance.numbers.resonanceSeclusionBattleCountPerHour;
      expect(rate, 5, reason: 'numbers.yaml seclusion_battle_count_per_hour');

      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 10,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      await SeclusionService(isar: IsarSetup.instance).completeRetreat(
        session: session,
        characterId: kCharId,
        charRealmTier: RealmTier.xueTu,
        config: GameRepository.instance.numbers.retreat,
        maps: GameRepository.instance.seclusionMaps,
        now: start.add(const Duration(hours: 10)),
      );

      final eq = await IsarSetup.instance.equipments.get(eqId);
      expect(eq?.battleCount, 50, reason: 'floor(10h × 5/h)');
    });

    test('未装备时不报错(equippedWeaponId=null skip)', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      // 不抛即通过
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );
      expect(out.actualHours, 4);
    });

    // P4 材料经济 P1：completeRetreat 入库银两 ────────────────────────────────

    test('收功后 item_silver 数量等于 computeOutputs.silver', () async {
      final start = DateTime(2026, 5, 11, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );

      final completeAt = start.add(const Duration(hours: 4));
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: completeAt,
          );

      expect(out.silver, greaterThan(0));

      final item = await IsarSetup.instance.inventoryItems
          .filter()
          .itemTypeEqualTo(ItemType.silver)
          .findFirst();
      expect(item, isNotNull, reason: 'item_silver 应入库');
      expect(item!.defId, 'item_silver');
      expect(item.quantity, out.silver);
    });

    test('收功 merge 既有 item_silver 行（防 defId 分裂回归）', () async {
      final now = DateTime(2026, 5, 12, 9, 0);
      final seeded = InventoryItem()
        ..defId = 'item_silver'
        ..itemType = ItemType.silver
        ..quantity = 100
        ..firstObtainedAt = now
        ..lastObtainedAt = now;
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.inventoryItems.put(seeded),
      );

      final start = DateTime(2026, 5, 12, 10, 0);
      final session = await SeclusionService(isar: IsarSetup.instance)
          .startRetreat(
            mapType: RetreatMapType.shanLin,
            durationHours: 4,
            saveDataId: kSaveDataId,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            maps: GameRepository.instance.seclusionMaps,
            now: start,
          );
      final out = await SeclusionService(isar: IsarSetup.instance)
          .completeRetreat(
            session: session,
            characterId: kCharId,
            charRealmTier: RealmTier.xueTu,
            config: GameRepository.instance.numbers.retreat,
            maps: GameRepository.instance.seclusionMaps,
            now: start.add(const Duration(hours: 4)),
          );

      // 必须仍只有 1 行 silver（不能分裂多 defId）
      final all = await IsarSetup.instance.inventoryItems
          .filter()
          .itemTypeEqualTo(ItemType.silver)
          .findAll();
      expect(all.length, 1, reason: '同 ItemType.silver 不可分裂多 defId 行');
      expect(all.first.defId, 'item_silver');
      expect(all.first.quantity, 100 + out.silver);
    });
  });
}
