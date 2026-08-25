import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_participant_snapshot_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
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

  test('生产入口把全局自动设置、前台 bot 与快速重演接到既有同核组件', () {
    final stageList = File(
      'lib/features/mainline/presentation/stage_list_screen.dart',
    ).readAsStringSync();
    final host = File(
      'lib/features/mainline/presentation/phase0a_mainline_battle_host.dart',
    ).readAsStringSync();
    final runner = File(
      'lib/features/sweep/application/phase0a_sweep_headless_runner.dart',
    ).readAsStringSync();

    expect(stageList, contains('gameplaySettingsProvider.future'));
    expect(stageList, contains('ActivityController.playerBot'));
    expect(stageList, contains('MainlineHeadlessReplayUnit'));
    expect(host, contains('Phase0aPlayerBotAdapter'));
    expect(host, contains('botCommandBuilder:'));
    expect(runner, contains('ActivityClock.headless'));
    expect(runner, contains('MainlineParticipantSnapshotService'));
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
