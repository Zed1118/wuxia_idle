import '../../../core/domain/enums.dart';
import '../../battle_record/domain/boss_memory_source.dart';
import '../../encounter/domain/encounter_def.dart' show AttributeKey;
import 'battle_state.dart' show BattleResult;

/// enum → 中文显示名的集中本地化层。
///
/// **这是 CLAUDE.md §5.6 正名的合法集中式 sink**(v1.20):枚举→显示名映射集中
/// 在此,带 `switch` 穷尽检查(枚举增删时编译期报漏翻译),与 `UiStrings` 同类,
/// 不算「散写硬编码」。新增枚举显示名走这里,不要在调用点内联中文。
class EnumL10n {
  EnumL10n._();

  static String battleResult(BattleResult r) {
    return switch (r) {
      BattleResult.leftWin => '左队胜',
      BattleResult.rightWin => '右队胜',
      BattleResult.draw => '平局',
    };
  }

  static String school(TechniqueSchool s) {
    return switch (s) {
      TechniqueSchool.gangMeng => '刚猛',
      TechniqueSchool.lingQiao => '灵巧',
      TechniqueSchool.yinRou => '阴柔',
    };
  }

  static String realmTier(RealmTier t) {
    return switch (t) {
      RealmTier.xueTu => '学徒',
      RealmTier.sanLiu => '三流',
      RealmTier.erLiu => '二流',
      RealmTier.yiLiu => '一流',
      RealmTier.jueDing => '绝顶',
      RealmTier.zongShi => '宗师',
      RealmTier.wuSheng => '武圣',
    };
  }

  /// 境界 7 层（GDD §3.1，与 CultivationLayer 严格不同名）。
  static String realmLayer(RealmLayer l) {
    return switch (l) {
      RealmLayer.qiMeng => '启蒙',
      RealmLayer.ruMen => '入门',
      RealmLayer.shuLian => '熟练',
      RealmLayer.jingTong => '精通',
      RealmLayer.yuanShu => '圆熟',
      RealmLayer.huaJing => '化境',
      RealmLayer.dengFeng => '登峰',
    };
  }

  static String skillType(SkillType t) {
    return switch (t) {
      SkillType.normalAttack => '普攻',
      SkillType.powerSkill => '强力技能',
      SkillType.ultimate => '大招',
      SkillType.jointSkill => '人剑合一',
    };
  }

  /// 招式目标类型(批次 1.3 简介浮层 · 拖招手势)。
  static String targetType(TargetType t) {
    return switch (t) {
      TargetType.single => '单体',
      TargetType.aoe => '群体',
    };
  }

  /// `<tier><layer>` 完整境界：例 `wuSheng/dengFeng → "武圣登峰"`。
  static String realm(RealmTier t, RealmLayer l) =>
      '${realmTier(t)}${realmLayer(l)}';

  /// 流派克制特效字符串（numbers.yaml `techniques.schools[].extra_effect`）。
  ///
  /// 已知值：`extra_quake_dmg` / `crit_rate_+0.20` / `internal_injury`。
  /// 未知值原样返回（兜底，不抛错——日志层不应中断战斗主流程）。
  static String attackEffect(String key) {
    return switch (key) {
      'extra_quake_dmg' => '附带震伤',
      'crit_rate_+0.20' => '暴击率 +20%',
      'internal_injury' => '施加内伤',
      _ => key,
    };
  }

  /// §12.1 #7 v1.4 阴柔内伤 dot 发作日志(actor 未死亡)。
  static String internalInjuryTick(String actorName, int damage) =>
      '$actorName 内伤发作,扣 $damage 血';

  /// §12.1 #7 v1.4 阴柔内伤 dot 致死日志(actor 死亡)。
  static String internalInjuryFatal(String actorName) =>
      '$actorName 内伤崩裂,经脉俱断';

  /// P0 破招:Boss 起手蓄力招牌技日志。
  static String chargeStart(String name, String skill) => '$name 凝气蓄势:$skill';

  /// P0 破招:Boss 蓄力中(未满)跳过本次行动日志。
  static String charging(String name) => '$name 蓄力中……';

  /// P0 破招:破招成功(打断蓄力)日志。
  static String interrupted(String breaker, String boss) =>
      '$breaker 一击破招,$boss 招式溃散!';

  /// P0 破招:踉跄跳过本次行动日志。
  static String staggered(String name) => '$name 踉跄难稳。';

  /// 第七阶段批二 ①:Boss 转阶段日志(血量跌破阈值进入下一阶段)。
  static String bossPhaseTransition(String name, int phaseIndex) =>
      '$name 气势陡变,进入第 ${phaseIndex + 1} 阶!';

