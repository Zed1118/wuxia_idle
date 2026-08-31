import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_providers.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';
import 'package:wuxia_idle/features/inner_demon/presentation/inner_demon_screen.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  testWidgets('角色面板目标本人以 typed manual request 进入真实 stage seam', (tester) async {
    ActivityParticipationRequest? capturedRequest;
    CombatantSnapshot? capturedSnapshot;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async => MainlineProgress()
              ..clearedStageIds = const ['stage_01_03', 'stage_inner_demon_01'],
          ),
          innerDemonProgressProvider(7).overrideWith(
            (ref) async => InnerDemonProgress.from(
              innerDemonDef: GameRepository.instance.numbers.innerDemon,
              clearedStageIds: const {},
            ),
          ),
        ],
        child: MaterialApp(
          home: InnerDemonScreen(
            characterId: 7,
            participantSnapshotResolverForTest:
                ({
                  required request,
                  required expectedStageId,
                  required expectedCharacterId,
                }) async {
                  capturedRequest = request;
                  expect(expectedStageId, 'stage_inner_demon_01');
                  expect(expectedCharacterId, 7);
                  return testCombatantSnapshot(
                    characterId: 7,
                    name: '当前目标',
                    includeProductionBasicAttack: true,
                  );
                },
            stageRunnerForTest:
                ({
                  required context,
                  required ref,
                  required stage,
                  required targetCycle,
                  required participantSnapshot,
                }) async {
                  capturedSnapshot = participantSnapshot;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = GameRepository.instance.getStage('stage_inner_demon_01');
    await tester.tap(find.text(first.name));
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.contentKind, ActivityContentKind.innerDemon);
    expect(capturedRequest!.characterId, 7);
    expect(capturedRequest!.participation, ActivityParticipationMode.direct);
    expect(capturedRequest!.controller, ActivityController.human);
    expect(capturedRequest!.clock, ActivityClock.realtime);
    expect(
      capturedRequest!.entryKind,
      ActivityEntryKind.firstClear,
      reason: '另一角色造成的存档级心魔通关不得把本人入口变成重打',
    );
    expect(capturedSnapshot!.characterId, 7);
  });
}
