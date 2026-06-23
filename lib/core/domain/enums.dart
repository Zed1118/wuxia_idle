/// 全部枚举定义（data_schema.md §2 / GDD 对应章节见每个枚举上方注释）。
///
/// 集中维护规则：所有 @Enumerated(EnumType.name) 字段都引用此文件中的枚举，
/// 后续以"枚举名字符串"落盘，**任何重命名都会让旧存档失效**。
///
/// GDD 章节索引：
/// - 境界 / 修炼度  → §3.1 / §4.3
/// - 装备 / 心法品阶 → §3.2 / §3.3
/// - 装备槽位 / 开锋 → §6.5
/// - 流派 / 招式     → §4.4 / §5.3
/// - 共鸣度          → §6.4
/// - 角色稀有度 / 师徒 → §4.1 / §7.1
/// - 关卡 / 闭关地图 / 时辰 → §8.1 / §8.2 / §8.3 / §7.3
/// - 物品 / 事件     → §6.3 / §9.2
library;

// ─────────────────────────────────────────────────────────────────────────────
// 2.1 境界相关
// ─────────────────────────────────────────────────────────────────────────────

/// 境界大阶（7 阶，GDD §3.1）。
enum RealmTier {
  xueTu,     // 1 学徒
  sanLiu,    // 2 三流
  erLiu,     // 3 二流
  yiLiu,     // 4 一流
  jueDing,   // 5 绝顶
  zongShi,   // 6 宗师
  wuSheng,   // 7 武圣
}

/// 境界 7 层（每个大阶内部，GDD §3.1）。
enum RealmLayer {
  qiMeng,    // 1 启蒙
  ruMen,     // 2 入门
  shuLian,   // 3 熟练
  jingTong,  // 4 精通
  yuanShu,   // 5 圆熟
  huaJing,   // 6 化境
  dengFeng,  // 7 登峰
}

