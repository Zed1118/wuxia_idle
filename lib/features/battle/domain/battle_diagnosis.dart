import '../../../data/numbers_config.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import 'enum_localizations.dart';
import 'battle_state.dart';
import 'battle_stats.dart';

/// 失败复盘建议的跳转目标（team 无独立 screen，不做按钮）。
enum DiagnosisJumpTarget { skills, equipment, cultivation, roster, supplies }

/// 战败主短板分类。文案集中在 [UiStrings.defeatShortfallLabel]。
enum DefeatShortfall { realm, equipment, technique, roster, counter, supplies }

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
  final DefeatShortfall shortfall;
  final String primaryCause;
  final List<String> dataLines;
  final List<DiagnosisSuggestion> suggestions;

  const BattleDiagnosis({
    required this.ruleId,
    required this.shortfall,
    required this.primaryCause,
    required this.dataLines,
    required this.suggestions,
  });

  /// 按 priority 高→低逐条试，首条命中即止；全不中走 generic。
  static BattleDiagnosis? from(BattleState state, BattleReportConfig config) {
    final lost =
        state.result == BattleResult.rightWin ||
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
    final playerDamageTaken = enemyHits.fold<int>(
      0,
      (s, a) => s + a.attackResult!.finalDamage,
    );
    final minionDamage = enemyHits
        .where((a) => !(enemyById[a.actorId]?.isBoss ?? false))
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final internalWoundDamage = enemyHits
        .where(
          (a) => a.attackResult!.appliedEffects.contains('internal_injury'),
        )
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    final lastLethalHit = enemyHits.isEmpty ? null : enemyHits.last;

    // 主控玩家角色（slot 最小）。
    final player = left.isEmpty
        ? null
        : left.reduce((a, b) => a.slotIndex <= b.slotIndex ? a : b);

    // 规则 0（priority 110）realm_gap
    final playerTop = _topRealm(left);
    final enemyTop = _topRealm(right);
    if (playerTop != null &&
        enemyTop != null &&
        enemyTop.$1.index > playerTop.$1.index) {
      return BattleDiagnosis(
        ruleId: 'realm_gap',
        shortfall: DefeatShortfall.realm,
        primaryCause: UiStrings.diagCauseRealm,
        dataLines: [
          UiStrings.diagPlayerTopRealm(EnumL10n.realmTier(playerTop.$1)),
          UiStrings.diagEnemyTopRealm(EnumL10n.realmTier(enemyTop.$1)),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestRealm,
            DiagnosisJumpTarget.cultivation,
          ),
        ],
      );
    }

    // 规则 1（priority 100）killed_by_charge
    if (lastLethalHit != null) {
      final attacker = enemyById[lastLethalHit.actorId];
      final skillId = lastLethalHit.skill?.id;
      if (attacker != null &&
          attacker.chargeSkillId != null &&
          skillId == attacker.chargeSkillId) {
        return BattleDiagnosis(
          ruleId: 'killed_by_charge',
          shortfall: DefeatShortfall.technique,
          primaryCause: UiStrings.diagCauseCharge,
          dataLines: [
            UiStrings.diagLethalHit(
              lastLethalHit.skill?.name ?? '',
              lastLethalHit.attackResult!.finalDamage,
            ),
            UiStrings.diagInternalForceLeft(
              player?.currentInternalForce ?? 0,
              player?.maxInternalForce ?? 0,
            ),
          ],
          suggestions: const [
            DiagnosisSuggestion(
              UiStrings.diagSuggestCharge,
              DiagnosisJumpTarget.skills,
            ),
          ],
        );
      }
    }

    // 规则 1b（priority 95）countered_by_school
    final counteredDamage = enemyHits
        .where((a) => a.attackResult!.schoolCounterMultiplier > 1.0)
        .fold<int>(0, (s, a) => s + a.attackResult!.finalDamage);
    if (playerDamageTaken > 0 &&
        counteredDamage / playerDamageTaken >= config.minionDamagePct) {
      final pct = (counteredDamage / playerDamageTaken * 100).round();
      final school = _dominantEnemySchool(enemyHits, enemyById);
      return BattleDiagnosis(
        ruleId: 'countered_by_school',
        shortfall: DefeatShortfall.counter,
        primaryCause: UiStrings.diagCauseCounter,
        dataLines: [
          UiStrings.diagCounteredDamageRatio(pct),
          UiStrings.diagDominantEnemySchool(
            school == null ? UiStrings.unknown : EnumL10n.school(school),
          ),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestCounter,
            DiagnosisJumpTarget.roster,
          ),
        ],
      );
    }

    // 规则 2（priority 90）killed_by_internal_wound
    final injuredDeath = left.any(
      (p) => !p.isAlive && p.internalInjury != null,
    );
    if ((playerDamageTaken > 0 &&
            internalWoundDamage / playerDamageTaken >=
                config.internalWoundPct) ||
        injuredDeath) {
      final pct = playerDamageTaken > 0
          ? (internalWoundDamage / playerDamageTaken * 100).round()
          : 0;
      return BattleDiagnosis(
        ruleId: 'killed_by_internal_wound',
        shortfall: DefeatShortfall.supplies,
        primaryCause: UiStrings.diagCauseInternalWound,
        dataLines: [
          UiStrings.diagInternalWoundRatio(pct),
          UiStrings.diagDamageTaken(playerDamageTaken),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestInternalWound,
            DiagnosisJumpTarget.supplies,
          ),
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
        shortfall: DefeatShortfall.roster,
        primaryCause: UiStrings.diagCauseMob,
        dataLines: [
          UiStrings.diagMinionRatio(pct),
          UiStrings.diagDamageTaken(playerDamageTaken),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestMob,
            DiagnosisJumpTarget.roster,
          ),
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
        shortfall: DefeatShortfall.equipment,
        primaryCause: UiStrings.diagCauseFrontline,
        dataLines: [
          UiStrings.diagFrontlineDeath(death.name, death.deathTick),
          UiStrings.diagFrontlineMaxHp(death.maxHp),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestFrontline,
            DiagnosisJumpTarget.equipment,
          ),
        ],
      );
    }

    // 规则 4b（priority 50）supplies_exhausted
    final totalPlayerHp = left.fold<int>(0, (s, p) => s + p.maxHp);
    final playerHealing = _playerHealingDone(state);
    final anyPlayerStillStanding = left.any((p) => p.isAlive);
    if (right.length == 1 &&
        anyPlayerStillStanding &&
        totalPlayerHp > 0 &&
        playerDamageTaken / totalPlayerHp >= config.survivorHpPct &&
        !_hasRecoveryOption(left)) {
      return BattleDiagnosis(
        ruleId: 'supplies_exhausted',
        shortfall: DefeatShortfall.supplies,
        primaryCause: UiStrings.diagCauseSupplies,
        dataLines: [
          UiStrings.diagDamageTaken(playerDamageTaken),
          UiStrings.diagRecoveryDone(playerHealing),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestSupplies,
            DiagnosisJumpTarget.supplies,
          ),
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
        shortfall: DefeatShortfall.technique,
        primaryCause: UiStrings.diagCauseDps,
        dataLines: [
          UiStrings.diagTotalTicks(state.tick),
          UiStrings.diagSurvivorHp((avgHpPct * 100).round()),
        ],
        suggestions: const [
          DiagnosisSuggestion(
            UiStrings.diagSuggestDps,
            DiagnosisJumpTarget.skills,
          ),
        ],
      );
    }

    // 兜底 generic
    final stats = BattleStatsSummary.from(state);
    return BattleDiagnosis(
      ruleId: 'generic',
      shortfall: DefeatShortfall.technique,
      primaryCause: UiStrings.diagCauseGeneric,
      dataLines: [
        UiStrings.diagTotalDamage(stats.totalDamage),
        UiStrings.diagTotalTicks(state.tick),
      ],
      suggestions: const [
        DiagnosisSuggestion(
          UiStrings.diagSuggestGeneric,
          DiagnosisJumpTarget.skills,
        ),
      ],
    );
  }

  static (RealmTier, RealmLayer)? _topRealm(List<BattleCharacter> team) {
    if (team.isEmpty) return null;
    var best = team.first;
    for (final c in team.skip(1)) {
      if (c.realmTier.index > best.realmTier.index ||
          (c.realmTier == best.realmTier &&
              c.realmLayer.index > best.realmLayer.index)) {
        best = c;
      }
    }
    return (best.realmTier, best.realmLayer);
  }

  static TechniqueSchool? _dominantEnemySchool(
    List<BattleAction> enemyHits,
    Map<int, BattleCharacter> enemyById,
  ) {
    final damageBySchool = <TechniqueSchool, int>{};
    for (final a in enemyHits) {
      final school = enemyById[a.actorId]?.school;
      if (school == null) continue;
      damageBySchool[school] =
          (damageBySchool[school] ?? 0) + a.attackResult!.finalDamage;
    }
    TechniqueSchool? best;
    var bestDamage = -1;
    for (final entry in damageBySchool.entries) {
      if (entry.value > bestDamage) {
        best = entry.key;
        bestDamage = entry.value;
      }
    }
    return best;
  }

  static int _playerHealingDone(BattleState state) {
    final leftIds = {for (final p in state.leftTeam) p.characterId};
    var healing = 0;
    for (final a in state.actionLog) {
      if (!leftIds.contains(a.actorId)) continue;
      healing += a.attackResult?.lifestealHeal ?? 0;
    }
    return healing;
  }

  static bool _hasRecoveryOption(List<BattleCharacter> left) {
    for (final p in left) {
      if (p.forgingLifestealPct > 0) return true;
      for (final skill in p.availableSkills) {
        if (skill.visualEffect.contains('heal')) return true;
      }
    }
    return false;
  }

  /// 前排死亡启发式：累计敌方伤害首次 ≥ maxHp 的 tick = 死亡 tick；
  /// 取 slotIndex 0 且最早死亡者（按 actionLog 顺序累计，maxHp 取战中常量）。
  static _FrontlineDeath? _firstFrontlineDeath(
    List<BattleCharacter> left,
    List<BattleAction> enemyHits,
    int totalTick,
  ) {
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
