import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_narrative_manifest.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_participant_snapshot_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/sweep/presentation/sweep_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late MainlineNarrativeManifest narrativeManifest;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
    narrativeManifest = await MainlineNarrativeManifest.load(
      loader: (path) => File(path).readAsString(),
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'mainline_all_mode_consistency_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<Character> insertCharacter(
    String name, {
    required bool founder,
  }) async {
    final isar = IsarSetup.instance;
    final character = Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: founder ? LineageRole.founder : LineageRole.disciple,
      createdAt: DateTime.utc(2026, 8, 25),
      internalForce: 3000,
      school: TechniqueSchool.gangMeng,
      isFounder: founder,
      isAlive: true,
    );
    await isar.writeTxn(() => isar.characters.put(character));
    final technique = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: character.id,
      tier: TechniqueTier.values.first,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.utc(2026, 8, 25),
    );
    await isar.writeTxn(() async {
      character.mainTechniqueId = await isar.techniques.put(technique);
      await isar.characters.put(character);
    });
    return character;
  }

  Future<(Character, Character)> seedRoster() async {
    final leader = await insertCharacter('掌门甲', founder: true);
    final disciple = await insertCharacter('门人乙', founder: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save
        ..activeCharacterIds = [leader.id, disciple.id]
        ..founderCharacterId = leader.id;
      await isar.saveDatas.put(save);
    });
    return (leader, disciple);
  }

  Future<MainlineProgress> seedClearedProgress(String stageId) async {
    final progress = MainlineProgress()
      ..saveDataId = IsarSetup.currentSlotId
      ..currentChapterIndex = 1
      ..clearedStageIds = [stageId]
      ..clearedAt = [DateTime.utc(2026, 8, 25)]
      ..clearedStageCycleKeys = ['$stageId#1'];
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.mainlineProgress.put(progress),
    );
    return progress;
  }

  Future<WidgetRef> pumpStageList(
    WidgetTester tester, {
    required MainlineProgress progress,
    required List<Character> activeCharacters,
    required bool autoPlayDefault,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => progress),
          mainlineNarrativeManifestProvider.overrideWith(
            (ref) async => narrativeManifest,
          ),
          activeCharacterIdsProvider.overrideWith(
            (ref) async => [
              for (final character in activeCharacters) character.id,
            ],
          ),
          for (final character in activeCharacters)
            characterByIdProvider(
              character.id,
            ).overrideWith((ref) async => character),
          gameplaySettingsProvider.overrideWith(
            (ref) async => GameplaySettings(autoPlayDefault: autoPlayDefault),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const MaterialApp(home: StageListScreen(chapterIndex: 1));
          },
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    return capturedRef;
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 120,
  }) async {
    for (var i = 0; i < maxPumps && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(finder, findsOneWidget);
  }

  ActivityParticipationRequest request({
    required int characterId,
    required ActivityController controller,
    required ActivityClock clock,
    required ActivityEntryKind entryKind,
  }) => ActivityParticipationRequest(
    contentId: 'stage_01_01',
    contentKind: ActivityContentKind.mainline,
    characterId: characterId,
    loadoutPlanId: mainlineLoadoutPlanId(
      stageId: 'stage_01_01',
      characterId: characterId,
    ),
    participation: ActivityParticipationMode.direct,
    controller: controller,
    clock: clock,
    entryKind: entryKind,
  );

  testWidgets('已通关主线明确区分可见重打与快速 headless 重演', (tester) async {
    MainlineReplayMode? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showMainlineReplayModePicker(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.mainlineVisibleReplayMode), findsOneWidget);
    expect(find.text(UiStrings.mainlineHeadlessReplayMode), findsOneWidget);

    await tester.tap(find.byKey(const Key('mainline_headless_replay_mode')));
    await tester.pumpAndSettle();
    expect(selected, MainlineReplayMode.headless);
  });

  testWidgets('StageListScreen 可见重打消费 bot/realtime 与同一门人快照', (tester) async {
    final seeded = await tester.runAsync(() async {
      final (leader, disciple) = await seedRoster();
      final progress = await seedClearedProgress('stage_01_01');
      return (leader: leader, disciple: disciple, progress: progress);
    });
    final leader = seeded!.leader;
    final disciple = seeded.disciple;
    final progress = seeded.progress;
    await pumpStageList(
      tester,
      progress: progress,
      activeCharacters: [leader, disciple],
      autoPlayDefault: true,
    );

    await tester.tap(find.text('山门之外'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mainline_visible_replay_mode')));
    final participantFinder = find.byKey(
      Key('mainline_replay_participant_${disciple.id}'),
    );
    await pumpUntilFound(tester, participantFinder);
    await tester.tap(participantFinder);
    await pumpUntilFound(tester, find.byType(Phase0aMainlineBattleHost));

    try {
      final host = tester.widget<Phase0aMainlineBattleHost>(
        find.byType(Phase0aMainlineBattleHost),
      );
      await pumpUntilFound(tester, find.byType(Phase0aBattleScreen));
      final screen = tester.widget<Phase0aBattleScreen>(
        find.byType(Phase0aBattleScreen),
      );
      expect(host.controller, ActivityController.playerBot);
      expect(host.playerSnapshot?.characterId, disciple.id);
      expect(
        screen.controller.roster.nameOf(screen.controller.state.player.id),
        disciple.name,
      );
      expect(screen.botCommandBuilder, isNotNull);
    } finally {
      if (find.byType(Phase0aMainlineBattleHost).evaluate().isNotEmpty) {
        Navigator.of(
          tester.element(find.byType(Phase0aMainlineBattleHost)),
        ).pop();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('StageListScreen 快速重演消费 headless 当前掌门快照', (tester) async {
    final seeded = await tester.runAsync(() async {
      final (leader, disciple) = await seedRoster();
      final progress = await seedClearedProgress('stage_01_01');
      return (leader: leader, disciple: disciple, progress: progress);
    });
    final leader = seeded!.leader;
    final disciple = seeded.disciple;
    final progress = seeded.progress;
    final ref = await pumpStageList(
      tester,
      progress: progress,
      activeCharacters: [leader, disciple],
      autoPlayDefault: false,
    );

    await tester.tap(find.text('山门之外'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mainline_headless_replay_mode')));
    await tester.pumpAndSettle();

    final sweepScreen = tester.widget<SweepScreen>(find.byType(SweepScreen));
    expect(
      sweepScreen.presentationMode,
      HeadlessRunPresentationMode.mainlineReplay,
    );
    final unit = sweepScreen.units.single as MainlineHeadlessReplayUnit;
    expect(unit.stage.id, 'stage_01_01');
    expect(unit.cycle, 1);
    final result = await tester.runAsync(
      () => unit.runPhase0aHeadless(
        ref,
        policy: const Phase0aBotTacticPolicy.assault(),
      ),
    );
    expect(result, isNotNull);
    expect(result!.timedOut, isFalse);
    expect(result.expectedParticipantId, leader.id);
    expect(result.participantName, leader.name);
    expect(result.settlement?.participantCharacterIds.where((id) => id > 0), {
      leader.id,
    });
  });

  test('可见真人与前台 bot 都锁定玩家选择的 eligible 空闲门人', () async {
    final (_, disciple) = await seedRoster();
    final service = MainlineParticipantSnapshotService(IsarSetup.instance);

    for (final controller in [
      ActivityController.human,
      ActivityController.playerBot,
    ]) {
      final resolved = await service.resolve(
        request(
          characterId: disciple.id,
          controller: controller,
          clock: ActivityClock.realtime,
          entryKind: ActivityEntryKind.replay,
        ),
      );
      expect(resolved.selection.participantId, disciple.id);
      expect(resolved.snapshot.characterId, disciple.id);
      expect(resolved.request.controller, controller);
    }
  });

  test('headless 与 sweep 固定当前掌门，错人或不可战状态均 fail closed', () async {
    final (leader, disciple) = await seedRoster();
    final service = MainlineParticipantSnapshotService(IsarSetup.instance);

    for (final entryKind in [
      ActivityEntryKind.replay,
      ActivityEntryKind.sweep,
    ]) {
      final resolved = await service.resolve(
        request(
          characterId: leader.id,
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
          entryKind: entryKind,
        ),
      );
      expect(resolved.snapshot.characterId, leader.id);

      expect(
        () => service.resolve(
          request(
            characterId: disciple.id,
            controller: ActivityController.playerBot,
            clock: ActivityClock.headless,
            entryKind: entryKind,
          ),
        ),
        throwsA(isA<MainlineParticipationRefusedError>()),
      );
    }

    await IsarSetup.instance.writeTxn(() async {
      leader.currentRetreatSessionId = 7;
      await IsarSetup.instance.characters.put(leader);
    });
    expect(
      () => service.resolve(
        request(
          characterId: leader.id,
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
          entryKind: ActivityEntryKind.sweep,
        ),
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );
  });

  test('未通关自动字段组合、疗养、跨代与悬空主修均 fail closed', () async {
    final (leader, _) = await seedRoster();
    final service = MainlineParticipantSnapshotService(IsarSetup.instance);

    expect(
      () => service.resolve(
        request(
          characterId: leader.id,
          controller: ActivityController.playerBot,
          clock: ActivityClock.realtime,
          entryKind: ActivityEntryKind.firstClear,
        ),
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );

    await IsarSetup.instance.writeTxn(() async {
      leader.injuryHoursRemaining = 1;
      await IsarSetup.instance.characters.put(leader);
    });
    expect(
      () => service.resolve(
        request(
          characterId: leader.id,
          controller: ActivityController.human,
          clock: ActivityClock.realtime,
          entryKind: ActivityEntryKind.firstClear,
        ),
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );

    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.activeCharacterIds = [];
      leader
        ..injuryHoursRemaining = 0
        ..mainTechniqueId = 999999;
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.characters.put(leader);
    });
    expect(
      () => service.resolve(
        request(
          characterId: leader.id,
          controller: ActivityController.human,
          clock: ActivityClock.realtime,
          entryKind: ActivityEntryKind.firstClear,
        ),
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );
  });
}
