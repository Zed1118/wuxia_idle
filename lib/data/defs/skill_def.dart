import '../../core/domain/enums.dart';

/// 招式获取来源(波A A4 统一来源模型)。
/// 红线:production 全招必有(loader fail-fast);消费方 = 红线自洽 +
/// P4 藏经阁来源显示(P4 接 UI 前仅 schema + 红线)。
enum SkillSource {
  technique, // 心法自带(随心法修习获得)
  encounter, // 奇遇解锁(encounter_skills.yaml 全池)
  mainlineDrop, // 主线 Boss 首通真解(stages.yaml dropSkillManualId)
  fragment, // 残页集齐解锁(波B 泛化:塔 Boss 层 towers.yaml + 章末重打 stages.yaml dropSkillFragmentId)
  gauntlet, // 断魂庄首通奖励真解(boss_gauntlets.yaml first_clear_reward_skill_id)
  special, // 系统特殊(破招技/joint 共鸣/轻功对决)
}

SkillSource _parseSkillSource(String raw) => switch (raw) {
  'technique' => SkillSource.technique,
  'encounter' => SkillSource.encounter,
  'mainline_drop' => SkillSource.mainlineDrop,
  'fragment' => SkillSource.fragment,
  'gauntlet' => SkillSource.gauntlet,
  'special' => SkillSource.special,
  _ => throw StateError('未知 skill source: $raw(波A A4 红线)'),
};

