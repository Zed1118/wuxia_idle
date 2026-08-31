import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_providers.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mass_battle/application/mass_battle_participant_service.dart';
import 'package:wuxia_idle/features/mass_battle/presentation/mass_battle_screen.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

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

  testWidgets('逐次选择空闲门人后 exact snapshot 进入守城生产 stage seam', (tester) async {
    final candidates = [
      MassBattleParticipantCandidate(
        character: character(1, '掌门', founder: true),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
      MassBattleParticipantCandidate(
        character: character(2, '守城门人', founder: false),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
    ];
    CombatantSnapshot? captured;
    ActivityController? capturedController;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async =>
                MainlineProgress()..clearedStageIds = const ['stage_06_05'],
          ),
          massBattleParticipantCandidatesProvider.overrideWith(
            (ref) async => candidates,
          ),
        ],
        child: MaterialApp(
          home: MassBattleScreen(
            participantSnapshotResolverForTest: (requestedId) async =>
                testCombatantSnapshot(
                  characterId: requestedId,
                  name: requestedId == 2 ? '守城门人' : '掌门',
                  includeProductionBasicAttack: true,
                ),
            stageRunnerForTest:
                ({
                  required context,
                  required ref,
                  required stage,
                  required targetCycle,
                  required participantSnapshot,
                  required controller,
                }) async {
                  captured = participantSnapshot;
                  capturedController = controller;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstStage = GameRepository.instance.getStage('stage_mass_battle_01');
    await tester.tap(find.text(firstStage.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('守城门人'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.characterId, 2);
    expect(captured!.name, '守城门人');
    expect(capturedController, ActivityController.human);
  });

  testWidgets('已首通守城可见重打消费全局自动设置进入前台 bot', (tester) async {
    final candidates = [
      MassBattleParticipantCandidate(
        character: character(2, '托管守卒', founder: false),
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
    ];
    ActivityController? capturedController;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async =>
                MainlineProgress()
                  ..clearedStageIds = const ['stage_mass_battle_01'],
          ),
          durableActivityRunProvider(
            DurableActivityKind.massBattle,
          ).overrideWith((ref) async => null),
          massBattleParticipantCandidatesProvider.overrideWith(
            (ref) async => candidates,
          ),
          gameplaySettingsProvider.overrideWith(
            (ref) async => const GameplaySettings(autoPlayDefault: true),
          ),
        ],
        child: MaterialApp(
          home: MassBattleScreen(
            participantSnapshotResolverForTest: (requestedId) async =>
                testCombatantSnapshot(
                  characterId: requestedId,
                  name: '托管守卒',
                  includeProductionBasicAttack: true,
                ),
            stageRunnerForTest:
                ({
                  required context,
                  required ref,
                  required stage,
                  required targetCycle,
                  required participantSnapshot,
                  required controller,
                }) async {
                  capturedController = controller;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstStage = GameRepository.instance.getStage('stage_mass_battle_01');
    await tester.tap(find.text(firstStage.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('托管守卒'));
    await tester.pumpAndSettle();

    expect(capturedController, ActivityController.playerBot);
  });

  testWidgets('已首通守城关在 durable provider 已决且无在途 run 时显示生产差遣入口', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async =>
                MainlineProgress()
                  ..clearedStageIds = const ['stage_mass_battle_01'],
          ),
          durableActivityRunProvider(
            DurableActivityKind.massBattle,
          ).overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: MassBattleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.schedule_send_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fast_forward_outlined), findsOneWidget);
  });
}