/// 修炼度 9 层（每本心法独立累积，GDD §4.3）。严格不与境界 7 层重名。
enum CultivationLayer {
  chuKui,     // 1 初窥  100%
  xiaoCheng,  // 2 小成  115%
  zhongCheng, // 3 中成  130%
  daCheng,    // 4 大成  150%
  yuanMan,    // 5 圆满  175%
  dianFeng,   // 6 巅峰  200%
  tongShen,   // 7 通神  230%
  wuXia,      // 8 无瑕  260%
  jiJing,     // 9 极境  300%
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.2 装备 / 心法品阶
// ─────────────────────────────────────────────────────────────────────────────

/// 装备品阶（7 阶，GDD §3.2），与境界一一对应。
enum EquipmentTier {
  xunChang,    // 1 寻常货
  xiangYang,   // 2 像样货
  haoJiaHuo,   // 3 好家伙
  liQi,        // 4 利器
  zhongQi,     // 5 重器
  baoWu,       // 6 宝物
  shenWu,      // 7 神物
}

/// 心法品阶（7 阶，GDD §3.3）。
enum TechniqueTier {
  ruMenGong,         // 1 入门功
  changLianGong,     // 2 常练功
  mingJiaGong,       // 3 名家功
  menPaiJueXue,      // 4 门派绝学
  jiangHuMiChuan,    // 5 江湖秘传
  shiChuanShenGong,  // 6 失传神功
  chuanShuoShenGong, // 7 传说神功
}

/// 装备槽位。
enum EquipmentSlot {
  weapon,     // 武器
  armor,      // 护甲
  accessory,  // 饰品
}

/// 开锋槽位类型（+10 / +15 / +19 解锁，GDD §6.5）。
enum ForgingSlotType {
  attack,        // 攻击强化
  speed,         // 速度强化
  lifesteal,     // 吸血
  pierce,        // 破甲
  specialSkill,  // 专属技能（仅第三槽 +19）
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.3 心法 / 流派 / 招式
// ─────────────────────────────────────────────────────────────────────────────

/// 三流派（GDD §4.4）。克制关系：刚猛 → 阴柔 → 灵巧 → 刚猛。
enum TechniqueSchool {
  gangMeng,  // 刚猛 → 克阴柔（震伤）
  lingQiao,  // 灵巧 → 克刚猛（暴击+20%）
  yinRou,    // 阴柔 → 克灵巧（内伤 debuff）
}

/// 心法在角色身上的定位（GDD §4.2）。
enum TechniqueRole {
  main,    // 主修（每个角色 1 本）
  assist,  // 辅修（每个角色最多 3 本）
}

/// 招式的自动战斗使用策略(P0 破招)。
/// - normal: AI 正常选用(按倍率)
/// - saveForInterrupt: AI 平时不放,仅敌人蓄力时用于破招
/// - manualOnly: P0 留位,仅玩家手动放(暂不实装独立行为)
enum AiUsePolicy { normal, saveForInterrupt, manualOnly }

/// 招式类型（GDD §5.3）。
enum SkillType {
  normalAttack,  // 普通攻击  倍率 500
  powerSkill,    // 强力技能  倍率 1000-3000
  ultimate,      // 大招      倍率 5000+
  jointSkill,    // 人剑合一招式（共鸣度默契阶段解锁）
}

/// 招式目标类型(2026-06-14 拖招交互重做)。
/// - single: 单体技，拖拽到敌人头像指定目标后触发。
/// - aoe: 群体技，技能栏单击弹简介浮层，长按拖下发、松手即对全体触发
///   (目标=全体/AI 选最佳，无需指定落点)。
/// 红线:ultimate/powerSkill 的 targetType yaml 必填(loader fail-fast);
/// normalAttack/jointSkill 留空 → fromYaml 默认 single。
enum TargetType { single, aoe }

/// 共鸣度阶段（GDD §6.4，派生值，不入库）。
enum ResonanceStage {
  shengShu,         // 生疏  0~100      无加成
  chenShou,         // 趁手  100~500    +10%
  moQi,             // 默契  500~2000   +20%，解锁人剑合一
  xinJianTongLing,  // 心剑通灵 2000+   +30%，剑鸣特效
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.4 角色相关
// ─────────────────────────────────────────────────────────────────────────────

/// 角色稀有度（GDD §4.1，出生时根据四属性总和决定，不可重 roll）。
enum RarityTier {
  yongCai,   // 庸才   16-17  15%
  xunChang,  // 寻常   18-19  35%
  biaoZhun,  // 标准   20     25%
  ziYou,     // 资优   21-22  18%
  tianCai,   // 天才   23     5%
  jueShi,    // 绝世   24     2%
}

/// 师徒角色定位（GDD §7.1）。
/// senior=大弟子 / junior=二弟子（第七阶段批三:开局渐进解锁 + 战斗职责三分）。
/// disciple 值保留:老档(0.25.0 前)反序列化安全,迁移后按 founder.discipleIds 顺序
/// 重映射为 senior/junior;通过收徒系统新增的通用弟子仍可为 disciple。
enum LineageRole {
  founder,        // 开派祖师（玩家本体）
  disciple,       // 弟子（通用/老档过渡值）
  senior,         // 大弟子（批三:破防开窗职责）
  junior,         // 二弟子（批三:破招打断控场职责）
  grandDisciple,  // 徒孙（绝顶境界后解锁）
}

extension LineageRoleX on LineageRole {
  /// 是否「弟子」身份(含命名大弟子 senior / 二弟子 junior 与通用收徒 disciple)。
  /// 用于「是否非祖师弟子」判定;**不含** founder / grandDisciple,保留原 `== disciple` 语义边界。
  bool get isDiscipleRole =>
      this == LineageRole.disciple ||
      this == LineageRole.senior ||
      this == LineageRole.junior;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.5 内容 / 系统
// ─────────────────────────────────────────────────────────────────────────────

/// 关卡类型。
enum StageType {
  mainline,    // 主线（GDD §8.1）
  tower,       // 爬塔（问鼎江湖，GDD §8.2）
  innerDemon,  // 心魔关(1.0 P2.2 §12.1,7 关拦截 wuSheng 7 层突破 / 镜像玩家 +10-20%)
  lightFoot,   // 轻功对决(1.0 P3.1 §12.3,5 关 yiLiu/jueDing 平行支线 / terrain modifier 地形机制)
  massBattle,  // 群战守城(1.0 P3.2 §12.3,5 关 yiLiu/jueDing 平行支线 / wave-based 守城 + 阵型 3 选 1)
  pvp,         // 异步 PVP(1.0 P3.3 §12.3,本地阵容快照 + ELO 段位 / NoopPvpSync mock,真 Supabase 留 1.1+)
}

/// 战斗机制地形(1.0 P3.1 §12.3,GDD v1.11)。
///
/// 进 LightFootStrategy 战斗机制,与 [EncounterBiome] 解耦:
///   - [EncounterBiome] 是 stage 标签层(奇遇 trigger 维度,18 项 mountainPath...)
///   - [TerrainBiome] 是战斗机制层(LightFootStrategy 烘焙 terrain modifier
///     到 BattleCharacter critRate/evasionRate/defenseRate/damage delta)
///
/// terrain modifier 数值见 `numbers.yaml light_foot.terrain_modifiers`。
/// 双方对等生效(地形中立),clamp(0.0, 0.95) 防破红线。
enum TerrainBiome {
  water,    // 水面(渡口/急流):evasion +0.15 / defense -0.10
  rooftop,  // 屋脊(青瓦/飞檐):crit +0.10 / damage ×1.15 / defense -0.05
  bamboo,   // 竹林(密竹/江南):evasion +0.20 / damage ×0.90
}

/// 群战守城阵型(1.0 P3.2 §12.3,GDD v1.13)。
///
/// 战前 3 选 1,进 [MassBattleStrategy] 入口 `applyFormationTo` 一次性烘焙
/// modifier 到 BattleCharacter critRate/evasionRate/defenseRate/
/// attackPowerMultiplier(**仅玩家 leftTeam** 生效,敌方不沾;烘焙后 idempotent)。
///
/// 阵型数值见 `numbers.yaml mass_battle.formations`,clamp(0.0, 0.95)
/// 防 §5.4 红线破(沿 LightFootStrategy `_bake` clamp 体例)。
///
/// 3 阵型定位:
///   - [yanXing] 雁行:攻势启 — crit +0.10 / defense -0.05
///   - [baGua]   八卦:守势固 — defense +0.10 / evasion +0.05
///   - [fengShi] 锋矢:突击强 — damage ×1.10 / crit +0.05
enum Formation {
  yanXing,   // 雁行:攻势 crit +0.10 / defense -0.05
  baGua,     // 八卦:守势 defense +0.10 / evasion +0.05
  fengShi,   // 锋矢:突击 damage ×1.10 / crit +0.05
}

/// 关卡解锁状态（Phase 3 T34 主线进度）。
///
/// UI 三态渲染：
///   - locked    → 灰色 + 锁图标，点击无响应
///   - available → 主色按钮，点击进入 StageEntryFlow
///   - cleared   → 绿勾，点击可重玩（不再触发首通逻辑）
enum StageStatus {
  locked,
  available,
  cleared,
}

/// 爬塔 Boss 层类型（Phase 3 T40，GDD §8.2 + CLAUDE §7）。
///
/// 30 层共 6 Boss：
///   - minor：小 Boss，分布在 5 / 15 / 25 层
///   - major：大 Boss，分布在 10 / 20 / 30 层
///
/// 普通层 bossKind 为 null。
enum TowerBossKind {
  minor,
  major,
}

/// 爬塔层解锁状态（Phase 3 T41）。
///
/// 与 [StageStatus] 同义但隔离，避免主线 / 爬塔 enum 复用产生跨模块耦合。
enum TowerFloorStatus {
  locked,
  available,
  cleared,
}

/// 闭关地图（GDD §8.3）。
enum RetreatMapType {
  shanLin,       // 山林（平均产出）
  guJianZhong,   // 古剑冢（兵器掉率 +50%）
  cangJingGe,    // 藏经阁（心法领悟 +50%）
  xuanYaPuBu,    // 悬崖瀑布（内力增长 +50%）
  duanYaJueBi,   // 断崖绝壁（仅宗师以上可去）
}

/// 场景生境(C-W14-2 奇遇 trigger 维度)。
///
/// 与 [RetreatMapType] 区别:RetreatMapType 是"闭关地图 id",
/// EncounterBiome 是"场景类型"(可跨地图/关卡复用)。例:`shanLin` 闭关 +
/// stage_01_01 山门外都是 [mountainForest]。
///
/// stages.yaml / numbers.yaml retreat.maps 配置时**允许空字段**(向后兼容,
/// 不强求每关都标 biome)。但若配,必须是下面枚举值之一,加载层强校验。
enum EncounterBiome {
  mountainPath,    // 山道(stage_01_03 黑风岭 / stage_03_04 雁门旧事)
  inn,             // 客栈茶店(stage_01_02 荒山野店)
  dock,            // 渡口水滨(stage_01_05 风雨渡口)
  cityWall,        // 城外/城内(stage_01_04 洛阳城外 / stage_03_01 武林会)
  escortRoad,      // 镖路官道(stage_02_01 镖局护送)
  teaHouse,        // 茶馆茶亭(stage_02_02 茶馆论剑 / 奇遇 cha_ting_dui_ju)
  smithy,          // 铸剑铺(stage_02_03 春水堂)
  drillGround,     // 校场擂台(stage_02_04 / stage_03_02 / stage_03_05)
  alley,           // 巷弄(stage_02_05 巷中夜雨)
  temple,          // 寺院经阁(stage_03_03 山寺夜话 / 闭关 cangJingGe)
  mountainForest,  // 山林(stage_01_01 山门外 / 闭关 shanLin)
  swordTomb,       // 古剑冢(闭关 guJianZhong)
  cliffWaterfall,  // 悬崖瀑布(闭关 xuanYaPuBu)
  cliff,           // 断崖绝壁(闭关 duanYaJueBi)
  bambooForest,    // 竹林(奇遇 bamboo_listen_rain · GDD §7.2 example)
  desert,          // 大漠戈壁(stage_04_03 沙海迷踪 / 1.0 P2 西域续章)
  frontier,        // 边塞关隘(stage_04_02 玉门古道 / stage_04_05 嘉峪关)
  innerRealm,      // 心魔境(1.0 P2.2 §12.1,stage_inner_demon_01..07 抽象内省境)
}

/// 天气/时段(C-W14-2 奇遇 trigger 维度)。
///
/// Demo 阶段 5 个值。[night] 严格不是天气而是时段,为 schema 简化合并入此枚举,
/// 不另起 TimeOfDayPhase 维度。clear 是默认"无特别天气"。
enum EncounterWeather {
  clear,    // 晴(默认)
  rain,     // 雨(stage_01_05 风雨渡口 / 闭关 xuanYaPuBu)
  snow,     // 雪(闭关 duanYaJueBi)
  mist,     // 雾(stage_01_03 黑风岭 / 闭关 guJianZhong)
  night,    // 夜(stage_02_05 巷中夜雨 / stage_03_03 山寺夜话)
}

/// 时辰（闭关加成用，GDD §7.3）。
enum TimeOfDayPeriod {
  ziShi,    // 子时 23:00-1:00
  zhengWu,  // 正午 11:00-13:00
  other,    // 其他时段（无加成）
}

/// 农历节日（GDD §12.4 W16 接口预留）。
///
/// **不影响数值红线**（GDD §12.4 明文「节日活动：不影响数值」）—— 仅用作
/// encounter trigger 维度 + UI「今日节日」chip 显示。农历转公历按年 hardcode
/// 在 numbers.yaml `festivals.days_2026`（沿用节气 §12 #13 决议体例，不引入农历库）。
///
/// Demo 阶段 8 个真实传统节日：除夕 / 春节 / 元宵 / 清明 / 端午 / 七夕 / 中秋 / 重阳。
///
/// 清明既是节气也是节日：节气走 numbers.yaml `retreat.solar_term_bonus.days_2026`
/// (闭关 +30% 维度),节日走 `festivals.days_2026` 配 encounter trigger 维度 + chip。
/// 同日双重身份不冲突,各走各通道(GDD §8.4 节日通道独立于节气通道)。
enum Festival {
  chuXi,        // 除夕   农历腊月最后一天（春节前一天）
  chunJie,      // 春节   农历正月初一
  yuanXiao,     // 元宵   农历正月十五
  qingMingJie,  // 清明   公历清明节（既节气又节日）
  duanWu,       // 端午   农历五月初五
  qiXi,         // 七夕   农历七月初七
  zhongQiu,     // 中秋   农历八月十五
  chongYang,    // 重阳   农历九月初九
}

/// 闭关 session 状态（Phase 3 T48）。
enum RetreatStatus {
  active,     // 进行中（未收功）
  completed,  // 已收功
  abandoned,  // 已放弃（切换地图时旧 session 置此）
}

/// 背包物品类型。
enum ItemType {
  moJianShi,        // 磨剑石（强化材料）
  xinXueJieJing,    // 心血结晶（强化保底，GDD §6.3）
  jingYanDan,       // 经验丹
  techniqueScroll,  // 心法秘籍
  miscMaterial,     // 杂项材料
  silver;           // 银两（货币）

