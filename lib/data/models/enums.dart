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

/// 招式类型（GDD §5.3）。
enum SkillType {
  normalAttack,  // 普通攻击  倍率 500
  powerSkill,    // 强力技能  倍率 1000-3000
  ultimate,      // 大招      倍率 5000+
  jointSkill,    // 人剑合一招式（共鸣度默契阶段解锁）
}

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
enum LineageRole {
  founder,        // 开派祖师（玩家本体）
  disciple,       // 弟子
  grandDisciple,  // 徒孙（绝顶境界后解锁）
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.5 内容 / 系统
// ─────────────────────────────────────────────────────────────────────────────

/// 关卡类型。
enum StageType {
  mainline,  // 主线（GDD §8.1）
  tower,     // 爬塔（问鼎江湖，GDD §8.2）
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

/// 时辰（闭关加成用，GDD §7.3）。
enum TimeOfDayPeriod {
  ziShi,    // 子时 23:00-1:00
  zhengWu,  // 正午 11:00-13:00
  other,    // 其他时段（无加成）
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
}

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
