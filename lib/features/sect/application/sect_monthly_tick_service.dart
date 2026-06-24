import 'dart:math';

import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../domain/sect_outcome.dart';
import 'sect_event_service.dart';
import 'sect_reputation_decay.dart';

/// 月度 tick 编排结果(B1 接通 · spec
/// `2026-06-24-b1-sect-event-game-loop-wiring-design.md` §3)。
///
/// [compute] 已**原地 mutate** 传入的 `sect`(reputation / lastTickAt / lastEventAt)
/// 与各 expired event,本结构只回传 caller writeTxn 需 put 的两组事件。
class SectTickResult {
  /// 本 tick 新触发的 pending 事件(caller put 入 isar.sectEvents)。
  final List<SectEvent> newEvents;

  /// 本 tick 过期回收的事件(已原地标 expired,caller put 落库)。
  final List<SectEvent> expiredEvents;

  const SectTickResult({required this.newEvents, required this.expiredEvents});
}

/// 门派月度 tick 编排(B1 接通门派事件 game loop · 仅 tournament)。
///
/// **纯函数体例**(沿 [SectEventService] / [SectReputationDecayService]):
/// 不碰 Isar,组合既有 `checkAndTrigger` + `computeDecay` + `resolve(expired)`,
/// 真持久化(writeTxn)在 caller 端(`sect_providers._runSectTick`)。
///
/// 真实日历月锚(2026-06-24 拍板 · 守 §5.5 真实时间是唯一时钟):
/// - **过期扫描**(每次都跑,不绑月界):pending 超 `expire_days` → expired + rep loss。
/// - **月度 pass**(≥1 完整月才跑):`elapsedMonths = (now - (lastTickAt ?? createdAt)).inDays ~/ 30`,
///   逐月 `checkAndTrigger`(命中且未达 active 上限 → 新 pending),decay 按 idle 月数累扣。
class SectMonthlyTickService {
  final SectEventService eventSvc;
  final SectReputationDecayService decaySvc;
  final NumbersConfig numbers;

  const SectMonthlyTickService({
    required this.eventSvc,
    required this.decaySvc,
    required this.numbers,
  });

  /// 一个月 = 30 真实天(沿 numbers cooldown_days / decay 30 天 cycle 语义)。
  static const int _daysPerMonth = 30;

  SectTickResult compute({
    required Sect sect,
    required List<SectEvent> activeEvents,
    required RealmTier playerRealm,
    required DateTime now,
    required Random rng,
  }) {
    final cfg = numbers.sectEvent;
    final expireDays = cfg.tournament.expireDays;
    final activeEventsMax = cfg.activeEventsMax;
    final repMin = cfg.reputation.min;
    final repMax = cfg.reputation.max;
    final pool = cfg.tournament.narrativeIds;

    // ① 过期扫描(不绑月界):pending 超 expire_days → 复用 resolve(expired)
    //    原地写 status/resolvedAt/reputationDelta + sect.rep loss + lastEventAt。
    final expired = <SectEvent>[];
    for (final e in activeEvents) {
      if (e.status == SectEventStatus.pending &&
          now.difference(e.triggeredAt).inDays >= expireDays) {
        eventSvc.resolve(
          sect: sect,
          event: e,
          outcome: SectOutcome.expired,
          now: now,
        );
        expired.add(e);
      }
    }

    // ② 月度 pass
    final newEvents = <SectEvent>[];
    final anchor = sect.lastTickAt ?? sect.createdAt;
    final elapsedMonths = now.difference(anchor).inDays ~/ _daysPerMonth;
    if (elapsedMonths >= 1) {
      // decay:lastEventAt 在本 tick 内不变 → 每月扣额 × 月数(idle ≥30 天才非 0)。
      final decayPerMonth = decaySvc.computeDecay(sect: sect, now: now);
      if (decayPerMonth != 0) {
        sect.sectReputation =
            (sect.sectReputation + decayPerMonth * elapsedMonths)
                .clamp(repMin, repMax);
      }

      // 触发:逐月一次,线程化增长中的 active 列表(过期已腾出的槽位生效)。
      var working = activeEvents
          .where((e) => e.status == SectEventStatus.pending)
          .toList();
      for (var m = 0; m < elapsedMonths; m++) {
        if (pool.isEmpty) break; // 空池防空 pick 崩
        if (working.length >= activeEventsMax) break; // cap 只增,命中即止
        final picked = pool[rng.nextInt(pool.length)];
        final ev = eventSvc.checkAndTrigger(
          sect: sect,
          activeEvents: working,
          playerRealm: playerRealm,
          now: now,
          pickedNarrativeId: picked,
          rng: rng,
        );
        if (ev != null) {
          newEvents.add(ev);
          working = [...working, ev];
        }
      }

      sect.lastTickAt =
          anchor.add(Duration(days: elapsedMonths * _daysPerMonth));
    }

    return SectTickResult(newEvents: newEvents, expiredEvents: expired);
  }
}
