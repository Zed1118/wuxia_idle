import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../domain/battle_state.dart';
import 'ultimate_caption_overlay.dart' show isUltimateCaptionSkill;

/// 打击感强度档（暴击普攻 light < 强力技 medium < 大招/人剑合一 heavy）。
enum ImpactTier { light, medium, heavy }

/// 单次重击的打击感画像（纯派生现有字段，零 schema）。
class ImpactProfile {
  final ImpactTier tier;
  final String? glyph; // 「斩/震/断」；heavy/破招/大招为 null
  final int hitStopMs;
  final double shakeMagnitude;
  final double flashStrength;
  const ImpactProfile({
    required this.tier,
    required this.glyph,
    required this.hitStopMs,
    required this.shakeMagnitude,
    required this.flashStrength,
  });
}

/// 由 [action] 派生打击感画像；非重击（普攻非暴击/闪避/无结算）返 null。纯函数。
ImpactProfile? impactProfileFor(BattleAction action, ImpactFeedbackConfig cfg) {
  final result = action.attackResult;
  if (result == null || result.isDodged) return null;
  final skill = action.skill;
  final ImpactTier tier;
  if (isUltimateCaptionSkill(skill)) {
    tier = ImpactTier.heavy;
  } else if (skill?.type == SkillType.powerSkill) {
    tier = ImpactTier.medium;
  } else if (skill?.type == SkillType.normalAttack && result.isCritical) {
    tier = ImpactTier.light;
  } else {
    return null;
  }
  final params = switch (tier) {
    ImpactTier.light => cfg.light,
    ImpactTier.medium => cfg.medium,
    ImpactTier.heavy => cfg.heavy,
  };
  String? glyph;
  if (tier != ImpactTier.heavy && !action.interrupted) {
    if (action.openedBreakWindow) {
      // 破防开窗专用题字，覆盖流派默认字（互斥于 interrupted 的「破!」）。
      glyph = UiStrings.impactGlyphBreakWindow;
    } else {
      glyph = switch (skill?.style) {
        TechniqueSchool.gangMeng => UiStrings.impactGlyphZhen,
        TechniqueSchool.yinRou => UiStrings.impactGlyphDuan,
        TechniqueSchool.lingQiao || null => UiStrings.impactGlyphZhan,
      };
    }
  }
  return ImpactProfile(
    tier: tier,
    glyph: glyph,
    hitStopMs: params.hitStopMs,
    shakeMagnitude: params.shakeMagnitude,
    flashStrength: params.flashStrength,
  );
}
