import 'dart:math';

import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../domain/sect_outcome.dart';

/// 门派事件服务(1.0 P3.4 §12.1 Batch 2.2 · spec p3_4_sect_event_spec_2026-05-24 §4)。
///
/// **pure-ish 体例**(避 Isar 实例化测撞 autoIncrement · memory
/// `feedback_isar_autoincrement_test_id_collision`):
/// - `checkAndTrigger` 接全部入参 → 返 `SectEvent?`(触发就 new instance / 不触发 null)
/// - `resolve` 接 event + outcome + sect → 原地 mutation 后返 tuple
/// - **真持久化(Isar writeTxn)在 caller 端**(Phase 4 wire 到 Riverpod 时落)
///
/// NumbersConfig 已升 [SectEventDef] 强类型(T19b 技术债清账,原"Phase 4+ 升"挂账清)。
class SectEventService {
  final NumbersConfig numbers;

  const SectEventService({required this.numbers});

  /// 月度 tick 触发链路(spec §4):
  /// ① cooldown:`(now - lastEventAt).inDays < cooldown_days` → null
  /// ② 境界:`playerRealm < trigger_realm_min` → null
  /// ③ 上限:`activeEvents.length >= active_events_max` → null
  /// ④ 概率:`rng.nextDouble() >= trigger_probability` → null
  /// 全通过 → 返 SectEvent(status=pending,resolvedAt/reputationDelta 留 null)。
  SectEvent? checkAndTrigger({
    required Sect sect,
    required List<SectEvent> activeEvents,
    required RealmTier playerRealm,
    required DateTime now,
    required String pickedNarrativeId,
    required Random rng,
  }) {
    final cfg = numbers.sectEvent;
    final tournament = cfg.tournament;
    final cooldownDays = tournament.cooldownDays;
    final triggerProbability = tournament.triggerProbability;
    final triggerRealmMin =
        RealmTier.values.byName(tournament.triggerRealmMin);
    final activeEventsMax = cfg.activeEventsMax;

    // ① cooldown
    final lastAt = sect.lastEventAt;
    if (lastAt != null) {
      final daysSince = now.difference(lastAt).inDays;
      if (daysSince < cooldownDays) return null;
    }

    // ② 境界(RealmTier.values 顺序 xueTu=0 → wuSheng=6 与 §5.3 七阶一致)
    if (playerRealm.index < triggerRealmMin.index) return null;

    // ③ activeEvents 上限
    if (activeEvents.length >= activeEventsMax) return null;

    // ④ rand 概率
    if (rng.nextDouble() >= triggerProbability) return null;

    return SectEvent()
      ..sectId = sect.id
      ..type = SectEventType.tournament
      ..status = SectEventStatus.pending
      ..triggeredAt = now
      ..narrativeId = pickedNarrativeId;
  }

  /// 事件结算链路(spec §4):
  /// - `win`:     reputation +win_delta(clamp ≤max)· totalWins +1 · 每
  ///              `promote_wins_threshold` 胜 → sectLevel +1(clamp ≤max)
  /// - `loss`:    reputation +loss_delta(clamp ≥min)
  /// - `expired`: reputation +loss_delta(clamp ≥min)+ status=expired
  ///
  /// 三路皆写 `lastEventAt=now`(用于 cooldown / decay 锚)+
  /// `event.resolvedAt=now` + `event.reputationDelta`。
  ///
  /// 返 `(sect, event)` 原地 mutation 后实例。caller 端 writeTxn 落。
  (Sect, SectEvent) resolve({
    required Sect sect,
    required SectEvent event,
    required SectOutcome outcome,
    required DateTime now,
  }) {
    final cfg = numbers.sectEvent;
    final repCfg = cfg.reputation;
    final levelCfg = cfg.sectLevel;
    final winDelta = repCfg.winDelta;
    final lossDelta = repCfg.lossDelta;
    final repMax = repCfg.max;
    final repMin = repCfg.min;
    final levelMax = levelCfg.max;
    final promoteThreshold = levelCfg.promoteWinsThreshold;

    int newRep = sect.sectReputation;
    int newWins = sect.totalWins;
    int newLevel = sect.sectLevel;
    int repDelta;
    SectEventStatus newStatus;

    switch (outcome) {
      case SectOutcome.win:
        newRep = (newRep + winDelta).clamp(repMin, repMax);
        newWins += 1;
        if (newWins > 0 && newWins % promoteThreshold == 0) {
          newLevel = (newLevel + 1).clamp(1, levelMax);
        }
        repDelta = winDelta;
        newStatus = SectEventStatus.resolved;
        break;
      case SectOutcome.loss:
        newRep = (newRep + lossDelta).clamp(repMin, repMax);
        repDelta = lossDelta;
        newStatus = SectEventStatus.resolved;
        break;
      case SectOutcome.expired:
        newRep = (newRep + lossDelta).clamp(repMin, repMax);
        repDelta = lossDelta;
        newStatus = SectEventStatus.expired;
        break;
    }

    sect
      ..sectReputation = newRep
      ..totalWins = newWins
      ..sectLevel = newLevel
      ..lastEventAt = now;
    event
      ..status = newStatus
      ..resolvedAt = now
      ..reputationDelta = repDelta;

    return (sect, event);
  }
}
