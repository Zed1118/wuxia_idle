/// 转阶段 AI 模式。normal=默认；aggressive=提高强力技/大招优先级；focus=倾向集火破绽。
enum BossAiMode { normal, aggressive, focus }

/// 转阶段一次性 telegraphed 机制。chargeCounter=进蓄力态下回合放阶段大招(复用破招蓄力)。
enum BossPhaseMechanic { chargeCounter }

/// Boss 阶段定义（第七阶段批二 ①）。EnemyDef.bossPhases 内嵌；null=单阶段旧行为。
/// 纯机制/表现切换，**不携带任何属性 buff**（守 §5.4 不数值膨胀）。
class BossPhaseDef {
  /// 进入本阶段的血量上限百分比阈值（降序，首项必为 1.0=满血起始阶段）。
  final double hpThresholdPct;

  /// 进入本阶段并入该单位 availableSkills 的招 id（敌方招，可空）。
  final List<String> unlockSkillIds;

  final BossAiMode aiMode;
  final BossPhaseMechanic? onEnterMechanic;

  /// 转阶段题字 UiStrings key（表现层用，可空=不题字）。
  final String? titleKey;

  const BossPhaseDef({
    required this.hpThresholdPct,
    this.unlockSkillIds = const [],
    this.aiMode = BossAiMode.normal,
    this.onEnterMechanic,
    this.titleKey,
  });

  factory BossPhaseDef.fromYaml(Map<String, dynamic> y) => BossPhaseDef(
        hpThresholdPct: (y['hpThresholdPct'] as num).toDouble(),
        unlockSkillIds: List<String>.from(
            (y['unlockSkillIds'] as List? ?? const []).map((e) => e as String)),
        aiMode: y['aiMode'] == null
            ? BossAiMode.normal
            : BossAiMode.values.byName(y['aiMode'] as String),
        onEnterMechanic: y['onEnterMechanic'] == null
            ? null
            : BossPhaseMechanic.values.byName(y['onEnterMechanic'] as String),
        titleKey: y['titleKey'] as String?,
      );

  /// 解析阶段数组并校验：首项阈值=1.0、阈值严格降序。
  static List<BossPhaseDef> parseList(List<dynamic> raw) {
    final list = raw
        .map((e) => BossPhaseDef.fromYaml(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (list.isEmpty) return list;
    if (list.first.hpThresholdPct != 1.0) {
      throw StateError('bossPhases 首项 hpThresholdPct 必须为 1.0(满血起始阶段)');
    }
    for (var i = 1; i < list.length; i++) {
      if (list[i].hpThresholdPct >= list[i - 1].hpThresholdPct) {
        throw StateError('bossPhases hpThresholdPct 必须严格降序');
      }
    }
    return list;
  }
}
