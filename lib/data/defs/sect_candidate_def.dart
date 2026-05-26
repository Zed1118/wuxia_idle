import '../../core/domain/enums.dart';
import 'master_def.dart' show AttributeProfile;

/// 门派招收候选 NPC 定义(P4.1 1.1 Q6A · GDD §12.2)。
///
/// 与 [RecruitCandidateDef](./recruit_candidate_def.dart) 区分:
///   - `RecruitCandidateDef` = 收徒 inactive 池(GDD §7.1 一流境界突破触发)
///   - `SectCandidateDef` = 门派招收 active NPC(P4.1 1.1 encounter 触发)
///
/// 加载源:`data/sect_candidates.yaml`,Demo 5-8 NPC PoC(spec §1)。
/// 招收成功后:`encounter_hook` 据本 def 创建 Character + `SectMemberService.recruit`
/// 入派(`Character.isInSect=true / sectId / sectRank=initiate`,memberCount++)。
/// **不入** `SaveData.activeCharacterIds`(NPC 不出战 · 仅入派语义,
/// sect_screen 成员列表可见 · 沿 P4.1 spec member 体例)。
///
/// 三系锁死(CLAUDE.md §5.3):NPC 境界 `sanLiu qiMeng` → 装备/心法 ≤
/// `xiangYangHuo / changLianGong` 阶。startingEquipmentIds / startingTechniqueIds
/// 由 `_enforceSectCandidateRedLines` 加载期校验(防破红线)。
///
/// `targetSectId` Demo 阶段不消费(Q3=A 默认 playerSectId)·
/// 1.2 跨派系 NPC 招进时启用(`SectMemberService.recruit(sectId: this.targetSectId)`)。
class SectCandidateDef {
  final String id;
  final String name;
  final RealmTier defaultRealm;
  final RealmLayer defaultLayer;
  final TechniqueSchool? school;
  final AttributeProfile attributeProfile;
  final List<String> startingTechniqueIds;
  final List<String> startingEquipmentIds;
  final String lore;
  final String? portraitPath;

  /// 1.2 跨派系预留字段。Demo 阶段 null(招入 playerSectId)。
  final int? targetSectId;

  const SectCandidateDef({
    required this.id,
    required this.name,
    required this.defaultRealm,
    required this.defaultLayer,
    required this.school,
    required this.attributeProfile,
    required this.startingTechniqueIds,
    required this.startingEquipmentIds,
    required this.lore,
    this.portraitPath,
    this.targetSectId,
  });

  factory SectCandidateDef.fromYaml(Map<String, dynamic> y) {
    return SectCandidateDef(
      id: y['id'] as String,
      name: y['name'] as String,
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
      targetSectId: (y['targetSectId'] as num?)?.toInt(),
    );
  }
}
