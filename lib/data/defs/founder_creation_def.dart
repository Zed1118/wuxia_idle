import '../../core/domain/enums.dart';
import 'master_def.dart';

/// 新档祖师塑形配置。
///
/// 加载源:`data/founder_creation.yaml`。Dart 只负责读取和执行流程;显示文案、
/// 起手路线和命盘模板均由 yaml 维护,避免开局路线扩展时改代码。
class FounderCreationConfig {
  final List<FounderSchoolOption> schools;
  final List<FounderOriginOption> origins;
  final List<FounderFateOption> fatePool;

  const FounderCreationConfig({
    required this.schools,
    required this.origins,
    required this.fatePool,
  });

  factory FounderCreationConfig.fromYaml(Map<String, dynamic> y) {
    return FounderCreationConfig(
      schools: ((y['schools'] as List?) ?? const [])
          .map(
            (e) => FounderSchoolOption.fromYaml(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      origins: ((y['origins'] as List?) ?? const [])
          .map(
            (e) => FounderOriginOption.fromYaml(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      fatePool: ((y['fatePool'] as List?) ?? const [])
          .map(
            (e) =>
                FounderFateOption.fromYaml(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  static const empty = FounderCreationConfig(
    schools: [],
    origins: [],
    fatePool: [],
  );

  FounderSchoolOption schoolById(String id) =>
      schools.firstWhere((e) => e.id == id);

  FounderOriginOption originById(String id) =>
      origins.firstWhere((e) => e.id == id);

  FounderFateOption fateById(String id) =>
      fatePool.firstWhere((e) => e.id == id);
}

class FounderSchoolOption {
  final String id;
  final TechniqueSchool school;
  final String label;
  final String temperament;
  final String summary;
  final String attributeHint;
  final List<String> startingTechniqueIds;
  final String goalHint;

  const FounderSchoolOption({
    required this.id,
    required this.school,
    required this.label,
    required this.temperament,
    required this.summary,
    required this.attributeHint,
    required this.startingTechniqueIds,
    required this.goalHint,
  });

  factory FounderSchoolOption.fromYaml(Map<String, dynamic> y) {
    return FounderSchoolOption(
      id: y['id'] as String,
      school: TechniqueSchool.values.byName(y['school'] as String),
      label: y['label'] as String,
      temperament: y['temperament'] as String,
      summary: y['summary'] as String,
      attributeHint: y['attributeHint'] as String,
      startingTechniqueIds: List<String>.from(
        (y['startingTechniqueIds'] as List? ?? const []).map(
          (e) => e as String,
        ),
      ),
      goalHint: y['goalHint'] as String,
    );
  }
}

class FounderOriginOption {
  final String id;
  final String label;
  final String summary;
  final int mojianshiBonus;
  final int jieJingBonus;
  final String resourceSummary;
  final String biographyLine;

  const FounderOriginOption({
    required this.id,
    required this.label,
    required this.summary,
    required this.mojianshiBonus,
    required this.jieJingBonus,
    required this.resourceSummary,
    required this.biographyLine,
  });

  factory FounderOriginOption.fromYaml(Map<String, dynamic> y) {
    return FounderOriginOption(
      id: y['id'] as String,
      label: y['label'] as String,
      summary: y['summary'] as String,
      mojianshiBonus: (y['mojianshiBonus'] as num?)?.toInt() ?? 0,
      jieJingBonus: (y['jieJingBonus'] as num?)?.toInt() ?? 0,
      resourceSummary: y['resourceSummary'] as String,
      biographyLine: y['biographyLine'] as String,
    );
  }
}

class FounderFateOption {
  final String id;
  final String label;
  final String verse;
  final String focus;
  final AttributeProfile attributeProfile;

  const FounderFateOption({
    required this.id,
    required this.label,
    required this.verse,
    required this.focus,
    required this.attributeProfile,
  });

  factory FounderFateOption.fromYaml(Map<String, dynamic> y) {
    return FounderFateOption(
      id: y['id'] as String,
      label: y['label'] as String,
      verse: y['verse'] as String,
      focus: y['focus'] as String,
      attributeProfile: AttributeProfile.fromYaml(
        Map<String, dynamic>.from(y['attributeProfile'] as Map),
      ),
    );
  }
}
