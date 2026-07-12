import '../../core/domain/enums.dart';

class TechniqueQiProfile {
  const TechniqueQiProfile({
    this.maxBonus = 0,
    this.openingBonus = 0,
    this.gainPct = 0,
    this.costReductionPct = 0,
  });

  final int maxBonus;
  final int openingBonus;
  final double gainPct;
  final double costReductionPct;

  factory TechniqueQiProfile.fromYaml(Map<String, dynamic> y) {
    final profile = TechniqueQiProfile(
      maxBonus: (y['maxBonus'] as num?)?.toInt() ?? 0,
      openingBonus: (y['openingBonus'] as num?)?.toInt() ?? 0,
      gainPct: (y['gainPct'] as num?)?.toDouble() ?? 0,
      costReductionPct: (y['costReductionPct'] as num?)?.toDouble() ?? 0,
    );
    if (profile.maxBonus < 0 ||
        profile.openingBonus < 0 ||
        profile.gainPct < 0 ||
        profile.costReductionPct < 0) {
      throw StateError('心法真气倾向不得为负数: $y');
    }
    return profile;
  }
}

/// 心法配置（data_schema.md §5.2，纯 Dart，不入 Isar）。
class TechniqueDef {
  final String id;
  final String name;
  final TechniqueTier tier;
  final TechniqueSchool school;
  final String description;
  final List<String> skillIds;

  /// UNUSED(0 读取 · 审计 D1 2026-06-24):与 techniques.yaml 的 `tier` 注释一致,
  /// 此二字段为与 `numbers.yaml techniques.tiers` 对齐的镜像参考值。派生属性的真相源
  /// 是 numbers.yaml tiers(`internal_force_growth_bonus`/`speed_bonus` 按阶查),
  /// 经 `derived_stats` 消费;本 def 字段从无生产消费方。保留作 per-心法 文档对照,
  /// 不删免动全 techniques.yaml 条目;真要消费时再接 derived 路径。
  final double internalForceGrowthBonus;
  final int speedBonus;
  final List<String> acquireSourceTags;
  final TechniqueQiProfile qiProfile;

  /// 心法个体卷轴图 png 路径(可选)。当前 techniques.yaml 无任一条目配置 `imagePath`,
  /// 恒为 null;字段保留待未来心法个体立绘。tier 分组头为纯绘制水墨头
  /// (`technique_panel_screen` `_TechniqueTierHeader`),不依赖资产图——
  /// 原 `assets/techniques/tier_*.png` 卷轴 cover 因抠图白边叠深底突兀,
  /// 2026-06-29(commit 16941355)目检否决改文字头,2026-07-02 资产已删。
  final String? imagePath;

  const TechniqueDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.school,
    required this.description,
    required this.skillIds,
    required this.internalForceGrowthBonus,
    required this.speedBonus,
    required this.acquireSourceTags,
    this.qiProfile = const TechniqueQiProfile(),
    this.imagePath,
  });

  factory TechniqueDef.fromYaml(Map<String, dynamic> y) {
    return TechniqueDef(
      id: y['id'] as String,
      name: y['name'] as String,
      tier: TechniqueTier.values.byName(y['tier'] as String),
      school: TechniqueSchool.values.byName(y['school'] as String),
      description: y['description'] as String,
      skillIds: List<String>.from(
        (y['skillIds'] as List? ?? const []).map((e) => e as String),
      ),
      internalForceGrowthBonus: (y['internalForceGrowthBonus'] as num)
          .toDouble(),
      speedBonus: (y['speedBonus'] as num).toInt(),
      acquireSourceTags: List<String>.from(
        (y['acquireSourceTags'] as List? ?? const []).map((e) => e as String),
      ),
      qiProfile: TechniqueQiProfile.fromYaml(
        Map<String, dynamic>.from(y['qiProfile'] as Map? ?? const {}),
      ),
      imagePath: y['imagePath'] as String?,
    );
  }

  @override
  String toString() =>
      'TechniqueDef(id=$id, name=$name, tier=${tier.name}, school=${school.name})';
}
