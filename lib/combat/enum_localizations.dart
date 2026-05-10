import '../data/models/enums.dart';
import 'battle_state.dart' show BattleResult;

/// enum 与战斗 effect 字符串的中文化（phase1_tasks.md T13 §750）。
///
/// **本文件是 Phase 1 中唯一允许出现"代码内中文"的位置**，且仅限调试日志使用。
/// Phase 4 起 DeepSeek 文案系统接管，这里的硬编码会迁出。
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
}
