/// 活动种类（闭关/百草岭/断魂庄）。
enum ActivityKind { retreat, expedition, bossGauntlet }

/// 单个活动会话的占用/保留条目。
class ActivityOccupancyEntry {
  const ActivityOccupancyEntry({
    required this.kind,
    required this.runId,
    required this.characterIds,
    required this.equipmentIds,
    required this.techniqueIds,
  });

  final ActivityKind kind;

  /// 会话 Isar id；闭关无独立 run 概念时为 null。
  final int? runId;

  final Set<int> characterIds;
  final Set<int> equipmentIds;
  final Set<int> techniqueIds;
}

/// 统一活动保留上下文（companion §3.5/§8.1 Q5）。唯一对外占用查询结果，
/// 出战编成、所有战斗入口、装备强化/助炼/分解/开锋、心法研习/装配均消费此结果。
class ActivityOccupancy {
  const ActivityOccupancy(this.entries);

  final List<ActivityOccupancyEntry> entries;

  static const ActivityOccupancy empty = ActivityOccupancy(
    <ActivityOccupancyEntry>[],
  );

  Set<int> get occupiedCharacterIds => {
    for (final e in entries) ...e.characterIds,
  };

  /// 装备批 `EquipmentAidService.isCandidateEligible(reservedEquipmentIds:)` 直接消费。
  Set<int> get reservedEquipmentIds => {
    for (final e in entries) ...e.equipmentIds,
  };

  Set<int> get reservedTechniqueIds => {
    for (final e in entries) ...e.techniqueIds,
  };

  bool isCharacterOccupied(int id) => occupiedCharacterIds.contains(id);

  /// 该角色所属活动（供 UI「远征中未随行」提示）；未占用返回 null。
  ActivityKind? activityOf(int characterId) {
    for (final e in entries) {
      if (e.characterIds.contains(characterId)) return e.kind;
    }
    return null;
  }
}
