/// 存档槽只读摘要快照(给存档选择屏用)。
///
/// 纯只读值对象,不写库、不新增 schema 字段(spec B §3.4):祖师名/境界/主线进度/
/// 最后游玩均从 SaveData + Character + MainlineProgress 现成字段派生。空槽用
/// [SlotSummary.empty]。
class SlotSummary {
  const SlotSummary({
    required this.slotId,
    required this.isEmpty,
    this.slotName,
    this.founderName,
    this.realmDisplay,
    this.chapterIndex = 0,
    this.clearedStageCount = 0,
    this.highestTowerFloor = 0,
    this.lastPlayed,
    this.isMostRecent = false,
  });

  /// 槽号(1/2/3)。
  final int slotId;

  /// 是否空槽(db 文件不存在 或 无 founder)。
  final bool isEmpty;

  /// 玩家自定义存档名(空槽或未命名为 null)。
  final String? slotName;

  /// 祖师名(空槽为 null)。
  final String? founderName;

  /// 祖师境界显示名,如「武圣登峰」(空槽为 null)。
  final String? realmDisplay;

  /// 主线当前焦点章节(空槽 0)。
  final int chapterIndex;

  /// 已通关主线关卡数(空槽 0)。
  final int clearedStageCount;

  /// 问鼎江湖最高通关层数(空槽 0)。
  final int highestTowerFloor;

  /// 最后游玩时间(取 SaveData.lastOnlineAt;空槽 null)。
  final DateTime? lastPlayed;

  /// 是否为所有非空槽里最近游玩的一档。
  final bool isMostRecent;

  factory SlotSummary.empty(int slotId) =>
      SlotSummary(slotId: slotId, isEmpty: true);

  SlotSummary copyWith({String? slotName, bool? isMostRecent}) => SlotSummary(
    slotId: slotId,
    isEmpty: isEmpty,
    slotName: slotName ?? this.slotName,
    founderName: founderName,
    realmDisplay: realmDisplay,
    chapterIndex: chapterIndex,
    clearedStageCount: clearedStageCount,
    highestTowerFloor: highestTowerFloor,
    lastPlayed: lastPlayed,
    isMostRecent: isMostRecent ?? this.isMostRecent,
  );
}
