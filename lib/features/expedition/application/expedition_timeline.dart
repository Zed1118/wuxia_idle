import 'dart:async';

import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../seclusion/application/offline_passive_service.dart';
import '../domain/expedition_rules.dart';
import '../domain/expedition_run.dart';
import 'expedition_combat_selector.dart';
import 'expedition_service.dart';

/// Orders elapsed-time writers for one open save. Headless battles run outside
/// Isar transactions; only a node's passive slice and its durable result write.
/// Call public entry points outside a write transaction.
class ExpeditionTimeline {
  ExpeditionTimeline._();

  static final _queues = Expando<Future<void>>();
  static final _leaseKey = Object();
  static final _nodeKey = Object();

  /// Awaited nested service calls share a lease, including return/claim paths.
  /// A completed lease cannot let a later timer bypass the queue.
  static Future<T> serialize<T>(Isar isar, Future<T> Function() action) {
    final lease = Zone.current[_leaseKey];
    if (lease is _TimelineLease &&
        lease.active &&
        identical(lease.isar, isar)) {
      return action();
    }
    final task = (_queues[isar] ?? Future<void>.value()).then((_) async {
      final lease = _TimelineLease(isar);
      try {
        return await runZoned(action, zoneValues: {_leaseKey: lease});
      } finally {
        lease.active = false;
      }
    });
    _queues[isar] = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return task;
  }

  static Future<T> runAfterCatchUp<T>({
    required Isar isar,
    required DateTime now,
    required Future<T> Function() action,
    ExpeditionService? service,
  }) => serialize(isar, () async {
    await catchUp(isar: isar, now: now, service: service);
    return action();
  });

  static Future<void> catchUp({
    required Isar isar,
    required DateTime now,
    ExpeditionService? service,
  }) async {
    final currentService = service ?? ExpeditionService(isar);
    final run = await currentService.activeRun();
    if (run == null) return;
    if (run.members.length != 1) {
      // Retired multiplayer sessions receive only their persisted rewards.
      await currentService.recall(now: now);
      return;
    }
    final config = GameRepository.instance.expeditionConfig;
    if (config == null) {
      throw StateError('Active expedition has no configuration');
    }
    final result = await currentService.settleToNow(
      combat: expeditionCombatFor(
        isar,
        memberCount: run.members.length,
        member: run.members.single,
      ),
      config: config,
      now: now,
    );
    if (!result.caughtUp) {
      throw StateError(
        'Expedition must catch up before advancing passive time',
      );
    }
  }

  static DateTime nodeCompletedAt(ExpeditionRun run, int node) {
    final config = GameRepository.instance.expeditionConfig;
    if (config == null) {
      throw StateError('Active expedition has no configuration');
    }
    return run.departedAt.add(
      Duration(
        minutes: ExpeditionRules.cumulativeMinutesToCompleteNode(
          node,
          normalMinutes: config.normalNodeMinutes,
          eliteMinutes: config.eliteNodeMinutes,
        ),
      ),
    );
  }

  /// Called within the node preparation transaction, after rechecking its cursor.
  /// An already advanced historic ledger cannot reconstruct earlier attributes.
  /// Preserve it and diagnose the conflict instead of guessing a rollback.
  static Future<void> settleBeforeNodeInTxn({
    required Isar isar,
    required ExpeditionRun run,
    required DateTime at,
  }) async {
    final save = await isar.saveDatas.get(0);
    final established =
        save != null &&
        (save.passiveLastSettledAt != null ||
            save.lastOnlineAt != save.createdAt);
    final anchor = established
        ? save.passiveLastSettledAt ?? save.lastOnlineAt
        : null;
    if (save != null &&
        run.members.any((m) => m.characterId == save.founderCharacterId) &&
        anchor != null &&
        anchor.isAfter(at)) {
      throw ExpeditionTimelineConflict(
        runId: run.id,
        nextNode: run.currentNode + 1,
        passiveAt: anchor,
        nodeAt: at,
      );
    }
    await runZoned(
      () => OfflinePassiveService.settleWithinTxn(isar: isar, now: at),
      zoneValues: {
        _nodeKey: (isar: isar, runId: run.id, node: run.currentNode, at: at),
      },
    );
  }

  /// Raw transaction consumers must prepare overdue expedition nodes outside
  /// their transaction. The sole exception is that node's validated time slice.
  static Future<void> assertPassiveBoundary(Isar isar, DateTime now) async {
    final runs = await isar.expeditionRuns.where().findAll();
    for (final run in runs) {
      if (run.defeated || run.members.length != 1) continue;
      final node = Zone.current[_nodeKey];
      if (node is ({Isar isar, int runId, int node, DateTime at}) &&
          identical(node.isar, isar) &&
          node.runId == run.id &&
          node.node == run.currentNode &&
          node.at == now) {
        continue;
      }
      final at = nodeCompletedAt(run, run.currentNode + 1);
      if (now.isBefore(at)) continue;
      throw StateError(
        'Pending expedition node must settle before passive growth',
      );
    }
  }

  static Future<PassiveYield?> settlePassiveWindow({
    required Isar isar,
    required DateTime now,
    required bool recoverInjuries,
    required bool updatePresence,
    required bool settleIslandBeforeGrowth,
    ExpeditionService? service,
  }) => serialize(isar, () async {
    final before = await isar.saveDatas.get(0);
    await catchUp(isar: isar, now: now, service: service);
    final tail = await isar.writeTxn(
      () => OfflinePassiveService.settleWithinTxn(
        isar: isar,
        now: now,
        recoverInjuries: recoverInjuries,
        updatePresence: updatePresence,
        consumeRecap: updatePresence,
        settleIslandBeforeGrowth: settleIslandBeforeGrowth,
      ),
    );
    // Presence consumes the persisted recap in the same transaction as its tail.
    // Non-presence callers receive only the amount actually awarded by this call.
    if (updatePresence) return tail;
    final after = await isar.saveDatas.get(0);
    if (before == null || after == null) return tail;
    final experience =
        after.totalPassiveExperience - before.totalPassiveExperience;
    final mojianshi =
        after.totalPassiveMojianshi - before.totalPassiveMojianshi;
    if (experience == 0 && mojianshi == 0) return tail;
    final anchor = before.passiveLastSettledAt ?? before.lastOnlineAt;
    final hours =
        now.difference(anchor).inMicroseconds / Duration.microsecondsPerHour;
    return (
      experience: experience,
      mojianshi: mojianshi,
      awayHours: hours,
      settledHours: hours,
      isCapped: false,
    );
  });
}

class _TimelineLease {
  _TimelineLease(this.isar);
  final Isar isar;
  bool active = true;
}

/// A historic passive ledger is already ahead of an unplayed expedition node.
/// No rollback or guessed battle outcome is safe. Callers may offer an explicit
/// player choice to end that exact run and collect only its persisted rewards.
class ExpeditionTimelineConflict implements Exception {
  const ExpeditionTimelineConflict({
    required this.runId,
    required this.nextNode,
    required this.passiveAt,
    required this.nodeAt,
  });
  final int runId;
  final int nextNode;
  final DateTime passiveAt;
  final DateTime nodeAt;
  @override
  String toString() =>
      'ExpeditionTimelineConflict(run: $runId, node: $nextNode, '
      'passive: $passiveAt, nodeAt: $nodeAt)';
}
