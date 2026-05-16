import '../../../core/domain/enums.dart';

/// 奇遇 / 武学领悟 type 枚举(GDD §7.2 + CLAUDE §8.1)。
///
/// Unified 模型:武学领悟是奇遇的一个 type。Demo 阶段 Phase 1 只实现
/// [techniqueInsight] + [fortuneEvent],[trial] + [karma] 留 Phase 2+。
enum EncounterType {
  /// 武学领悟:满足触发条件 → 灵光一现 → 领悟新招。
  techniqueInsight,
  /// 机缘事件:偶遇高人 / 古迹 / 命运对话,outcome 多为属性微调。
  fortuneEvent,
  /// 试炼:战斗向奇遇(Phase 2+)。
  trial,
  /// 因果:剧情向奇遇(Phase 2+)。
  karma,
}

/// outcome 数值化类型(C-W14-1 决策点 Q4:领悟新招 + 属性微调 + skip)。
enum OutcomeType {
  /// 解锁新招式(unlock skill_id 加入 character.unlockedSkillIds,
  /// Phase 1 仅记录,战斗系统消费后续接)。
  unlockSkill,
  /// 4 属性微调 +1(GDD §4.1 line 183 生涯总和上限 5)。
  attributeBonus,
  /// 无 effect(玩家选了 skip 选项)。
  none,
}

/// 4 属性枚举(EncounterDef 用,与 [Attributes] 字段对齐)。
///
/// 不复用 [Attributes] 类型避免 def 层污染 Isar。
enum AttributeKey {
  constitution, // 根骨
  enlightenment, // 悟性
  agility, // 身法
  fortune, // 机缘
}

/// outcome 数值化定义。每条 encounter 的每个 outcome_id 对应一个。
class OutcomeDef {
  final OutcomeType type;
  /// 仅 [OutcomeType.unlockSkill] 时有效。
  final String? skillId;
  /// 仅 [OutcomeType.attributeBonus] 时有效。
  final AttributeKey? attributeKey;
  /// 仅 [OutcomeType.attributeBonus] 时有效;Demo 阶段固定 +1。
  final int attributeDelta;

  const OutcomeDef({
    required this.type,
    this.skillId,
    this.attributeKey,
    this.attributeDelta = 1,
  });

  factory OutcomeDef.fromYaml(Map<String, dynamic> y) {
    final type = OutcomeType.values.byName(y['type'] as String);
    switch (type) {
      case OutcomeType.unlockSkill:
        final sid = y['skillId'] as String?;
        if (sid == null) {
          throw StateError('OutcomeDef unlockSkill 必须配 skillId');
        }
        return OutcomeDef(type: type, skillId: sid);
      case OutcomeType.attributeBonus:
        final ak = y['attributeKey'] as String?;
        if (ak == null) {
          throw StateError('OutcomeDef attributeBonus 必须配 attributeKey');
        }
        return OutcomeDef(
          type: type,
          attributeKey: AttributeKey.values.byName(ak),
          attributeDelta: (y['attributeDelta'] as num?)?.toInt() ?? 1,
        );
      case OutcomeType.none:
        return const OutcomeDef(type: OutcomeType.none);
    }
  }
}

/// 触发条件(C-W14-1 决策点 Q1:多维度 counter,无全局机缘值)。
///
/// **C-W14-2 扩展**:在 W14-1 的 [schoolKillThreshold] + [fortuneRequired]
/// 基础上,加 [biomeMinutes] + [weatherMinutes] 多维度。biome/weather 累计
/// 走 [EncounterService.recordIdleMinutes](闭关 actualHours × 60 喂)。
///
/// **W16 扩展**:加 [festivalRequired]。仅在指定节日当天触发(对接
/// `numbers.yaml festivals.days_2026`)。GDD §12.4 接口预留 —— 节日活动不影响
/// 数值，仅作为 encounter trigger 维度（限定剧情）。
///
/// 多维度阈值**全部满足才触发**(AND 语义)。任一维度配空 map = 该维度无门槛。
class EncounterTrigger {
  /// 每流派的击杀阈值。例:`{lingQiao: 100}` = 击败 100 个灵巧流派敌人。
  final Map<TechniqueSchool, int> schoolKillThreshold;
  /// 在某 biome 累积分钟数门槛(C-W14-2)。例:`{bambooForest: 600}` =
  /// 在竹林场景累计 10 小时挂机。
  final Map<EncounterBiome, int> biomeMinutes;
  /// 在某 weather 累积分钟数门槛(C-W14-2)。例:`{rain: 120}` = 在雨天
  /// 累计 2 小时挂机。
  final Map<EncounterWeather, int> weatherMinutes;
  /// 机缘属性下限。`fortune < this` 时不参与软概率计算,直接 0 概率。
  /// `null` 表示无下限(任何 fortune 都参与)。
  final int? fortuneRequired;
  /// W16 节日触发门槛。`null` 表示无门槛(任何日子都参与)；
  /// 非 null 时仅在该节日当天通过 [EncounterService] `festivalToday` 维度匹配时才触发。
  final Festival? festivalRequired;

