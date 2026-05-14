import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../data/defs/seclusion_map_def.dart';
import '../data/models/character.dart';
import '../data/models/enums.dart';
import '../data/models/equipment.dart';
import '../data/models/inventory_item.dart';
import '../data/models/retreat_session.dart';
import '../data/models/reward_entry.dart';
import '../data/numbers_config.dart';
import '../utils/rng.dart';
import 'encounter_service.dart';

/// 闭关产出汇总（Phase 3 T48）。
///
/// 由 [SeclusionService.computeOutputs] 返回，[completeRetreat] 写入 Isar。
typedef RetreatOutputs = ({
  double actualHours,
  int mojianshi,
  List<Equipment> equipmentDrops,
  int experiencePoints,
});

/// 闭关系统服务（Phase 3 T48）。
///
/// 全静态方法，依赖注入 [RetreatConfig] + [Rng]（测试可 mock）。
/// 与 [TowerProgressService] / [MainlineProgressService] 完全独立：
/// 不互相 import，saveDataId 隔离。
///
/// 关键不变量：
///   - 同一 saveDataId 至多一条 active session；[startRetreat] 开始前
///     先调 [_abandonActive]（内部方法）
///   - [computeOutputs] 纯函数（不写 Isar），由 [completeRetreat] 调用
///   - actualHours = min(elapsed, durationHours, capHours)
///   - mojianshi = floor(perHour × actualHours × realmScale × dayBonus)
///   - 装备抽检：per session 单次，概率 = equipmentDropRate × baseEquipDropProbability
class SeclusionService {
  const SeclusionService({
    required this.isar,
    this.encounterService,
  });

  final Isar isar;

  /// 奇遇服务(C-W14-2)。null = 不喂 biome/weather 累计(测试 fixture 默认)。
  /// 生产路径 provider 注入,完成闭关后按 `actualHours × 60` 喂分钟。
  final EncounterService? encounterService;

  // ─────────────────────────────────────────────────────────────────────────
  // 公开 API
  // ─────────────────────────────────────────────────────────────────────────

  /// 当前存档是否可以进入指定地图（境界锁）。
  ///
  /// [charRealmTier] 为角色当前大阶。
  ///
  /// 纯函数：不用 Isar,保持 static。
  static bool canEnterMap({
    required RetreatMapType mapType,
    required RealmTier charRealmTier,
    required List<SeclusionMapDef> maps,
  }) {
    final def = _getDef(mapType, maps);
    return charRealmTier.index >= def.requiredRealm.index;
  }

  /// 取当前 active session；无活跃 session 返回 null。
  Future<RetreatSession?> getActiveSession(int saveDataId) async {
    return isar.retreatSessions
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .statusEqualTo(RetreatStatus.active)
        .findFirst();
  }

  /// 开始闭关：
  ///   1. 境界校验（不满足抛 [StateError]）
  ///   2. abandon 旧 active session（若有）
  ///   3. 写新 [RetreatSession] + 更新 [Character.currentRetreatSessionId]
  Future<RetreatSession> startRetreat({
    required RetreatMapType mapType,
    required int durationHours,
    required int saveDataId,
    required int characterId,
    required RealmTier charRealmTier,
    required List<SeclusionMapDef> maps,
    required DateTime now,
  }) async {
    if (!canEnterMap(
      mapType: mapType,
      charRealmTier: charRealmTier,
      maps: maps,
    )) {
      throw StateError(
        '境界不足：${charRealmTier.name} 无法进入 ${mapType.name}（'
        '要求 ${_getDef(mapType, maps).requiredRealm.name}）',
      );
    }

    late RetreatSession created;

    await isar.writeTxn(() async {
      // 1. abandon 旧 active（若有）
      final old = await isar.retreatSessions
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .statusEqualTo(RetreatStatus.active)
          .findFirst();
      if (old != null) {
        old.status = RetreatStatus.abandoned;
        old.completedAt = now;
        await isar.retreatSessions.put(old);
      }

      // 2. 建新 session
      final session = RetreatSession()
        ..saveDataId = saveDataId
        ..mapType = mapType
        ..durationHours = durationHours
        ..startedAt = now
        ..completedAt = null
        ..status = RetreatStatus.active
        ..actualRewards = [];
      final sid = await isar.retreatSessions.put(session);
      session.id = sid;
      created = session;

      // 3. 更新 character.currentRetreatSessionId
      final ch = await isar.characters.get(characterId);
      if (ch != null) {
        ch.currentRetreatSessionId = sid;
        await isar.characters.put(ch);
      }
    });

    return created;
  }

  /// 计算闭关产出（纯函数，不写 Isar）。
  ///
  /// [now] 为当前时刻，[config] 来自 GameRepository.numbers.retreat。
  static RetreatOutputs computeOutputs({
    required RetreatSession session,
    required RealmTier charRealmTier,
    required RetreatConfig config,
    required List<SeclusionMapDef> maps,
    required DateTime now,
    Rng? rng,
  }) {
    final def = _getDef(session.mapType, maps);
    final elapsed = now.difference(session.startedAt).inSeconds / 3600.0;
    final cap = config.capHours.toDouble();
    final planned = session.durationHours.toDouble();
    final actualHours = _clamp(elapsed, 0, _min(planned, cap));

    final scale = config.realmScaleFor(charRealmTier);
    final dayBonus = _timeDayBonus(session.startedAt);

    final mojianshi = (def.mojianshiPerHour * actualHours * scale * dayBonus)
        .floor()
        .clamp(0, 999999);

    final experiencePoints =
        (def.experiencePerHour * actualHours * scale).floor().clamp(0, 999999);

    // 装备抽检：每 session 单次，概率 = equipmentDropRate × base
    final effectiveRng = rng ?? DefaultRng();
    final equipRoll = effectiveRng.nextDouble();
    final equipProb = def.equipmentDropRate * config.baseEquipDropProbability;
    final equipDrops = <Equipment>[];
    if (equipRoll < equipProb) {
      // Demo 阶段：无独立 seclusion dropTable，概率触发但无 table 时不崩溃
      // Phase 4 补全 dropTable 时替换此路径
    }

    return (
      actualHours: actualHours,
      mojianshi: mojianshi,
      equipmentDrops: equipDrops,
      experiencePoints: experiencePoints,
    );
  }

