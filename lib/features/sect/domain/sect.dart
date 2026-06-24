import 'package:isar_community/isar.dart';

part 'sect.g.dart';

/// 门派事件类型(P3.4 §12.1 default 决议 · Demo ship `tournament` 一种,
/// `mission` / `crisis` 留 1.0 扩展接口)。
enum SectEventType { tournament, mission, crisis }

/// 门派事件状态机(pending → resolved | expired)。
///
/// - `pending`:已触发未应战
/// - `resolved`:战斗已结算(win/loss 写入 `reputationDelta`)
/// - `expired`:超 `expire_days`(默认 7d)未应战 → reputation -5
enum SectEventStatus { pending, resolved, expired }

/// 门派实体(P3.4 §12.1 default 决议 · spec p3_4_sect_event_spec_2026-05-24 §2)。
///
/// Q1.A 玩家自建门派 / Q3.A `sectReputation` 字段名独立 P1.2 `reputation` 不冲突 /
/// Q4.B 否 sect_building 纯抽象 `sectLevel` int 沿七阶 / Q5.B `founderId` 弱挂
/// `LineageMember.id` 不强校验(Demo 单玩家路径无跨表 cascade)。
@collection
class Sect {
  Id id = Isar.autoIncrement;

  late String name;

  /// 弱挂 LineageMember.id(Q5.B · 不强校验 referential integrity)。
  late int founderId;

  /// 1-7 沿 §5.3 三系锁死的七阶抽象(Q4.B · 不开实体 sect_building 子系统)。
  late int sectLevel;

  /// 0-100 独立轴(Q3.A · 字段名 ≠ P1.2 character.reputation,decay timer 独立 30d cycle)。
  late int sectReputation;

  /// 累计 tournament 胜场,驱动 `sectLevel` 升级(每 `promote_wins_threshold` 胜 → +1)。
  late int totalWins;

  late DateTime createdAt;

  /// cooldown 锚 + decay 30 天起算点;null = 从未触发过 event(初创态)。
  DateTime? lastEventAt;

  /// 月度 tick 锚点(B1 接通 · 区别于 [lastEventAt]):上次跑过月度 tick 检查的
  /// 时间。`null` = 从未跑过(首 tick 从 [createdAt] 起算 elapsedMonths)。
  /// 每 tick 推进 `elapsedMonths × 30 天`(保留 <30 天余数),防同日重复触发。
  /// Isar 对 nullable 新增字段向后兼容(旧记录读 null)。
  DateTime? lastTickAt;

  /// 引 `data/territories.yaml` id(P4.1 §12.2 Q4=A 静态 yaml + dynamic owner)。
  ///
  /// `TerritoryService.claim/release` 维护;cap 走 `numbers.yaml
  /// sect_management.territory.max_per_sect_by_level[sectLevel-1]`。
  List<String> territoryIds = [];

  /// 成员计数 cache(P4.1 §12.2 Q2=C 双向 fk · `SectMemberService.recruit/dismiss`
  /// writeTxn 时同步)。
  ///
  /// **不含 founder 本人**(founder 即玩家本身,通过 `Sect.founderId` 直接索引,
  /// `Character.isInSect=true && sectId=this.id` 含 founder + 招收 member)。
  /// **cap**:`numbers.yaml sect_management.member_cap.by_sect_level[sectLevel-1]`。
  int memberCount = 0;
}
