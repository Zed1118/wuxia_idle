import '../../core/domain/enums.dart';

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

  /// M4 Stage 3 美术(2026-05-21):心法卷轴图 png 路径。
  /// 仅 3 标志高阶心法在 yaml 配置(失传神功 / 传说神功 / 门派绝学);
  /// 其余心法 null,UI 走 tier section banner cover(约定路径 `assets/techniques/tier_[name].png`)。
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
      internalForceGrowthBonus:
          (y['internalForceGrowthBonus'] as num).toDouble(),
      speedBonus: (y['speedBonus'] as num).toInt(),
      acquireSourceTags: List<String>.from(
        (y['acquireSourceTags'] as List? ?? const []).map((e) => e as String),
      ),
      imagePath: y['imagePath'] as String?,
    );
  }

  @override
  String toString() =>
      'TechniqueDef(id=$id, name=$name, tier=${tier.name}, school=${school.name})';
}