  /// 收功：
  ///   1. 计算产出
  ///   2. 写 mojianshi 进 InventoryItem
  ///   3. 更新 session：completedAt / status / actualRewards
  ///   4. 清 Character.currentRetreatSessionId
  Future<RetreatOutputs> completeRetreat({
    required RetreatSession session,
    required int characterId,
    required RealmTier charRealmTier,
    required RetreatConfig config,
    required List<SeclusionMapDef> maps,
    required DateTime now,
    Rng? rng,
  }) async {
    final outputs = computeOutputs(
      session: session,
      charRealmTier: charRealmTier,
      config: config,
      maps: maps,
      now: now,
      rng: rng,
    );

    await isar.writeTxn(() async {
      // 1. 写 mojianshi → InventoryItem
      // defId 统一为 'item_mojianshi'，与 towers.yaml / stages.yaml drop 体系
      // 及 tower_entry_flow._itemTypeOf 映射对齐，避免同 ItemType 多 defId 分裂。
      if (outputs.mojianshi > 0) {
        await _addInventoryItem(
          isar,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: outputs.mojianshi,
          now: now,
        );
      }

      // 2. 更新 session
      final rewards = <RewardEntry>[];
      if (outputs.mojianshi > 0) {
        rewards.add(RewardEntry()
          ..rewardKey = 'item_mojianshi'
          ..quantity = outputs.mojianshi);
      }
      session
        ..completedAt = now
        ..status = RetreatStatus.completed
        ..actualRewards = rewards;
      await isar.retreatSessions.put(session);

      // 3. 清 character.currentRetreatSessionId
      final ch = await isar.characters.get(characterId);
      if (ch != null) {
        ch.currentRetreatSessionId = null;
        await isar.characters.put(ch);
      }
    });

    // C-W14-2 idle tick:writeTxn 外单独喂奇遇 biome/weather 累计。
    // 嵌套 writeTxn 会抛 IsarError,故分开两个 txn。原子性损失可接受:
    // mojianshi 已落地,idle tick 失败仅缺少奇遇累计,不破坏闭关数据。
    await _feedEncounterIdleMinutes(
      session: session,
      saveDataId: session.saveDataId,
      maps: maps,
      actualHours: outputs.actualHours,
    );

    return outputs;
  }

  /// 闭关 actualHours 累计喂给 EncounterService(C-W14-2)。
  ///
  /// 异常静默 + debugPrint(W13 教训:catch 加日志,不影响主流程)。
  Future<void> _feedEncounterIdleMinutes({
    required RetreatSession session,
    required int saveDataId,
    required List<SeclusionMapDef> maps,
    required double actualHours,
  }) async {
    final svc = encounterService;
    if (svc == null) return;
    if (actualHours <= 0) return;
    final def = _getDef(session.mapType, maps);
    if (def.biome == null && def.weather == null) return;
    final minutes = (actualHours * 60).floor();
    if (minutes <= 0) return;
    try {
      await svc.getOrCreate(saveDataId: saveDataId);
      await svc.recordIdleMinutes(
        saveDataId: saveDataId,
        biome: def.biome,
        weather: def.weather,
        minutes: minutes,
      );
    } catch (e, st) {
      debugPrint('SeclusionService.idle tick failed: $e\n$st');
    }
  }

  /// 放弃闭关（切换地图 / 主动放弃）：仅更新状态，不发奖。
  Future<void> abandonRetreat({
    required RetreatSession session,
    required int characterId,
    required DateTime now,
  }) async {
    await isar.writeTxn(() async {
      session
        ..completedAt = now
        ..status = RetreatStatus.abandoned;
      await isar.retreatSessions.put(session);

      final ch = await isar.characters.get(characterId);
      if (ch != null) {
        ch.currentRetreatSessionId = null;
        await isar.characters.put(ch);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 内部工具
  // ─────────────────────────────────────────────────────────────────────────

  static SeclusionMapDef _getDef(
    RetreatMapType mapType,
    List<SeclusionMapDef> maps,
  ) =>
      maps.firstWhere(
        (m) => m.mapType == mapType,
        orElse: () =>
            throw StateError('SeclusionMapDef 未找到: ${mapType.name}'),
      );

  /// 时辰加成（只影响磨剑石/经验，子时×1.2，其余×1.0；Demo 阶段简化）。
  static double _timeDayBonus(DateTime startedAt) {
    final h = startedAt.hour;
    // 子时 23:00-01:00（含）
    if (h == 23 || h == 0) return 1.2;
    return 1.0;
  }

  static double _min(double a, double b) => a < b ? a : b;

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static Future<void> _addInventoryItem(
    Isar isar, {
    required String defId,
    required ItemType itemType,
    required int quantity,
    required DateTime now,
  }) async {
    final existing = await isar.inventoryItems.getByDefId(defId);
    if (existing != null) {
      existing.quantity += quantity;
      existing.lastObtainedAt = now;
      await isar.inventoryItems.put(existing);
    } else {
      final item = InventoryItem()
        ..defId = defId
        ..itemType = itemType
        ..quantity = quantity
        ..firstObtainedAt = now
        ..lastObtainedAt = now;
      await isar.inventoryItems.put(item);
    }
  }
}
