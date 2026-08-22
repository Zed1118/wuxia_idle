import '../../../core/domain/character.dart';
import '../../../core/domain/attribute_effect_policy.dart';
import '../../../data/defs/injury_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';

/// 双层伤势设值纯函数（全静态，仿 InnerDemonService 体例）。
///
/// 只改传入 Character 的字段，不碰 Isar/persistence。
/// 持久化由 Task 7 caller 负责。
class InjuryService {
  InjuryService._();

  /// 重伤：设疗养剩余 = recoveryHours（再伤刷新不叠加，仿余毒）。
  static void applyHeavyInjury(Character c, {required double recoveryHours}) {
    c.injuryHoursRemaining = recoveryHours;
  }

  /// 轻伤：连战 +1，clamp maxStacks。
  static void accumulateLightInjury(Character c, {required int maxStacks}) {
    final n = c.lightInjuryStacks + 1;
    c.lightInjuryStacks = n > maxStacks ? maxStacks : n;
  }

  /// Engine-neutral injury settlement used by combat consumers.
  static void applySettlementInjuries({
    required List<Character> participatingCharacters,
    required Map<int, CombatParticipantSnapshot> participants,
    required InjuryConfig config,
    required AttributeEffectRules attributeEffects,
    required bool isVictory,
    required bool isHardFight,
  }) {
    // 连战轻伤：每场都累积。
    for (final ch in participatingCharacters) {
      accumulateLightInjury(ch, maxStacks: config.lightMaxStacks);
    }

    if (!isHardFight) return;

    final policy = AttributeEffectPolicy(attributeEffects);
    double recoveryHoursFor(Character character) => policy.heavyInjuryHours(
      baseHours: config.heavyRecoveryHours,
      constitution: character.attributes.constitution,
    );

    if (!isVictory) {
      // 硬仗战败：全员重伤。
      for (final ch in participatingCharacters) {
        applyHeavyInjury(ch, recoveryHours: recoveryHoursFor(ch));
      }
      return;
    }

    // 硬仗惨胜：仅存活且低血角色重伤。
    for (final ch in participatingCharacters) {
      final participant = participants[ch.id];
      if (participant == null) continue;
      if (participant.isAlive &&
          participant.currentHp <
              participant.maxHp * config.heavyWinHpThresholdPct) {
        applyHeavyInjury(ch, recoveryHours: recoveryHoursFor(ch));
      }
    }
  }
}
