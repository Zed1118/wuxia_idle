import 'package:isar/isar.dart';

import '../data/defs/seclusion_map_def.dart';
import '../data/isar_setup.dart';
import '../data/models/character.dart';
import '../data/models/enums.dart';
import '../data/models/equipment.dart';
import '../data/models/inventory_item.dart';
import '../data/models/retreat_session.dart';
import '../data/models/reward_entry.dart';
import '../data/numbers_config.dart';
import '../utils/rng.dart';

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
  SeclusionService._();

  // ─────────────────────────────────────────────────────────────────────────
  // 公开 API
  // ─────────────────────────────────────────────────────────────────────────

  /// 当前存档是否可以进入指定地图（境界锁）。
  ///
  /// [charRealmTier] 为角色当前大阶。
  static bool canEnterMap({
    required RetreatMapType mapType,
    required RealmTier charRealmTier,
    required List<SeclusionMapDef> maps,
  }) {
    final def = _getDef(mapType, maps);
    return charRealmTier.index >= def.requiredRealm.index;
  }

  /// 取当前 active session；无活跃 session 返回 null。
  static Future<RetreatSession?> getActiveSession(int saveDataId) async {
    return IsarSetup.instance.retreatSessions
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .statusEqualTo(RetreatStatus.active)
        .findFirst();
  }

  /// 开始闭关：
  ///   1. 境界校验（不满足抛 [StateError]）
  ///   2. abandon 旧 active session（若有）
  ///   3. 写新 [RetreatSession] + 更新 [Character.currentRetreatSessionId]
  static Future<RetreatSession> startRetreat({
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

    final isar = IsarSetup.instance;
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
  static Future<RetreatOutputs> completeRetreat({
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

    final isar = IsarSetup.instance;

    await isar.writeTxn(() async {
      // 1. 写 mojianshi → InventoryItem
      if (outputs.mojianshi > 0) {
        await _addInventoryItem(
          isar,
          defId: 'mojianshi',
          itemType: ItemType.moJianShi,
          quantity: outputs.mojianshi,
          now: now,
        );
      }

      // 2. 更新 session
      final rewards = <RewardEntry>[];
      if (outputs.mojianshi > 0) {
        rewards.add(RewardEntry()
          ..rewardKey = 'mojianshi'
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

    return outputs;
  }

  /// 放弃闭关（切换地图 / 主动放弃）：仅更新状态，不发奖。
  static Future<void> abandonRetreat({
    required RetreatSession session,
    required int characterId,
    required DateTime now,
  }) async {
    final isar = IsarSetup.instance;
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
    final existing = await isar.inventoryItems
        .filter()
        .defIdEqualTo(defId)
        .findFirst();
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
