import 'package:isar_community/isar.dart';

import '../../data/numbers_config.dart';
import 'enums.dart';
import 'skill_usage_entry.dart';

part 'technique.g.dart';

/// 心法实例（data_schema.md §4.4 / GDD §4.2-§4.3）。
///
/// `defId` 指向 yaml 中的 TechniqueDef。修炼度由招式使用次数累积。
/// 散功见文件底部 [TechniqueDispersion] extension。
@collection
class Technique {
  Id id = Isar.autoIncrement;

  @Index()
  late String defId;

  @Index()
  late int ownerCharacterId;

  @Enumerated(EnumType.name)
  late TechniqueTier tier;

  @Enumerated(EnumType.name)
  late TechniqueSchool school;

  @Enumerated(EnumType.name)
  CultivationLayer cultivationLayer = CultivationLayer.chuKui;

  int cultivationProgress = 0;
  int cultivationProgressToNext = 100;

  List<SkillUsageEntry> skillUsageCount = [];

  @Enumerated(EnumType.name)
  late TechniqueRole role;

  bool wasMainBeforeReset = false;
  late DateTime learnedAt;

  Technique();

  /// 工厂方法：一次性初始化所有 late 字段。
  factory Technique.create({
    required String defId,
    required int ownerCharacterId,
    required TechniqueTier tier,
    required TechniqueSchool school,
    required TechniqueRole role,
    required DateTime learnedAt,
    CultivationLayer cultivationLayer = CultivationLayer.chuKui,
    int cultivationProgress = 0,
    int cultivationProgressToNext = 100,
    List<SkillUsageEntry>? skillUsageCount,
    bool wasMainBeforeReset = false,
  }) {
    return Technique()
      ..defId = defId
      ..ownerCharacterId = ownerCharacterId
      ..tier = tier
      ..school = school
      ..role = role
      ..learnedAt = learnedAt
      ..cultivationLayer = cultivationLayer
      ..cultivationProgress = cultivationProgress
      ..cultivationProgressToNext = cultivationProgressToNext
      ..skillUsageCount = skillUsageCount ?? []
      ..wasMainBeforeReset = wasMainBeforeReset;
  }
}

/// 散功扩展（data_schema.md §4.4 / GDD §6 散功代价）。
///
/// 修炼度按 [NumbersConfig.dispersionCultivationPenalty] (=0.5) 衰减；
/// 调用方还需把角色当前内力 ×0.5（在应用层做，对应 yaml
/// `techniques.dispersion.internal_force_penalty`）。
/// `cultivationLayer` 不在此处回退，由应用层根据新的 progress 重算。
extension TechniqueDispersion on Technique {
  void disperse(NumbersConfig n) {
    wasMainBeforeReset = true;
    cultivationProgress =
        (cultivationProgress * n.dispersionCultivationPenalty).toInt();
    role = TechniqueRole.assist;
  }
}
