import '../../../data/defs/drop_entry.dart';
import '../../../data/defs/stage_def.dart' show EnemyDef;
import '../../../data/models/enums.dart';

/// 爬塔层配置（Phase 3 T40，GDD §8.2 + CLAUDE §7）。
///
/// 与 [StageDef] 故意**不共享父类 / 不共享 yaml schema**：
///   - 主线按章节 + prevStageId 链解锁，爬塔按 floorIndex 单调递增解锁
///   - 主线奖励配 dropEquipmentDefIds / dropItemDefIds（Phase 1 旧字段保留），
///     爬塔只走 [dropTable]（Phase 2 T27 sealed DropEntry）
///   - 主线允许 enemyTeam 空（剧情关），爬塔每层必须 1-3 个敌人
///
/// 30 层数值曲线（phase3_tasks T40 拍板）：
///   - 1-5 学徒 / 6-10 三流 / 11-15 二流 / 16-20 一流 / 21-25 绝顶 / 26-30 宗师
///   - 普通层 HP 800→12000 线性插值；普通层攻 200→2500
///   - Boss 层在该阶巅峰 HP/攻 ×1.5
///
/// 数值红线（[GameRepository._enforceRedLines] 校验）：
///   - 普伤 ≤ 8000、Boss HP ≤ 50000、玩家血 ≤ 20000、内力 ≤ 15000
///   - floorIndex ∈ [1, 30] 唯一且连续
///   - bossKind 仅在 5/10/15/20/25/30 层非 null
///   - 普通层 narrativeOpeningId / narrativeVictoryId 必须为 null
class TowerFloorDef {
  /// 层号，1-30，唯一且连续（[GameRepository._enforceRedLines] 校验）。
  final int floorIndex;

  /// 推荐境界，仅用于 UI 提示（**不做硬挡**：挑战自由，难度自然惩罚）。
  final RealmTier requiredRealm;

  /// 敌人队伍，1-3 个；Boss 层固定 1 个但 HP/攻拉满。
  final List<EnemyDef> enemyTeam;

  /// Boss 类型；null 表示普通层。
  /// minor → 5/15/25 层；major → 10/20/30 层。
  final TowerBossKind? bossKind;

  /// 进入 Boss 层时播放的开场剧情 id；普通层必须为 null。
  /// 联结 `data/narratives/<id>.yaml`，缺文件由 [NarrativeLoader] 兜底。
  final String? narrativeOpeningId;

  /// Boss 层战胜后播放的剧情 id；普通层必须为 null。战败不触发。
  final String? narrativeVictoryId;

  /// 掉落表（Phase 2 T27 sealed DropEntry），由 [DropService.rollTowerRewards] 消费。
  /// **重打不发奖**（[TowerProgressService.recordClear] 返回 isFirstClear 控制）。
  final List<DropEntry> dropTable;

  const TowerFloorDef({
    required this.floorIndex,
    required this.requiredRealm,
    required this.enemyTeam,
    this.bossKind,
    this.narrativeOpeningId,
    this.narrativeVictoryId,
    this.dropTable = const [],
  });

  /// 是否为 Boss 层（任意 minor / major）。
  bool get isBoss => bossKind != null;

  factory TowerFloorDef.fromYaml(Map<String, dynamic> y) {
    return TowerFloorDef(
      floorIndex: (y['floorIndex'] as num).toInt(),
      requiredRealm: RealmTier.values.byName(y['requiredRealm'] as String),
      enemyTeam: ((y['enemyTeam'] as List?) ?? const [])
          .map((e) => EnemyDef.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      bossKind: y['bossKind'] == null
          ? null
          : TowerBossKind.values.byName(y['bossKind'] as String),
      narrativeOpeningId: y['narrativeOpeningId'] as String?,
      narrativeVictoryId: y['narrativeVictoryId'] as String?,
      dropTable: ((y['dropTable'] as List?) ?? const [])
          .map((e) => DropEntry.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }

  @override
  String toString() =>
      'TowerFloorDef(floor=$floorIndex, '
      'realm=${requiredRealm.name}, '
      'boss=${bossKind?.name ?? "-"}, enemies=${enemyTeam.length})';
}
