import 'drop_entry.dart';
import 'stage_def.dart' show EnemyDef;
import '../../core/domain/enums.dart';

/// 爬塔层配置（Phase 3 T40，GDD §8.2 + CLAUDE §7）。
///
/// 与 [StageDef] 故意**不共享父类 / 不共享 yaml schema**：
///   - 主线按章节 + prevStageId 链解锁，爬塔按 floorIndex 单调递增解锁
///   - 主线与爬塔奖励均只走 [dropTable]（Phase 2 T27 sealed DropEntry；
///     F5/2026-06-23 删主线 Phase 1 占位字段 dropEquipmentDefIds / dropItemDefIds）
///   - 主线允许 enemyTeam 空（剧情关），爬塔每层必须 1-3 个敌人
///
/// 49 层数值曲线（批 A · 1:1 锚死，spec 2026-08-01 §7）：
///   - floor N ↔ 境界绝对层 N，每 tier 7 层：学徒 1-7 / 三流 8-14 / 二流 15-21 /
///     一流 22-28 / 绝顶 29-35 / 宗师 36-42 / 武圣 43-49
///   - 普通敌单体 hp/atk/spd 对齐主线 stages.yaml 同 (tier,layer) 实测中位
///   - Boss 层以主 Boss 为核心；大 Boss 层可带护卫/护法形成多目标压力
///
/// 数值红线（[GameRepository._enforceRedLines] 校验）：
///   - 普伤 ≤ 8000、Boss HP ≤ 60000（§5.4，2026-06-14 调）、玩家血 ≤ 20000、内力 ≤ 15000
///   - floorIndex 从 1 起唯一连续；层数 ≤ 境界总层数 49（1:1 锚死上界）
///   - bossKind 按结构规则：tier 中点（4/11/18/25/32/39/46）minor、
///     tier 末层（7/14/21/28/35/42/49）major，其余必须 null
///   - 普通层 narrativeOpeningId / narrativeVictoryId 必须为 null
///   - requiredRealm ≤ 该层敌人境界（拍板 #8，防掉落阶提前发放）
///   - baseExpReward ≥ 0
class TowerFloorDef {
  /// 层号，从 1 起唯一连续（[GameRepository._enforceRedLines] 校验）。
  final int floorIndex;

  /// 推荐境界，仅用于 UI 提示（**不做硬挡**：挑战自由，难度自然惩罚）。
  final RealmTier requiredRealm;

  /// 敌人队伍，1-3 个；Boss 层至少 1 个主 Boss，后段可带护法。
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

  /// 通关基础经验奖励（W15 #30 第 3 期；批 A 扩 49 层重定曲线）。
  ///
  /// 曲线：普通层按 tier 递增 8→32 / 小 Boss ≈ 普通 ×2.5 / 大 Boss ≈ 普通 ×3。
  /// 塔承担「中盘 layer 推进主力」，与主线开局 + 闭关挂机长尾形成 3 系互补；
  /// 总量由 A5 balance 探针复校。重打不发奖由
  /// [TowerProgressService.recordClear] 控制(isFirstClear)。
  final int baseExpReward;

  /// M4 Stage 3 美术(2026-05-21):战斗屏场景背景 png 路径。
  /// null 时 battle_screen 走 backgroundColor 兜底。
  final String? sceneBackgroundPath;

  /// 可玩性 P1a:爬塔 Boss 残页(spec §二)。仅 bossKind != null 层可配 · null=不掉。
  /// 每次 Boss 胜利 rng 掉 1 残页(非首通限定,重复刷集残页 grind)。
  final String? dropSkillFragmentId;

  const TowerFloorDef({
    required this.floorIndex,
    required this.requiredRealm,
    required this.enemyTeam,
    this.bossKind,
    this.narrativeOpeningId,
    this.narrativeVictoryId,
    this.dropTable = const [],
    this.baseExpReward = 0,
    this.sceneBackgroundPath,
    this.dropSkillFragmentId,
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
      baseExpReward: (y['baseExpReward'] as num?)?.toInt() ?? 0,
      sceneBackgroundPath: y['sceneBackgroundPath'] as String?,
      dropSkillFragmentId: y['dropSkillFragmentId'] as String?,
    );
  }

  @override
  String toString() =>
      'TowerFloorDef(floor=$floorIndex, '
      'realm=${requiredRealm.name}, '
      'boss=${bossKind?.name ?? "-"}, enemies=${enemyTeam.length}, '
      'exp=$baseExpReward)';
}