  const EncounterTrigger({
    this.schoolKillThreshold = const {},
    this.biomeMinutes = const {},
    this.weatherMinutes = const {},
    this.fortuneRequired,
    this.festivalRequired,
  });

  factory EncounterTrigger.fromYaml(Map<String, dynamic> y) {
    return EncounterTrigger(
      schoolKillThreshold: Map.unmodifiable(_parseEnumIntMap(
        y['schoolKillThreshold'] as Map?,
        (k) => TechniqueSchool.values.byName(k),
      )),
      biomeMinutes: Map.unmodifiable(_parseEnumIntMap(
        y['biomeMinutes'] as Map?,
        (k) => EncounterBiome.values.byName(k),
      )),
      weatherMinutes: Map.unmodifiable(_parseEnumIntMap(
        y['weatherMinutes'] as Map?,
        (k) => EncounterWeather.values.byName(k),
      )),
      fortuneRequired: (y['fortuneRequired'] as num?)?.toInt(),
      festivalRequired: y['festivalRequired'] == null
          ? null
          : Festival.values.byName(y['festivalRequired'] as String),
    );
  }

  static Map<E, int> _parseEnumIntMap<E extends Enum>(
    Map? raw,
    E Function(String) parseKey,
  ) {
    final out = <E, int>{};
    if (raw == null) return out;
    for (final entry in raw.entries) {
      out[parseKey(entry.key as String)] = (entry.value as num).toInt();
    }
    return out;
  }
}

/// 奇遇 / 武学领悟定义(C-W14-1)。
///
/// 与 `data/events/<id>.yaml`(DeepSeek 写)通过 [id] 一一对应:
///   - encounters.yaml 这边写数值(trigger / probability / outcome 映射)
///   - events 那边写文案(opening / choices.text / choices.body)
///   - **加载层强校验**:每条 encounter 的 [outcomeMapping] keys 必须 ⊇
///     events 文件 choices 中除 `skip` 外的所有 outcome_id。
class EncounterDef {
  final String id;
  final EncounterType type;
  final EncounterTrigger trigger;
  /// trigger 全满足后的基础触发概率 ∈ [0, 1]。
  /// 实际触发概率 = baseProbability * (1 + fortune/20)(C-W14-1 决策点 Q3)。
  final double baseProbability;
  /// outcome_id → OutcomeDef 映射。outcome_id 必须与 `events/[id].yaml` 的
  /// `choices[].outcome_id` 一致(`skip` 默认 [OutcomeType.none],
  /// 不必显式配)。
  final Map<String, OutcomeDef> outcomeMapping;

  const EncounterDef({
    required this.id,
    required this.type,
    required this.trigger,
    required this.baseProbability,
    required this.outcomeMapping,
  });

  factory EncounterDef.fromYaml(Map<String, dynamic> y) {
    final outcomesRaw = (y['outcomeMapping'] as Map?) ?? const {};
    final mapping = <String, OutcomeDef>{};
    for (final entry in outcomesRaw.entries) {
      mapping[entry.key as String] =
          OutcomeDef.fromYaml(Map<String, dynamic>.from(entry.value as Map));
    }
    final baseProb = (y['baseProbability'] as num).toDouble();
    if (baseProb < 0 || baseProb > 1) {
      throw StateError(
        'EncounterDef ${y['id']} baseProbability=$baseProb,应 ∈ [0, 1]',
      );
    }
    return EncounterDef(
      id: y['id'] as String,
      type: EncounterType.values.byName(y['type'] as String),
      trigger: EncounterTrigger.fromYaml(
        Map<String, dynamic>.from(y['trigger'] as Map? ?? const {}),
      ),
      baseProbability: baseProb,
      outcomeMapping: Map.unmodifiable(mapping),
    );
  }

  /// 取 outcome,缺失时 fallback 到 [OutcomeType.none](等同 skip)。
  OutcomeDef resolveOutcome(String outcomeId) =>
      outcomeMapping[outcomeId] ??
      const OutcomeDef(type: OutcomeType.none);
}
