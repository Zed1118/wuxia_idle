import '../../core/domain/enums.dart';

/// 招式配置（data_schema.md §5.3，纯 Dart，不入 Isar）。
///
/// `parentTechniqueDefId` 为空时，表示该招式由"武学领悟"独立产出（GDD §7.2）。
/// `tier` 仅 encounter skill 填 1-7(沿用 GDD §5.2 七阶节奏 + §5.3 三系锁死),
/// 普通心法招式 tier 留空。
/// `narrativeInsightId` 是 encounter skill 显式指向 insight 文案文件名
/// (`data/narratives/techniques/insights/<id>.yaml`) 的可选关联,
/// 用于把数值招式池(skill_encounter_*)与文案池(move_insight_*/中文诗意命名)
/// 显式挂钩(W14-4 audit #36)。普通心法招式留空。
class SkillDef {
  final String id;
  final String name;
  final String description;
  final SkillType type;
  final int powerMultiplier;
  final int internalForceCost;
  final int cooldownTurns;
  final bool requiresManualTrigger;
  final String? parentTechniqueDefId;
  final String visualEffect;
  final int? tier;
  final String? narrativeInsightId;

  /// M4 Stage 3 美术(2026-05-21):招式插图 png 路径。
  /// 仅标志性招式在 yaml 配置;其余 null 走 UI fallback。
  final String? imagePath;

  /// P0 破招:此技命中正在蓄力的目标可打断其招牌技。
  final bool canInterrupt;

  /// P0 破招:AI 自动战斗对此技的使用策略。
  final AiUsePolicy aiUsePolicy;

  const SkillDef({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.powerMultiplier,
    required this.internalForceCost,
    required this.cooldownTurns,
    required this.requiresManualTrigger,
    this.parentTechniqueDefId,
    required this.visualEffect,
    this.tier,
    this.narrativeInsightId,
    this.imagePath,
    this.canInterrupt = false,
    this.aiUsePolicy = AiUsePolicy.normal,
  });

  /// 奇遇招式 = parentTechniqueDefId 为空 & tier 非空。
  bool get isEncounterSkill => parentTechniqueDefId == null && tier != null;

  factory SkillDef.fromYaml(Map<String, dynamic> y) {
    return SkillDef(
      id: y['id'] as String,
      name: y['name'] as String,
      description: y['description'] as String,
      type: SkillType.values.byName(y['type'] as String),
      powerMultiplier: (y['powerMultiplier'] as num).toInt(),
      internalForceCost: (y['internalForceCost'] as num).toInt(),
      cooldownTurns: (y['cooldownTurns'] as num).toInt(),
      requiresManualTrigger: y['requiresManualTrigger'] as bool,
      parentTechniqueDefId: y['parentTechniqueDefId'] as String?,
      visualEffect: y['visualEffect'] as String,
      tier: (y['tier'] as num?)?.toInt(),
      narrativeInsightId: y['narrativeInsightId'] as String?,
      imagePath: y['imagePath'] as String?,
      canInterrupt: y['canInterrupt'] as bool? ?? false,
      aiUsePolicy: y['aiUsePolicy'] != null
          ? AiUsePolicy.values.byName(y['aiUsePolicy'] as String)
          : AiUsePolicy.normal,
    );
  }

  @override
  String toString() =>
      'SkillDef(id=$id, name=$name, type=${type.name}, power=$powerMultiplier)';
}
