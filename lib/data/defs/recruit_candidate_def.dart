import '../../core/domain/enums.dart';
import 'master_def.dart' show AttributeProfile;

/// 收徒候选 NPC 定义(P1.1 A1 师徒 E.1)。
///
/// GDD §7.1「突破到一流可收徒」+ audit doc `p1_1_a1_recruitment_audit_2026-05-21.md`
/// 方案 3 决议(inactive 池收徒,active 上限不动)。
///
/// 加载源:`data/recruit_candidates.yaml`,Demo + 1.0 P1.1 阶段固定 3 候选。
/// 拜师后:`RecruitmentService.acceptCandidate(id)` 据本 def 创 Character 入 Isar,
/// **不入** `SaveData.activeCharacterIds`(语义 inactive,玩家后续可切换出场)。
///
/// 三系锁死(CLAUDE.md §5.3):弟子默认境界 `sanLiu qiMeng` → 装备/心法 ≤
/// `xiangYangHuo / changLianGong` 阶,startingEquipmentIds / startingTechniqueIds
/// 由 RecruitmentService 加载期校验(防破红线)。
class RecruitCandidateDef {
  final String id;
  final String name;
  final LineageRole lineageRole;
  final RealmTier defaultRealm;
  final RealmLayer defaultLayer;
  final TechniqueSchool? school;
  final AttributeProfile attributeProfile;
  final List<String> startingTechniqueIds;
  final List<String> startingEquipmentIds;
  final String lore;
  final String? portraitPath;

  const RecruitCandidateDef({
    required this.id,
    required this.name,
    required this.lineageRole,
    required this.defaultRealm,
    required this.defaultLayer,
    required this.school,
    required this.attributeProfile,
    required this.startingTechniqueIds,
    required this.startingEquipmentIds,
    required this.lore,
    this.portraitPath,
  });

  factory RecruitCandidateDef.fromYaml(Map<String, dynamic> y) {
    return RecruitCandidateDef(
      id: y['id'] as String,
      name: y['name'] as String,
      lineageRole: LineageRole.values.byName(y['lineageRole'] as String),
      defaultRealm: RealmTier.values.byName(y['defaultRealm'] as String),
      defaultLayer: RealmLayer.values.byName(y['defaultLayer'] as String),
      school: y['school'] == null
          ? null
          : TechniqueSchool.values.byName(y['school'] as String),
      attributeProfile: AttributeProfile.fromYaml(
        Map<String, dynamic>.from(y['attributeProfile'] as Map),
      ),
      startingTechniqueIds: List<String>.from(
        (y['startingTechniqueIds'] as List? ?? const [])
            .map((e) => e as String),
      ),
      startingEquipmentIds: List<String>.from(
        (y['startingEquipmentIds'] as List? ?? const [])
            .map((e) => e as String),
      ),
      lore: (y['lore'] as String).trim(),
      portraitPath: y['portraitPath'] as String?,
    );
  }
}
