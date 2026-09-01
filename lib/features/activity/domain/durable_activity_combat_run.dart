import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import 'activity_member_snapshot.dart';

part 'durable_activity_combat_run.g.dart';

/// 九霄塔/轻功/守城共用的持久差遣种类。
///
/// 枚举按 name 写入既有 string 字段；新增 tower 不改变 collection 字段 schema。
enum DurableActivityKind { tower, lightFoot, massBattle }

/// 差遣会话只在关卡边界持久化，不序列化战斗逐 tick 状态。
enum DurableActivityPhase { active, settlementApplied, closed }

enum DurableActivityOutcome { none, victory, defeat }

/// 九霄塔、轻功与守城的共用 durable run / settlement receipt。
///
/// 一条 active 记录先于 headless 战斗落库；崩溃后以同一 [seed]、参与者装配和
/// 守城阵型重跑。业务结算与 `settlementApplied` 在同一 Isar 事务提交，恢复时
/// 只展示已落库报告，不重复成长、伤势、进度或掉落。
@collection
class DurableActivityCombatRun {
  Id id = Isar.autoIncrement;

  @Index()
  late int saveDataId;

  @Enumerated(EnumType.name)
  late DurableActivityKind kind;

  late String contentId;
  late String loadoutPlanId;
  late String stageId;
  late int cycleIndex;
  late int seed;

  @Enumerated(EnumType.name)
  late ActivityContentKind contentKind;

  @Enumerated(EnumType.name)
  late ActivityParticipationMode participation;

  @Enumerated(EnumType.name)
  late ActivityController controller;

  @Enumerated(EnumType.name)
  late ActivityClock clock;

  @Enumerated(EnumType.name)
  late ActivityEntryKind entryKind;

  /// 当前两类差遣均严格单人；保留 ActivityMemberSnapshot 以接入统一占用真相源。
  List<ActivityMemberSnapshot> members = [];

  late DateTime participantCreatedAt;
  late String participantName;

  /// 守城必须非空、轻功必须为空；永不在恢复时猜默认阵型。
  @Enumerated(EnumType.name)
  Formation? formation;

  @Enumerated(EnumType.name)
  DurableActivityPhase phase = DurableActivityPhase.active;

  @Enumerated(EnumType.name)
  DurableActivityOutcome outcome = DurableActivityOutcome.none;

  late DateTime startedAt;

  /// 离线恢复游标；每次开始/恢复 headless 执行前推进。
  late DateTime lastAdvancedAt;

  DateTime? settlementAppliedAt;
  DateTime? closedAt;

  @ignore
  ActivityParticipationRequest get request {
    if (members.length != 1) {
      throw StateError('Durable activity run requires exactly one member');
    }
    return ActivityParticipationRequest(
      contentId: contentId,
      contentKind: contentKind,
      characterId: members.single.characterId,
      loadoutPlanId: loadoutPlanId,
      participation: participation,
      controller: controller,
      clock: clock,
      entryKind: entryKind,
    );
  }
}
