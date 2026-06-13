import 'package:isar_community/isar.dart';

part 'battle_replay_record.g.dart';

/// 半手动战斗 P0 步骤5:重放落盘记录(spec §六 数据结构草案)。
///
/// 一行 = 一关一周目的「已手动通关」证明 + 重放输入。手动单步通关后写入
/// (seed + 操作序列),自动战斗读出按同 seed + 同锚点重演确定性复刻通关
/// (`BattleNotifier.replay`,步骤4)。存在性 = 该关该周目已手动通关 →
/// UI 解锁「自动战斗」(解锁 wiring 留下一波)。
///
/// **每存档单行 per battleKey**:service 层保证(无 unique index;Phase 1
/// 仅 saveDataId=1)。重复手动通关覆盖为最新 seed+ops(语义:存最近一次手动
/// 通关的可重演输入)。
///
/// **挂机定义**(GDD line 81 加注,用户拍板 2026-06-13 采纳 spec §四草案):
/// 自动战斗 = 刷已手动通关的关卡,产出仍「在线=离线」(不引入加速/快进券);
/// 手动 = 推新内容的一次性门槛,非留存机制。
@collection
class BattleReplayRecord {
  Id id = Isar.autoIncrement;

  /// 关联 SaveData.slotId(Phase 1 固定 1)。Phase 5 多存档按此筛。
  late int saveDataId;

  /// 战斗标识:`stage#<stageId>#<cycle>` / `tower#<floor>#<cycle>`。
  /// cycle 默认 1(P0 无周目;周目递进 P1 接入,battleKey 已前向兼容)。
  /// 索引快速查「该关该周目是否已手动通关」。
  @Index()
  late String battleKey;

  /// 本场战斗随机种子(确定性重放重建 rng)。
  late int seed;

  /// 操作序列 JSON(`BattleReplayOp.encodeList`):
  /// `[{anchor,charId,skillId,targetId},...]`,保序。
  late String opsJson;

  /// 手动通关时间(覆盖时更新为最近一次)。
  late DateTime clearedAt;
}
