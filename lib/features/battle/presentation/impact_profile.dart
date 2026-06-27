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
  final String? glyph; // 单字水墨题字「斩/震/断」或破防开窗「破绽」；heavy/破招(interrupted)/大招为 null
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

/// 命中峰值类型（特写触发源）。none=不特写。
enum HitClimax { none, ultimateCrit, kill }

/// 由 [action] + [state] 派生峰值类型。纯函数。
/// ultimateCrit = 大招/人剑合一 且暴击；kill = 本击使目标死亡。
/// 二者皆中时 ultimateCrit 优先（题字更大）。
HitClimax hitClimaxFor(BattleAction action, BattleState state) {
  final r = action.attackResult;
  if (r == null || r.isDodged) return HitClimax.none;
  if (isUltimateCaptionSkill(action.skill) && r.isCritical) {
    return HitClimax.ultimateCrit;
  }
  final targetId = action.targetId;
  if (targetId != null) {
    final target = state.characterById(targetId);
    if (target != null && !target.isAlive) return HitClimax.kill;
  }
  return HitClimax.none;
}