/// 招式配置（data_schema.md §5.3，纯 Dart，不入 Isar）。
///
/// `parentTechniqueDefId` 为空时，表示该招式由"武学领悟"独立产出（GDD §7.2）。
/// `tier` 奇遇招与 drop 招(真解/残页)填 1-7(沿用 GDD §5.2 七阶节奏 +
/// §5.3 三系锁死,波B 红线 ⑥ drop 招必填),普通心法招式 tier 留空。
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

  /// Positive = generate qi, zero = neutral, negative = spend qi.
  final int qiDelta;
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

  /// 波A build gate:招式流派归属(刚猛/灵巧/阴柔)。
  /// 红线:canInterrupt=true 的破招技**必须**有 style(装配 gate 按
  /// `style == character.school` 过滤);波B 红线 ⑥:drop 招(真解/残页)
  /// 同样必填(装配池注入与 equip gate 按流派);普通心法招留空(流派由所属心法承载)。
  final TechniqueSchool? style;

  /// 波A A4:获取来源。yaml 必填(红线 not-null);直接构造的测试 fixture 可空。
  final SkillSource? source;

  /// 里程碑批(2026-07-16):正式挂载延后标记。true = 此 drop 招(真解/残页)
  /// 定义合法但当前发布阶段暂无 stage/tower/gauntlet 挂载点,豁免红线⑦「每招恰 1 挂载点」
  /// (仅豁免挂载完备性;style+tier 红线⑥仍必守,定义仍需自洽)。正式挂载
  /// (batch3 远征掉落等)时删本标记 = 发布。默认 false。
  /// (Phase C 断魂庄首通奖励 2026-07-19 已转正:锁脉针 source=gauntlet 挂载
  /// 落地,本标记随之删除。)
  final bool mountDeferred;

  /// 招式 per-skill 熟练度效果(可玩性 P1a · 只配真解/招牌/破招技)。null=不配。
  final SkillProficiencyEffects? proficiency;

  /// 2026-06-14 拖招交互:目标类型。single=单体(拖拽到敌人头像指定目标);
  /// aoe=群体(技能栏单击弹简介、长按拖下发、松手即对全体触发,目标=全体/AI 选最佳,
  /// 无需指定落点)。yaml 未填默认 single;
  /// 红线(game_repository `_enforceSkillTargetTypeRedLines`):普攻/合击必 single +
  /// production 至少存在一个 aoe 招(防整体回填丢失)。
  final TargetType targetType;

  /// 第六阶段三人协同:>0 = 命中存活敌人即开「破绽窗口」(不要求蓄力),
  /// 施加该幅度减防,与破招踉跄共用 staggerTicksRemaining/staggerDefenseDownOverride
  /// 字段,刷新不叠加。减防幅度经 boss_charge.interrupt_power_cap 上限 clamp
  /// （封顶减防 = 有效防御有地板，红线 §5.4）。
  final double defenseBreakPct;

  /// C1.3.1 断魂庄:此招蓄力完成且未破招时,对存活对方队每人扣
  /// `qiDrainPct × 最大真气` 的真气(§5.2 苏无咎锁脉针,消费 `QiDrainEffect`)。
  /// 0 = 无剥夺(默认)。schema 硬界 [0, 0.5](>0 段再由 `QiDrainEffect` 兜死
  /// (0, 0.5];load 期 `game_repository._enforceEncounterSkillRedLines` fail-fast,
  /// 越界配置启动即抛而非战斗中崩)。属资源剥夺方向机制,不膨胀伤害(守 §5.4)。
  /// skills.yaml camelCase 例外(§4)。
  final double qiDrainPct;

  const SkillDef({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.powerMultiplier,
    int? qiDelta,
    @Deprecated('请使用 qiDelta') int? internalForceCost,
    required this.cooldownTurns,
    required this.requiresManualTrigger,
    this.parentTechniqueDefId,
    required this.visualEffect,
    this.tier,
    this.narrativeInsightId,
    this.imagePath,
    this.canInterrupt = false,
    this.aiUsePolicy = AiUsePolicy.normal,
    this.style,
    this.source,
    this.mountDeferred = false,
    this.proficiency,
    this.targetType = TargetType.single,
    this.defenseBreakPct = 0.0,
    this.qiDrainPct = 0.0,
  }) : assert(qiDelta != null || internalForceCost != null),
       qiDelta = qiDelta ?? -(internalForceCost ?? 0);

  bool get generatesQi => qiDelta > 0;
  bool get spendsQi => qiDelta < 0;
  int get qiCost => spendsQi ? -qiDelta : 0;

  /// Transitional compatibility for callers migrated in the battle-state task.
  @Deprecated('战斗资源已拆为真气，请使用 qiCost')
  int get internalForceCost => qiCost;

  /// 奇遇招式 = source == encounter(波B 改单一真相源:drop 招补 tier 后
  /// 旧判定 parent==null && tier!=null 会误判真解/残页为奇遇招)。
  bool get isEncounterSkill => source == SkillSource.encounter;

  /// §5.3 三系锁死:有自身 tier(1-7,奇遇招)的招式需 `realmTier.index >= tier-1`
  /// 才可装配(沿 EncounterService.equipEncounterSkill 既有约定 · tier 1↔xueTu idx0)。
  /// tier null(心法招)→ 恒 true,其 §5.3 由所属心法 tier(canPractice)守,非招级。
  /// **解锁≠可装配**:已解锁但境界不达仍 false(师承遗物不例外同理)。
  bool canEquipAtRealm(RealmTier realmTier) =>
      tier == null || realmTier.index >= tier! - 1;

  factory SkillDef.fromYaml(Map<String, dynamic> y) {
    return SkillDef(
      id: y['id'] as String,
      name: y['name'] as String,
      description: y['description'] as String,
      type: SkillType.values.byName(y['type'] as String),
      powerMultiplier: (y['powerMultiplier'] as num).toInt(),
      qiDelta: y.containsKey('qiDelta')
          ? (y['qiDelta'] as num).toInt()
          : -((y['internalForceCost'] as num).toInt()),
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
      style: y['style'] != null
          ? TechniqueSchool.values.byName(y['style'] as String)
          : null,
      source: y['source'] != null
          ? _parseSkillSource(y['source'] as String)
          : null,
      mountDeferred: y['mount_deferred'] as bool? ?? false,
      proficiency: y['proficiency'] != null
          ? SkillProficiencyEffects.fromYaml(
              Map<String, dynamic>.from(y['proficiency'] as Map),
            )
          : null,
      targetType: y['targetType'] != null
          ? TargetType.values.byName(y['targetType'] as String)
          : TargetType.single,
      defenseBreakPct: (y['defenseBreakPct'] as num?)?.toDouble() ?? 0.0,
      qiDrainPct: (y['qiDrainPct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'SkillDef(id=$id, name=$name, type=${type.name}, power=$powerMultiplier)';
}

/// 招式 per-skill 熟练度效果(可玩性 P1a · 只配真解/招牌/破招技)。
/// key=熟练阶段 id(shunShou/shuLian/jingTong/huaJing),value=该阶段起生效的增量。
/// damage_pct 与全局阶段倍率综合后仍受 §2.5 130% cap(见 SkillProficiency.combinedMult)。
class SkillProficiencyEffects {
  final Map<String, double> _damagePct;
  final Map<String, int> _cooldownDelta;
  final Map<String, double> _interruptPowerPct;
  final Map<String, int> _interruptWindowBonus;

  const SkillProficiencyEffects(
    this._damagePct,
    this._cooldownDelta,
    this._interruptPowerPct,
    this._interruptWindowBonus,
  );

  double damagePctAt(String stageId) => _damagePct[stageId] ?? 0.0;
  int cooldownDeltaAt(String stageId) => _cooldownDelta[stageId] ?? 0;

  /// interrupt_power_pct(波A 方向 b 已消费):破招踉跄期有效减防
  /// = staggerDefenseDown × (1 + 此值),clamp 到 interruptPowerCap。
  /// 消费点 default_ground_strategy 破招结算;红线 _enforceInterruptSkillRedLines。
  double interruptPowerPctAt(String stageId) =>
      _interruptPowerPct[stageId] ?? 0.0;
  int interruptWindowBonusAt(String stageId) =>
      _interruptWindowBonus[stageId] ?? 0;

  factory SkillProficiencyEffects.fromYaml(Map<String, dynamic> y) {
    final effects = (y['effects'] as Map?)?.cast<String, dynamic>() ?? const {};
    final dmg = <String, double>{};
    final cd = <String, int>{};
    final ip = <String, double>{};
    final iw = <String, int>{};
    effects.forEach((stage, v) {
      final m = Map<String, dynamic>.from(v as Map);
      if (m['damage_pct'] != null) {
        dmg[stage] = (m['damage_pct'] as num).toDouble();
      }
      if (m['cooldown_delta'] != null) {
        cd[stage] = (m['cooldown_delta'] as num).toInt();
      }
      if (m['interrupt_power_pct'] != null) {
        ip[stage] = (m['interrupt_power_pct'] as num).toDouble();
      }
      if (m['interrupt_window_bonus_ticks'] != null) {
        iw[stage] = (m['interrupt_window_bonus_ticks'] as num).toInt();
      }
    });
    return SkillProficiencyEffects(dmg, cd, ip, iw);
  }
}
