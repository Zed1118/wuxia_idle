import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/light_foot/application/light_foot_participant_service.dart';
import 'package:wuxia_idle/features/light_foot/presentation/light_foot_screen.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Character character(int id, String name, {required bool founder}) =>
      Character.create(
        name: name,
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: founder ? LineageRole.founder : LineageRole.disciple,
        createdAt: DateTime.utc(2026, 8, 25),
      )..id = id;

  testWidgets('路线点击逐次选非 active 门人并把 exact snapshot 交给生产 stage seam', (
    tester,
  ) async {
    final candidates = [
      LightFootParticipantCandidate(
        character: character(1, '掌门', founder: true),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
      LightFootParticipantCandidate(
        character: character(2, '空闲门人', founder: false),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
    ];
    CombatantSnapshot? captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async =>
                MainlineProgress()..clearedStageIds = const ['stage_06_05'],
          ),
          lightFootParticipantCandidatesProvider.overrideWith(
            (ref) async => candidates,
          ),
        ],
        child: MaterialApp(
          home: LightFootScreen(
            participantSnapshotResolverForTest: (requestedId) async =>
                testCombatantSnapshot(
                  characterId: requestedId,
                  name: requestedId == 2 ? '空闲门人' : '掌门',
                  includeProductionBasicAttack: true,
                ),
            stageRunnerForTest:
                ({
                  required context,
                  required ref,
                  required stage,
                  required targetCycle,
                  required participantSnapshot,
                }) async {
                  captured = participantSnapshot;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstStage = GameRepository.instance.getStage('stage_light_foot_01');
    await tester.tap(find.text(firstStage.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('空闲门人'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.characterId, 2);
    expect(captured!.name, '空闲门人');
  });
}
