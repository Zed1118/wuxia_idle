import '../../../shared/strings.dart';

/// 上下文帮助系统的可解释对象（2026-06-16）。
///
/// 一个 [HelpTopic] = 玩家会在高频页面看到的一个术语 / 机制。调用侧只声明 topic，
/// 文案与（可选的）百科跳转由 [HelpCatalog] 派生。
enum HelpTopic {
  // 角色四属性 + 派生五数值 + 养成
  constitution,
  enlightenment,
  agility,
  fortune,
  hp,
  internalForce,
  speed,
  criticalRate,
  evasionRate,
  cultivation,
  resonance,
  realm,
  // 装备
  equipmentTier,
  strengthening,
  forging,
  heartBloodCrystal,
  lineageHeritage,
  // 心法
  mainTechnique,
  assistTechnique,
  school,
  synergy,
  // 战斗 / 成长（阶段三）
  combatAdvanced,
  seclusion,
}

/// `topic → (label, 短释义, 可空 codex id)` 的薄绑定。
///
/// **防双真相源**：[label] / [shortText] 引用 [UiStrings] 常量（唯一中文 sink）；
/// 解锁档（step）与分类（category）**不在此声明**，由 [codexEntryId] 经 `CodexIndex`
/// 派生。新增 topic 时只补本绑定 + UiStrings 文案，不要复制 step / 中文。
class HelpBinding {
  /// 术语显示名，例如「根骨」。引用 UiStrings 既有 label 常量。
  final String label;

  /// 悬停 / 长按显示的一句话释义。引用 UiStrings.glossaryXxx。
  final String shortText;

  /// 对应「江湖见闻录」长说明条目 id；**必须是 `CodexIndex.entries` 已登记 id**。
  /// 命中则页面级 [ContextHelpButton] 可跳详情；null = 仅出 tooltip。
  final String? codexEntryId;

  const HelpBinding({
    required this.label,
    required this.shortText,
    this.codexEntryId,
  });
}

/// 集中维护全部术语绑定。中文一律走 [UiStrings]，本表只做结构映射。
class HelpCatalog {
  HelpCatalog._();

  static const Map<HelpTopic, HelpBinding> bindings = {
    // —— 角色属性（无独立百科条目，仅 tooltip）——
    HelpTopic.constitution: HelpBinding(
      label: UiStrings.attrConstitution,
      shortText: UiStrings.glossaryConstitution,
    ),
    HelpTopic.enlightenment: HelpBinding(
      label: UiStrings.attrEnlightenment,
      shortText: UiStrings.glossaryEnlightenment,
    ),
    HelpTopic.agility: HelpBinding(
      label: UiStrings.attrAgility,
      shortText: UiStrings.glossaryAgility,
    ),
    HelpTopic.fortune: HelpBinding(
      label: UiStrings.attrFortune,
      shortText: UiStrings.glossaryFortune,
    ),
    // —— 派生数值 ——
    HelpTopic.hp: HelpBinding(
      label: UiStrings.statHp,
      shortText: UiStrings.glossaryHp,
    ),
    HelpTopic.internalForce: HelpBinding(
      label: UiStrings.statInternalForce,
      shortText: UiStrings.glossaryInternalForce,
    ),
    HelpTopic.speed: HelpBinding(
      label: UiStrings.statSpeed,
      shortText: UiStrings.glossarySpeed,
    ),
    HelpTopic.criticalRate: HelpBinding(
      label: UiStrings.statCriticalRate,
      shortText: UiStrings.glossaryCriticalRate,
    ),
    HelpTopic.evasionRate: HelpBinding(
      label: UiStrings.statEvasionRate,
      shortText: UiStrings.glossaryEvasionRate,
    ),
    // —— 养成 / 境界（挂百科）——
    HelpTopic.cultivation: HelpBinding(
      label: UiStrings.labelCultivation,
      shortText: UiStrings.glossaryCultivation,
      codexEntryId: 'techniques_and_styles',
    ),
    HelpTopic.resonance: HelpBinding(
      label: UiStrings.labelResonance,
      shortText: UiStrings.glossaryResonance,
      codexEntryId: 'resonance',
    ),
    HelpTopic.realm: HelpBinding(
      label: UiStrings.profileRealmLabel,
      shortText: UiStrings.glossaryRealm,
      codexEntryId: 'realm',
    ),
    // —— 装备 ——
    HelpTopic.equipmentTier: HelpBinding(
      label: UiStrings.labelEquipmentTier,
      shortText: UiStrings.glossaryEquipmentTier,
      codexEntryId: 'equipment_tiers',
    ),
    HelpTopic.strengthening: HelpBinding(
      label: UiStrings.tabEnhance,
      shortText: UiStrings.glossaryStrengthening,
      codexEntryId: 'strengthening',
    ),
    HelpTopic.forging: HelpBinding(
      label: UiStrings.tabForging,
      shortText: UiStrings.glossaryForging,
      codexEntryId: 'weapon_forging',
    ),
    HelpTopic.heartBloodCrystal: HelpBinding(
      label: UiStrings.labelHeartBloodCrystal,
      shortText: UiStrings.glossaryHeartBloodCrystal,
    ),
    HelpTopic.lineageHeritage: HelpBinding(
      label: UiStrings.lineageHeritageLabel,
      shortText: UiStrings.glossaryLineageHeritage,
      codexEntryId: 'master_disciple',
    ),
    // —— 心法 ——
    HelpTopic.mainTechnique: HelpBinding(
      label: UiStrings.techniqueRoleMain,
      shortText: UiStrings.glossaryMainTechnique,
      codexEntryId: 'techniques_and_styles',
    ),
    HelpTopic.assistTechnique: HelpBinding(
      label: UiStrings.techniqueRoleAssist,
      shortText: UiStrings.glossaryAssistTechnique,
      codexEntryId: 'techniques_and_styles',
    ),
    HelpTopic.school: HelpBinding(
      label: UiStrings.labelSchool,
      shortText: UiStrings.glossarySchool,
      codexEntryId: 'three_styles_detail',
    ),
    HelpTopic.synergy: HelpBinding(
      label: UiStrings.synergyActiveLabel,
      shortText: UiStrings.glossarySynergy,
      codexEntryId: 'techniques_and_styles',
    ),
    // —— 战斗 / 成长 ——
    HelpTopic.combatAdvanced: HelpBinding(
      label: UiStrings.labelCombatAdvanced,
      shortText: UiStrings.glossaryCombatAdvanced,
      codexEntryId: 'combat_advanced',
    ),
    HelpTopic.seclusion: HelpBinding(
      label: UiStrings.seclusionEnterCaption,
      shortText: UiStrings.glossarySeclusion,
      codexEntryId: 'retreat',
    ),
  };

  /// 取绑定；topic 必登记，否则属编程错误（[help_catalog_test] 守全覆盖）。
  static HelpBinding of(HelpTopic topic) => bindings[topic]!;
}

/// 纯判定：页面级帮助 `?` 是否可跳百科（解锁）。
///
/// 抽出为纯函数以便单测，不依赖 widget / provider。语义对齐 `codex_tab` 既有逻辑
/// （`step <= currentStep && isLoaded`），lore 类 [requiredStep] 传 null 视为 0。
bool helpEntryUnlocked({
  required int? requiredStep,
  required bool isLoaded,
  required int currentStep,
}) {
  return isLoaded && (requiredStep ?? 0) <= currentStep;
}
