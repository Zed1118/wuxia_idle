import '../../core/domain/enums.dart';

/// 心法相生 requirement 类型(W18-A1, GDD §4.5)。
///
/// 严格优先级:[schoolPair] > [sameSchool] > [sameTier]。同时命中多类时
/// 取最严格的类型(detectActive 遍历顺序保证)。
enum SynergyRequirementType {
  /// 主修+辅修严格指定流派组合(如 gangMeng+yinRou)。需配 [SynergyDef.mainSchool]
  /// + [SynergyDef.assistSchool],且两者必须不同。
  schoolPair,

  /// 主修+辅修同流派(任意 tier)。
  sameSchool,

  /// 主修+辅修 tier 相同(任意流派)。
  sameTier,
}

/// 心法相生 buff 系数(W18-A1)。
///
/// 各项 ≥ 0 ≤ 0.30(GameRepository 红线校验)。注入到 [StageBattleSetup]
/// 构造的角色属性副本上(view layer,不动 Isar)。
class SynergyMultipliers {
  /// 攻击系属性 buff(进 baseAttack 派生公式)。
  final double attackPct;

  /// 防御系属性 buff(进 baseDefense 派生公式)。
  final double defensePct;

  /// 速度系属性 buff(进 baseSpeed 派生公式)。
  final double speedPct;

  /// 血量 buff(进 maxHp 派生公式)。
  final double hpPct;

  /// 内力上限 buff(internalForceMax 派生)。
  final double internalForceMaxPct;

  /// 内力增长 buff(闭关/战斗后 internalForce 累加)。
  /// 注:W18-A1 第 1 批战斗 init 不直接消费,留 hook 给后续闭关/战后累积接入。
  final double internalForceGrowthPct;

  const SynergyMultipliers({
    this.attackPct = 0,
    this.defensePct = 0,
    this.speedPct = 0,
    this.hpPct = 0,
    this.internalForceMaxPct = 0,
    this.internalForceGrowthPct = 0,
  });

  /// 简要文案(UI chip 显示用)。零值字段跳过。
  String summary() {
    final parts = <String>[];
    if (attackPct != 0) parts.add('攻 ${_fmt(attackPct)}');
    if (defensePct != 0) parts.add('防 ${_fmt(defensePct)}');
    if (speedPct != 0) parts.add('速 ${_fmt(speedPct)}');
    if (hpPct != 0) parts.add('血 ${_fmt(hpPct)}');
    if (internalForceMaxPct != 0) {
      parts.add('内力上限 ${_fmt(internalForceMaxPct)}');
    }
    if (internalForceGrowthPct != 0) {
      parts.add('内力增长 ${_fmt(internalForceGrowthPct)}');
    }
    return parts.join(' · ');
  }

  static String _fmt(double v) {
    final pct = (v * 100).round();
    return v >= 0 ? '+$pct%' : '$pct%';
  }

  factory SynergyMultipliers.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return const SynergyMultipliers();
    double r(String k) => (y[k] as num?)?.toDouble() ?? 0;
    return SynergyMultipliers(
      attackPct: r('attackPct'),
      defensePct: r('defensePct'),
      speedPct: r('speedPct'),
      hpPct: r('hpPct'),
      internalForceMaxPct: r('internalForceMaxPct'),
      internalForceGrowthPct: r('internalForceGrowthPct'),
    );
  }

  /// 各项 ≤ 0.30 的红线校验。
  bool get isWithinRedLine =>
      attackPct <= 0.30 &&
      defensePct <= 0.30 &&
      speedPct <= 0.30 &&
      hpPct <= 0.30 &&
      internalForceMaxPct <= 0.30 &&
      internalForceGrowthPct <= 0.30 &&
      attackPct >= 0 &&
      defensePct >= 0 &&
      speedPct >= 0 &&
      hpPct >= 0 &&
      internalForceMaxPct >= 0 &&
      internalForceGrowthPct >= 0;
}

/// 心法相生 def(W18-A1, GDD §4.5 "心法相生 5-8 个隐藏组合")。
///
/// 主修 + 第 1 辅修达到 [requirementType] 指定的组合时触发,buff 注入战斗
/// init 时的 effective attributes(view layer)。彩蛋向,**不放进引导**,
/// 玩家通过实验发现(对齐 GDD §4.5 设计理由)。
class SynergyDef {
  final String id;
  final String name;
  final String description;
  final SynergyRequirementType requirementType;

  /// 仅 [requirementType] == [SynergyRequirementType.schoolPair] 时有效。
  final TechniqueSchool? mainSchool;

  /// 仅 [requirementType] == [SynergyRequirementType.schoolPair] 时有效。
  final TechniqueSchool? assistSchool;

  final SynergyMultipliers multipliers;

  const SynergyDef({
    required this.id,
    required this.name,
    required this.description,
    required this.requirementType,
    this.mainSchool,
    this.assistSchool,
    required this.multipliers,
  });

  /// 判定给定 (mainSchool, assistSchool, mainTier, assistTier) 是否命中本相生。
  bool matches({
    required TechniqueSchool mainSchool,
    required TechniqueSchool assistSchool,
    required TechniqueTier mainTier,
    required TechniqueTier assistTier,
  }) {
    switch (requirementType) {
      case SynergyRequirementType.schoolPair:
        return this.mainSchool == mainSchool &&
            this.assistSchool == assistSchool;
      case SynergyRequirementType.sameSchool:
        return mainSchool == assistSchool;
      case SynergyRequirementType.sameTier:
        return mainTier == assistTier;
    }
  }

  factory SynergyDef.fromYaml(Map<String, dynamic> y) {
    final req = y['requirement'] as Map?;
    if (req == null) {
      throw StateError('SynergyDef ${y['id']} 缺 requirement 段');
    }
    final type = SynergyRequirementType.values
        .byName(req['type'] as String);
    return SynergyDef(
      id: y['id'] as String,
      name: y['name'] as String,
      description: y['description'] as String,
      requirementType: type,
      mainSchool: req['mainSchool'] == null
          ? null
          : TechniqueSchool.values.byName(req['mainSchool'] as String),
      assistSchool: req['assistSchool'] == null
          ? null
          : TechniqueSchool.values.byName(req['assistSchool'] as String),
      multipliers: SynergyMultipliers.fromYaml(
        (y['multipliers'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  @override
  String toString() =>
      'SynergyDef(id=$id, name=$name, type=${requirementType.name})';
}
