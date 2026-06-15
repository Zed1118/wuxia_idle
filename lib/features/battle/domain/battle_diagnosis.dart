import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import 'battle_state.dart';
import 'battle_stats.dart';

/// 失败复盘建议的跳转目标（team 无独立 screen，不做按钮）。
enum DiagnosisJumpTarget { skills, equipment, cultivation }

/// 一条调整建议（文案 + 可选跳转）。
class DiagnosisSuggestion {
  final String text;
  final DiagnosisJumpTarget? jump;
  const DiagnosisSuggestion(this.text, [this.jump]);
}

/// 一场败北的三段式诊断（spec 2026-06-15-battle-report-diagnosis §7.2）。
/// 1 主因 + 2 关键数据 + ≤2 建议。仅败北（rightWin/draw）返回非 null。
class BattleDiagnosis {
  final String ruleId;
  final String primaryCause;
  final List<String> dataLines;
  final List<DiagnosisSuggestion> suggestions;

  const BattleDiagnosis({
    required this.ruleId,
    required this.primaryCause,
    required this.dataLines,
    required this.suggestions,
  });

  /// 按 priority 高→低逐条试，首条命中即止；全不中走 generic。
  static BattleDiagnosis? from(BattleState state, BattleReportConfig config) {
    final lost = state.result == BattleResult.rightWin ||
        state.result == BattleResult.draw;
    if (!lost) return null;

    final left = state.leftTeam;
    final right = state.rightTeam;
    final enemyIds = {for (final e in right) e.characterId};
    final leftIds = {for (final p in left) p.characterId};
    final enemyById = {for (final e in right) e.characterId: e};

    // 敌方对玩家的有效伤害动作（顺序保留）。
    final enemyHits = <BattleAction>[];
    for (final a in state.actionLog) {
      final r = a.attackResult;
      if (r == null || r.finalDamage <= 0) continue;
      if (!enemyIds.contains(a.actorId)) continue;
      if (a.targetId == null || !leftIds.contains(a.targetId)) continue;
      enemyHits.add(a);
    }
    final playerDamageTaken =
        enemyHits.fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final minionDamage = enemyHits
        .where((a) => !(enemyById[a.actorId]?.isBoss ?? false))
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final internalWoundDamage = enemyHits
        .where((a) => a.attackResult!.appliedEffects.contains('internal_injury'))
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final lastLethalHit = enemyHits.isEmpty ? null : enemyHits.last;

    // 主控玩家角色（slot 最小）。
    final player = left.isEmpty
        ? null
        : left.reduce((a, b) => a.slotIndex <= b.slotIndex ? a : b);

    // 规则 1（priority 100）killed_by_charge
    if (lastLethalHit != null) {
      final attacker = enemyById[lastLethalHit.actorId];
      final skillId = lastLethalHit.skill?.id;
      if (attacker != null &&
          attacker.chargeSkillId != null &&
          skillId == attacker.chargeSkillId) {
        return BattleDiagnosis(
          ruleId: 'killed_by_charge',
          primaryCause: UiStrings.diagCauseCharge,
          dataLines: [
            UiStrings.diagLethalHit(lastLethalHit.skill?.name ?? '',
                lastLethalHit.attackResult!.finalDamage),
            UiStrings.diagInternalForceLeft(player?.currentInternalForce ?? 0,
                player?.maxInternalForce ?? 0),
          ],
          suggestions: const [
            DiagnosisSuggestion(
                UiStrings.diagSuggestCharge, DiagnosisJumpTarget.skills),
          ],
        );
      }
    }

    // 规则 2（priority 90）killed_by_internal_wound
    final injuredDeath = left.any((p) => !p.isAlive && p.internalInjury != null);
    if ((playerDamageTaken > 0 &&
            internalWoundDamage / playerDamageTaken >= config.internalWoundPct) ||
        injuredDeath) {
      final pct = playerDamageTaken > 0
          ? (internalWoundDamage / playerDamageTaken * 100).round()
          : 0;
      return BattleDiagnosis(
        ruleId: 'killed_by_internal_wound',
        primaryCause: UiStrings.diagCauseInternalWound,
        dataLines: [
          UiStrings.diagInternalWoundRatio(pct),
          UiStrings.diagDamageTaken(playerDamageTaken),
        ],
        suggestions: const [
          DiagnosisSuggestion(UiStrings.diagSuggestInternalWound,
              DiagnosisJumpTarget.cultivation),
        ],
      );
    }

    // 规则 3（priority 80）mob_overrun
    if (right.length > 1 &&
        playerDamageTaken > 0 &&
        minionDamage / playerDamageTaken >= config.minionDamagePct) {
      final pct = (minionDamage / playerDamageTaken * 100).round();
      return BattleDiagnosis(
        ruleId: 'mob_overrun',
        primaryCause: UiStrings.diagCauseMob,
        dataLines: [
          UiStrings.diagMinionRatio(pct),
          UiStrings.diagDamageTaken(playerDamageTaken),
        ],
        suggestions: const [
          DiagnosisSuggestion(
              UiStrings.diagSuggestMob, DiagnosisJumpTarget.skills),
        ],
      );
    }

    // 规则 4（priority 60）frontline_fragile
    final death = _firstFrontlineDeath(left, enemyHits, state.tick);
    if (death != null &&
        state.tick > 0 &&
        death.deathTick / state.tick <= config.frontlineDeathPhasePct) {
      return BattleDiagnosis(
        ruleId: 'frontline_fragile',
        primaryCause: UiStrings.diagCauseFrontline,
        dataLines: [
          UiStrings.diagFrontlineDeath(death.name, death.deathTick),
          UiStrings.diagFrontlineMaxHp(death.maxHp),
        ],
        suggestions: const [
          DiagnosisSuggestion(
              UiStrings.diagSuggestFrontline, DiagnosisJumpTarget.equipment),
        ],
      );
    }

    // 规则 5（priority 40）dps_too_low
    final survivors = right.where((e) => e.isAlive && e.maxHp > 0).toList();
    final avgHpPct = survivors.isEmpty
        ? 0.0
        : survivors.fold<double>(0, (s, e) => s + e.currentHp / e.maxHp) /
            survivors.length;
    if (state.result == BattleResult.draw || avgHpPct >= config.survivorHpPct) {
      return BattleDiagnosis(
        ruleId: 'dps_too_low',
        primaryCause: UiStrings.diagCauseDps,
        dataLines: [
          UiStrings.diagTotalTicks(state.tick),
          UiStrings.diagSurvivorHp((avgHpPct * 100).round()),
        ],
        suggestions: const [
          DiagnosisSuggestion(
              UiStrings.diagSuggestDps, DiagnosisJumpTarget.skills),
        ],
      );
    }

    // 兜底 generic
    final stats = BattleStatsSummary.from(state);
    return BattleDiagnosis(
      ruleId: 'generic',
      primaryCause: UiStrings.diagCauseGeneric,
      dataLines: [
        UiStrings.diagTotalDamage(stats.totalDamage),
        UiStrings.diagTotalTicks(state.tick),
      ],
      suggestions: const [
        DiagnosisSuggestion(
            UiStrings.diagSuggestGeneric, DiagnosisJumpTarget.skills),
      ],
    );
  }

  /// 前排死亡启发式：累计敌方伤害首次 ≥ maxHp 的 tick = 死亡 tick；
  /// 取 slotIndex 0 且最早死亡者（按 actionLog 顺序累计，maxHp 取战中常量）。
  static _FrontlineDeath? _firstFrontlineDeath(
      List<BattleCharacter> left, List<BattleAction> enemyHits, int totalTick) {
    _FrontlineDeath? best;
    for (final p in left) {
      if (p.isAlive || p.slotIndex != 0) continue;
      var cum = 0;
      int? deathTick;
      for (final a in enemyHits) {
        if (a.targetId != p.characterId) continue;
        cum += a.attackResult!.finalDamage;
        if (cum >= p.maxHp) {
          deathTick = a.tick;
          break;
        }
      }
      deathTick ??= totalTick; // 无法定位则记终局
      if (best == null || deathTick < best.deathTick) {
        best = _FrontlineDeath(p.name, deathTick, p.maxHp);
      }
    }
    return best;
  }
}

class _FrontlineDeath {
  final String name;
  final int deathTick;
  final int maxHp;
  const _FrontlineDeath(this.name, this.deathTick, this.maxHp);
}
