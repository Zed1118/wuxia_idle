import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_automation_admission.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/gauntlet_automation_policy.dart';

import '../../support/isar_test_support.dart';

ActivityParticipationRequest _request({
  int characterId = 42,
  String contentId = GauntletAutomationPolicy.gauntletId,
  ActivityContentKind contentKind = ActivityContentKind.gauntlet,
  ActivityController controller = ActivityController.playerBot,
  ActivityClock clock = ActivityClock.headless,
  ActivityEntryKind entryKind = ActivityEntryKind.replay,
}) => ActivityParticipationRequest(
  contentId: contentId,
  contentKind: contentKind,
  characterId: characterId,
  loadoutPlanId: 'gauntlet-plan-$characterId',
  participation: ActivityParticipationMode.direct,
  controller: controller,
  clock: clock,
  entryKind: entryKind,
);

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_gauntlet_automation_admission_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<int> seed({
    Set<String> cleared = const {GauntletAutomationPolicy.gauntletId},
    int memberCharacterId = 42,
  }) async {
    late int runId;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 8, 24)
          ..lastSavedAt = DateTime(2026, 8, 24)
          ..lastOnlineAt = DateTime(2026, 8, 24)
          ..clearedGauntletIds = cleared.toList(),
      );
      runId = await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 1
          ..currentStage = 1
          ..sessionPhase = GauntletPhase.inBattle
          ..members = [
            ActivityMemberSnapshot()..characterId = memberCharacterId,
          ],
      );
    });
    return runId;
  }

  test('exact request is admitted for the existing single member', () async {
    final runId = await seed();
    final request = _request();

    final admission = await GauntletAutomationAdmissionService(
      IsarSetup.instance,
    ).admit(request: request);

    expect(admission.request, same(request));
    expect(admission.runId, runId);
    expect(admission.memberCharacterId, 42);
    expect(admission.currentStage, 1);
    expect(admission.sessionPhase, GauntletPhase.inBattle);
  });

  test(
    'wrong kind, wrong ID, visible bot, and first clear fail closed',
    () async {
      await seed();
      final requests = [
        _request(contentKind: ActivityContentKind.mainline),
        _request(contentId: 'another_gauntlet'),
        _request(clock: ActivityClock.realtime),
        _request(entryKind: ActivityEntryKind.firstClear),
      ];

      for (final request in requests) {
        await expectLater(
          GauntletAutomationAdmissionService(
            IsarSetup.instance,
          ).admit(request: request),
          throwsA(isA<GauntletAutomationRejectedException>()),
        );
      }
    },
  );

  test('uncleared replay rejects before returning an admission', () async {
    await seed(cleared: const {});

    await expectLater(
      GauntletAutomationAdmissionService(
        IsarSetup.instance,
      ).admit(request: _request()),
      throwsA(
        isA<GauntletAutomationRejectedException>().having(
          (error) => error.reason,
          'reason',
          GauntletAutomationRejectionReason.fullClearRequired,
        ),
      ),
    );
  });

  test('request character must equal the active run member', () async {
    await seed(memberCharacterId: 7);

    await expectLater(
      GauntletAutomationAdmissionService(
        IsarSetup.instance,
      ).admit(request: _request(characterId: 42)),
      throwsStateError,
    );
  });

  test('revalidation rejects a token after the active run changes', () async {
    final originalRunId = await seed();
    final service = GauntletAutomationAdmissionService(IsarSetup.instance);
    final admission = await service.admit(request: _request());

    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.delete(originalRunId);
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 2
          ..currentStage = 1
          ..sessionPhase = GauntletPhase.inBattle
          ..members = [ActivityMemberSnapshot()..characterId = 42],
      );
    });

    await expectLater(service.revalidate(admission), throwsStateError);
  });

  test('revalidation rejects stage and phase changes', () async {
    final runId = await seed();
    final service = GauntletAutomationAdmissionService(IsarSetup.instance);
    final stageAdmission = await service.admit(request: _request());

    await IsarSetup.instance.writeTxn(() async {
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
      run.currentStage = 2;
      await IsarSetup.instance.bossGauntletRuns.put(run);
    });
    await expectLater(service.revalidate(stageAdmission), throwsStateError);

    final phaseAdmission = await service.admit(request: _request());
    await IsarSetup.instance.writeTxn(() async {
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
      run.sessionPhase = GauntletPhase.interlude;
      await IsarSetup.instance.bossGauntletRuns.put(run);
    });
    await expectLater(service.revalidate(phaseAdmission), throwsStateError);
  });
}