  /// 根据已知 item defId 推断 [ItemType]，未知 id 兜底 [miscMaterial]。
  /// 入库（tower/mainline 写背包）与展示（victory dialog drop banner）共用。
  static ItemType fromDefId(String defId) {
    // 前缀匹配优先（材料经济 P2：经验丹 3 档 + 秘籍 9 本共 12 defId，
    // 避免逐个 case 冗长易漏静默吞 miscMaterial）。
    if (isTechniqueScrollDefId(defId)) return ItemType.techniqueScroll;
    if (defId.startsWith('item_jingyandan')) return ItemType.jingYanDan;
    switch (defId) {
      case 'item_mojianshi':
        return ItemType.moJianShi;
      case 'item_xinxuejiejing':
        return ItemType.xinXueJieJing;
      case 'item_silver':
        return ItemType.silver;
      default:
        return ItemType.miscMaterial;
    }
  }
}

/// 心法秘籍 defId 判定（前缀 `item_scroll_`）的 canonical 谓词。
///
/// 秘籍「首通必得」语义的单一真相源：mainline runtime 写背包门控
/// (`shouldSkipScrollDrop`)、掉落传闻 preview 逐条门控
/// (`DropRumorTable.fromDropTable` scrollOnly)、以及 [ItemType.fromDefId]
/// 三方共用，避免 `item_scroll_` 前缀散写多处 drift（F2/2026-06-23 续48）。
bool isTechniqueScrollDefId(String defId) => defId.startsWith('item_scroll_');

/// 游戏事件类型（"昨晚发生的事"，GDD §9.2）。
enum GameEventType {
  retreatCompleted,    // 闭关完成
  adventureTriggered,  // 奇遇触发
  equipmentObtained,   // 获得装备
  techniqueLearned,    // 习得心法
  skillEnlightened,    // 武学领悟
  realmBreakthrough,   // 境界突破
  resonanceUpgraded,   // 共鸣度晋升
  bossDefeated,        // 击败 Boss
  disciplePromoted,    // 弟子突破
}