  /// 心法修炼度 9 层（GDD §4.3，与境界 7 层 [realmLayer] 严格不同名）。
  static String cultivationLayer(CultivationLayer l) {
    return switch (l) {
      CultivationLayer.chuKui => '初窥',
      CultivationLayer.xiaoCheng => '小成',
      CultivationLayer.zhongCheng => '中成',
      CultivationLayer.daCheng => '大成',
      CultivationLayer.yuanMan => '圆满',
      CultivationLayer.dianFeng => '巅峰',
      CultivationLayer.tongShen => '通神',
      CultivationLayer.wuXia => '无瑕',
      CultivationLayer.jiJing => '极境',
    };
  }

  /// 装备品阶（GDD §3.2，与境界一一对应）。
  static String equipmentTier(EquipmentTier t) {
    return switch (t) {
      EquipmentTier.xunChang => '寻常货',
      EquipmentTier.xiangYang => '像样货',
      EquipmentTier.haoJiaHuo => '好家伙',
      EquipmentTier.liQi => '利器',
      EquipmentTier.zhongQi => '重器',
      EquipmentTier.baoWu => '宝物',
      EquipmentTier.shenWu => '神物',
    };
  }

  /// 心法品阶（GDD §3.3）。
  static String techniqueTier(TechniqueTier t) {
    return switch (t) {
      TechniqueTier.ruMenGong => '入门功',
      TechniqueTier.changLianGong => '常练功',
      TechniqueTier.mingJiaGong => '名家功',
      TechniqueTier.menPaiJueXue => '门派绝学',
      TechniqueTier.jiangHuMiChuan => '江湖秘传',
      TechniqueTier.shiChuanShenGong => '失传神功',
      TechniqueTier.chuanShuoShenGong => '传说神功',
    };
  }

  /// 装备槽位（GDD §6.5）。
  static String equipmentSlot(EquipmentSlot s) {
    return switch (s) {
      EquipmentSlot.weapon => '武器',
      EquipmentSlot.armor => '护甲',
      EquipmentSlot.accessory => '饰品',
    };
  }

  /// 共鸣度阶段（GDD §6.4）。
  static String resonanceStage(ResonanceStage s) {
    return switch (s) {
      ResonanceStage.shengShu => '生疏',
      ResonanceStage.chenShou => '趁手',
      ResonanceStage.moQi => '默契',
      ResonanceStage.xinJianTongLing => '心剑通灵',
    };
  }

  /// 开锋槽位类型（GDD §6.5）。
  static String forgingSlotType(ForgingSlotType t) {
    return switch (t) {
      ForgingSlotType.attack => '攻击',
      ForgingSlotType.speed => '速度',
      ForgingSlotType.lifesteal => '吸血',
      ForgingSlotType.pierce => '破甲',
      ForgingSlotType.specialSkill => '专属技能',
    };
  }

  /// 背包物品类型（W15 #30 P3 后续 A · 物料 Tab）。
  static String itemType(ItemType t) {
    return switch (t) {
      ItemType.moJianShi => '磨剑石',
      ItemType.xinXueJieJing => '心血结晶',
      ItemType.jingYanDan => '经验丹',
      ItemType.techniqueScroll => '心法秘籍',
      ItemType.miscMaterial => '杂项材料',
      ItemType.silver => '银两',
    };
  }

  /// 角色 4 项属性（GDD §4.1）。
  static String attributeKey(AttributeKey k) {
    return switch (k) {
      AttributeKey.constitution => '根骨',
      AttributeKey.enlightenment => '悟性',
      AttributeKey.agility => '身法',
      AttributeKey.fortune => '机缘',
    };
  }

  /// 轻功地形（GDD §轻功）。null 表示平地（无特殊地形修正）。
  static String terrainBiome(TerrainBiome? biome) {
    return switch (biome) {
      TerrainBiome.water => '水面',
      TerrainBiome.rooftop => '屋脊',
      TerrainBiome.bamboo => '竹林',
      null => '平地',
    };
  }

  /// 守城试炼阵型（mass_battle）。
  static String formation(Formation f) {
    return switch (f) {
      Formation.yanXing => '雁行',
      Formation.baGua => '八卦',
      Formation.fengShi => '锋矢',
    };
  }

  /// 农历节日（W16 framework + W17 扩 chuXi/qingMingJie）。Demo 阶段 8 个传统节日。
  static String festival(Festival f) {
    return switch (f) {
      Festival.chuXi => '除夕',
      Festival.chunJie => '春节',
      Festival.yuanXiao => '元宵',
      Festival.qingMingJie => '清明',
      Festival.duanWu => '端午',
      Festival.qiXi => '七夕',
      Festival.zhongQiu => '中秋',
      Festival.chongYang => '重阳',
    };
  }

  /// 战绩册 Boss 来源维度（P4 战绩册 · 分组用）。
  static String bossMemorySource(BossMemorySource s) => switch (s) {
        BossMemorySource.mainline => '主线征程',
        BossMemorySource.tower => '爬塔问鼎',
      };
}
