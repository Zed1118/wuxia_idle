import 'dart:convert';

/// 半手动战斗 P0:重放操作记录(spec `2026-06-13-semi-manual-battle-seed-
/// replay-cycle-design.md` §2.2 / §六)。
///
/// 一条 [BattleReplayOp] = 玩家在某个推进锚点对某角色手动请求某技能(可含
/// 选定目标)。手动通关时按序记录,与战斗 seed 一起构成「确定性重演该关该
/// 周目通关」的完整输入(同 seed 重建 rng + 在相同锚点回放 requestUltimate)。
///
/// **锚点 = `BattleState.tick`**(spec §八#6 用户拍板 2026-06-13):引擎时间
/// 计数器,同 seed 推进确定;重放到该 tick 时回放该 op。
class BattleReplayOp {
  /// 推进锚点:玩家发起本次手动请求时的 [BattleState.tick]。
  final int anchor;

  /// 被请求角色 characterId。
  final int charId;

  /// 请求的技能 id([SkillDef.id])。
  final String skillId;

  /// 选定目标 characterId;null = 未指定(走 AI 默认选目标)。
  /// P0 步骤2 暂恒为 null,步骤3「手动选目标」接入后填实。
  final int? targetId;

  const BattleReplayOp({
    required this.anchor,
    required this.charId,
    required this.skillId,
    this.targetId,
  });

  @override
  bool operator ==(Object other) =>
      other is BattleReplayOp &&
      other.anchor == anchor &&
      other.charId == charId &&
      other.skillId == skillId &&
      other.targetId == targetId;

  @override
  int get hashCode => Object.hash(anchor, charId, skillId, targetId);

  @override
  String toString() =>
      'BattleReplayOp(anchor=$anchor, char=$charId, skill=$skillId, '
      'target=$targetId)';

  // ─── 序列化(步骤5 落盘 BattleReplayRecord.opsJson)──────────────────────

  /// 单条 op → JSON map。targetId 为 null 时显式写 null(保真,decode 回 null)。
  Map<String, dynamic> toJson() => {
        'anchor': anchor,
        'charId': charId,
        'skillId': skillId,
        'targetId': targetId,
      };

  /// JSON map → 单条 op。
  factory BattleReplayOp.fromJson(Map<String, dynamic> json) => BattleReplayOp(
        anchor: json['anchor'] as int,
        charId: json['charId'] as int,
        skillId: json['skillId'] as String,
        targetId: json['targetId'] as int?,
      );

  /// 操作序列 → JSON 字符串(落盘 `opsJson`)。保序。
  static String encodeList(List<BattleReplayOp> ops) =>
      jsonEncode(ops.map((o) => o.toJson()).toList());

  /// JSON 字符串 → 操作序列(读盘重放)。保序。
  static List<BattleReplayOp> decodeList(String json) =>
      (jsonDecode(json) as List)
          .map((e) => BattleReplayOp.fromJson(e as Map<String, dynamic>))
          .toList();
}
