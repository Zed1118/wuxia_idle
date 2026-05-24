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
}
