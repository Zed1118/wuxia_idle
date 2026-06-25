import '../../../core/domain/character.dart';
import '../../battle/domain/battle_state.dart';
import '../domain/injury_config.dart';

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

  /// 战斗结算时对参战角色判定伤势（in-place 改字段，不写 Isar）。
  ///
  /// - **连战轻伤**：每场（无论胜负 / 是否硬仗）对全部参战角色 +1 轻伤层。
  /// - **硬仗重伤**（仅 [isHardFight]）：
  ///   - 战败（`!isVictory`）→ 全部参战角色重伤。
  ///   - 惨胜（`isVictory`）→ 仅「存活且 endHp < maxHp * heavyWinHpThresholdPct」
  ///     的角色重伤；按 `characterId == ch.id` 在 [finalState.leftTeam]（玩家队）
  ///     定位对应 [BattleCharacter] 取 endHp。
  static void applyBattleInjuries({
    required List<Character> participatingCharacters,
    required BattleState finalState,
    required InjuryConfig config,
    required bool isVictory,
    required bool isHardFight,
  }) {
    // 连战轻伤：每场都累积。
    for (final ch in participatingCharacters) {
      accumulateLightInjury(ch, maxStacks: config.lightMaxStacks);
    }

    if (!isHardFight) return;

    if (!isVictory) {
      // 硬仗战败：全员重伤。
      for (final ch in participatingCharacters) {
        applyHeavyInjury(ch, recoveryHours: config.heavyRecoveryHours);
      }
      return;
    }

    // 硬仗惨胜：仅存活且低血角色重伤。
    for (final ch in participatingCharacters) {
      final bc = _findBattleChar(finalState.leftTeam, ch.id);
      if (bc == null) continue;
      if (bc.isAlive &&
          bc.currentHp < bc.maxHp * config.heavyWinHpThresholdPct) {
        applyHeavyInjury(ch, recoveryHours: config.heavyRecoveryHours);
      }
    }
  }

  static BattleCharacter? _findBattleChar(
    List<BattleCharacter> team,
    int characterId,
  ) {
    for (final bc in team) {
      if (bc.characterId == characterId) return bc;
    }
    return null;
  }
}
