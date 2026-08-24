library;

import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../domain/boss_gauntlet_run.dart';
import '../domain/gauntlet_automation_policy.dart';

/// Unforgeable proof that the exact request matched current save and run state.
final class GauntletAutomationAdmission {
  const GauntletAutomationAdmission._({
    required this.request,
    required this.saveDataId,
    required this.runId,
    required this.memberCharacterId,
    required this.currentStage,
    required this.sessionPhase,
    required this.memberCurrentHp,
    required this.memberCurrentQi,
    required this.memberMaxHp,
    required this.memberMaxQi,
    required this.memberIsDowned,
  });

  final ActivityParticipationRequest request;
  final int saveDataId;
  final int runId;
  final int memberCharacterId;
  final int currentStage;
  final GauntletPhase sessionPhase;
  final int memberCurrentHp;
  final int memberCurrentQi;
  final int memberMaxHp;
  final int memberMaxQi;
  final bool memberIsDowned;
}

/// Application admission against the current persisted save and active run.
final class GauntletAutomationAdmissionService {
  const GauntletAutomationAdmissionService(this._isar);

  final Isar _isar;

  Future<GauntletAutomationAdmission> admit({
    required ActivityParticipationRequest request,
  }) async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) {
      throw StateError('Gauntlet automation admission requires a save');
    }

    GauntletAutomationPolicy.requireAllowed(
      request: request,
      clearedGauntletIds: save.clearedGauntletIds.toSet(),
    );

    final runs = await _isar.bossGauntletRuns.where().findAll();
    BossGauntletRun? activeRun;
    for (final run in runs) {
      if (run.saveDataId != save.id) continue;
      if (activeRun != null) {
        throw StateError('Gauntlet automation requires one active run');
      }
      activeRun = run;
    }
    if (activeRun == null) {
      throw StateError('Gauntlet automation requires an active run');
    }
    if (activeRun.members.length != 1) {
      throw StateError('Gauntlet automation requires one active member');
    }
    final memberCharacterId = activeRun.members.single.characterId;
    if (memberCharacterId != request.characterId) {
      throw StateError(
        'Gauntlet automation request character does not match active member',
      );
    }

    return GauntletAutomationAdmission._(
      request: request,
      saveDataId: save.id,
      runId: activeRun.id,
      memberCharacterId: memberCharacterId,
      currentStage: activeRun.currentStage,
      sessionPhase: activeRun.sessionPhase,
      memberCurrentHp: activeRun.members.single.currentHp,
      memberCurrentQi: activeRun.members.single.currentQi,
      memberMaxHp: activeRun.members.single.maxHp,
      memberMaxQi: activeRun.members.single.maxQi,
      memberIsDowned: activeRun.members.single.isDowned,
    );
  }

  /// Re-checks policy and persisted identity before every automated mutation.
  Future<GauntletAutomationAdmission> revalidate(
    GauntletAutomationAdmission admission,
  ) async {
    final current = await admit(request: admission.request);
    if (current.saveDataId != admission.saveDataId ||
        current.runId != admission.runId ||
        current.memberCharacterId != admission.memberCharacterId ||
        current.currentStage != admission.currentStage ||
        current.sessionPhase != admission.sessionPhase ||
        current.memberCurrentHp != admission.memberCurrentHp ||
        current.memberCurrentQi != admission.memberCurrentQi ||
        current.memberMaxHp != admission.memberMaxHp ||
        current.memberMaxQi != admission.memberMaxQi ||
        current.memberIsDowned != admission.memberIsDowned) {
      throw StateError('Gauntlet automation admission is stale');
    }
    return current;
  }
}
