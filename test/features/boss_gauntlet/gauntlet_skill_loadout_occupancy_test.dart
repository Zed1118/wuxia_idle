import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/cangjingge_screen.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/skill_proficiency_row.dart';
import 'package:wuxia_idle/features/character_panel/presentation/encounter_skill_section.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_service.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service_providers.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_ui.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';
import '../../support/test_data.dart';

enum _Operation {
  equipNumeric,
  unequipNumeric,
  equipEncounter,
  unequipEncounter,
}

void main() {
  late Directory directory;
  late int characterId;
  late Character widgetCharacter;
  late List<Technique> widgetTechniques;
  const encounterId = 'skill_encounter_jichu_buxi';
  const replacementEncounterId = 'skill_encounter_pu_xi_tu';

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gauntlet_loadout_');
    await IsarSetup.init(directory: directory, inspector: false);
    final profile = await seedPhase0aCh1FounderProfile(
      isar: IsarSetup.instance,
      schoolId: 'yin_rou',
      originId: 'mountain_wanderer',
      fateId: 'balanced_seed',
      rngSeed: 20260820,
    );
    characterId = profile.snapshot.characterId;
    // 这里只构造占用边界夹具；解锁与下方会话不冒充真实奇遇、入庄、胜利或首通。
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.skillUnlockProgress = List.of(save.skillUnlockProgress)
        ..markUnlocked(encounterId)
        ..markUnlocked(replacementEncounterId);
      await IsarSetup.instance.saveDatas.put(save);
    });
    expect(
      await EncounterService(isar: IsarSetup.instance).equipEncounterSkill(
        characterId: characterId,
        skillDef: GameRepository.instance.skillDefs[encounterId]!,
        saveDataId: 0,
      ),
      isA<EquipSucceeded>(),
    );
    widgetCharacter = (await IsarSetup.instance.characters.get(characterId))!;
    widgetTechniques = await IsarSetup.instance.techniques
        .filter()
        .ownerCharacterIdEqualTo(characterId)
        .findAll();
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<int> occupy(GauntletPhase phase, {int? memberId}) =>
      IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.bossGauntletRuns.put(
          BossGauntletRun()
            ..saveDataId = 0
            ..seed = 73
            ..sessionPhase = phase
            ..members = [
              ActivityMemberSnapshot()..characterId = memberId ?? characterId,
            ],
        ),
      );

  Future<dynamic> invoke(_Operation operation) {
    final isar = IsarSetup.instance;
    return switch (operation) {
      _Operation.equipNumeric => SkillLoadoutService(isar).equipSkill(
        characterId: characterId,
        slot: SkillSlot.main1,
        // 采用真实入门心法候选；该普攻装入后会从映射器的数值运行槽中移除。
        skillId: 'skill_yinrou_jichu_basic',
      ),
      _Operation.unequipNumeric => SkillLoadoutService(
        isar,
      ).unequipSlot(characterId: characterId, slot: SkillSlot.main1),
      _Operation.equipEncounter =>
        EncounterService(isar: isar).equipEncounterSkill(
          characterId: characterId,
          skillDef: GameRepository.instance.skillDefs[replacementEncounterId]!,
          saveDataId: 0,
        ),
      _Operation.unequipEncounter => EncounterService(
        isar: isar,
      ).unequipEncounterSkill(characterId: characterId),
    };
  }

  Future<void> expectBlocked(_Operation operation) async {
    switch (operation) {
      case _Operation.equipNumeric:
        expect(await invoke(operation), isA<SlotEquipOccupied>());
      case _Operation.equipEncounter:
        expect(await invoke(operation), isA<EquipOccupied>());
      case _Operation.unequipNumeric || _Operation.unequipEncounter:
        await expectLater(invoke(operation), throwsStateError);
    }
  }

  Future<void> expectAllowed(_Operation operation) async {
    switch (operation) {
      case _Operation.equipNumeric:
        expect(await invoke(operation), isA<SlotEquipSucceeded>());
        expect(
          (await IsarSetup.instance.characters.get(characterId))!.mainSkillId1,
          'skill_yinrou_jichu_basic',
        );
      case _Operation.equipEncounter:
        expect(await invoke(operation), isA<EquipSucceeded>());
        expect(
          (await IsarSetup.instance.characters.get(
            characterId,
          ))!.equippedEncounterSkillId,
          replacementEncounterId,
        );
      case _Operation.unequipNumeric:
        await invoke(operation);
        expect(
          (await IsarSetup.instance.characters.get(characterId))!.mainSkillId1,
          isNull,
        );
      case _Operation.unequipEncounter:
        expect(await invoke(operation), isTrue);
        expect(
          (await IsarSetup.instance.characters.get(
            characterId,
          ))!.equippedEncounterSkillId,
          isNull,
        );
    }
  }

  for (final phase in [
    GauntletPhase.inBattle,
    GauntletPhase.interlude,
    GauntletPhase.awaitingRewardChoice,
  ]) {
    for (final operation in _Operation.values) {
      test(
        '${phase.name} rejects ${operation.name} without any row change',
        () async {
          await occupy(phase);
          // 重开存档证明守卫读取持久占用，而非依赖界面状态。
          await IsarSetup.close();
          await IsarSetup.init(directory: directory, inspector: false);
          final isar = IsarSetup.instance;
          final charactersBefore = await isar.characters.where().exportJson();
          final runsBefore = await isar.bossGauntletRuns.where().exportJson();
          final saveBefore = await isar.saveDatas.where().exportJson();
          await expectBlocked(operation);
          expect(await isar.characters.where().exportJson(), charactersBefore);
          expect(await isar.bossGauntletRuns.where().exportJson(), runsBefore);
          expect(await isar.saveDatas.where().exportJson(), saveBefore);
        },
      );
    }
  }

  for (final operation in _Operation.values) {
    test(
      'release restores ${operation.name}; unrelated members do not block',
      () async {
        final runId = await occupy(GauntletPhase.interlude);
        await expectBlocked(operation);
        await IsarSetup.instance.writeTxn(
          () => IsarSetup.instance.bossGauntletRuns.delete(runId),
        );
        await occupy(GauntletPhase.inBattle, memberId: characterId + 100);
        await expectAllowed(operation);
      },
    );

    test(
      'does not add retreat or expedition restrictions to ${operation.name}',
      () async {
        final isar = IsarSetup.instance;
        await isar.writeTxn(() async {
          final character = (await isar.characters.get(characterId))!
            ..currentRetreatSessionId = 19;
          await isar.characters.put(character);
          await isar.expeditionRuns.put(
            ExpeditionRun()
              ..saveDataId = 0
              ..policy = ExpeditionPolicy.yanJingCaiYao
              ..seed = 73
              ..departedAt = DateTime(2026, 9, 14)
              ..members = [ActivityMemberSnapshot()..characterId = characterId],
          );
        });
        await expectAllowed(operation);
      },
    );
  }

  Future<void> pumpLoadoutUi(
    WidgetTester tester, {
    required bool cangjingge,
    required Size size,
    required Future<BossGauntletRun?> Function() loadRun,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final secret = GameRepository.instance.skillDefs.values.firstWhere(
      (skill) =>
          skill.style == widgetCharacter.school &&
          (skill.source == SkillSource.mainlineDrop ||
              skill.source == SkillSource.fragment ||
              skill.source == SkillSource.gauntlet),
    );
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        retry: (retryCount, error) => null,
        overrides: [
          // 界面夹具只替换读取源，避免在假时钟内触发真实 Isar 写事务。
          isarProvider.overrideWithValue(null),
          activeCharacterIdsProvider.overrideWith((ref) async => [characterId]),
          characterByIdProvider(
            characterId,
          ).overrideWith((ref) async => widgetCharacter),
          characterAllTechniquesProvider(
            characterId,
          ).overrideWith((ref) async => widgetTechniques),
          unlockedSkillIdSetProvider.overrideWith(
            (ref) async => {encounterId, replacementEncounterId, secret.id},
          ),
          activeGauntletProvider.overrideWith((ref) => loadRun()),
        ],
        child: MaterialApp(
          home: cangjingge
              ? CangJingGeScreen(characterId: characterId)
              : Scaffold(
                  body: EncounterSkillSection(character: widgetCharacter),
                ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  void expectLoadoutControls(
    WidgetTester tester, {
    required bool cangjingge,
    required bool blocked,
  }) {
    if (cangjingge) {
      final labels = [
        UiStrings.cangjingSlotMain(1),
        UiStrings.cangjingSlotMain(2),
        UiStrings.cangjingSlotAssist,
        UiStrings.cangjingSlotResonance,
        UiStrings.cangjingSlotUltimate,
        UiStrings.cangjingSlotKey,
        UiStrings.cangjingSlotEncounter,
      ];
      for (final label in labels) {
        final slot = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(slot, findsOneWidget);
        final control = tester.widget<InkWell>(slot);
        expect(control.onTap, blocked ? isNull : isNotNull);
        expect(control.canRequestFocus, !blocked);
        final semantics = tester.widgetList<Semantics>(
          find.ancestor(of: slot, matching: find.byType(Semantics)),
        );
        expect(
          semantics.any(
            (node) =>
                node.properties.button == true &&
                node.properties.enabled == !blocked,
          ),
          isTrue,
        );
      }
      expect(find.text(UiStrings.cangjingSecretGroupTitle), findsOneWidget);
      final rows = tester.widgetList<SkillProficiencyRow>(
        find.byType(SkillProficiencyRow),
      );
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row.onTap, blocked ? isNull : isNotNull);
      }
    } else {
      for (final label in [
        UiStrings.encounterSkillPickButton,
        UiStrings.encounterSkillUnequipButton,
      ]) {
        final button = find.widgetWithText(PlaqueButton, label);
        final control = tester.widget<PlaqueButton>(button);
        expect(control.disabled, blocked);
        expect(control.onTap, blocked ? isNull : isNotNull);
        final focus = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: button,
            matching: find.byType(FocusableActionDetector),
          ),
        );
        expect(focus.enabled, !blocked);
        final semantics = tester.widgetList<Semantics>(
          find.descendant(of: button, matching: find.byType(Semantics)),
        );
        expect(
          semantics.any(
            (node) =>
                node.properties.button == true &&
                node.properties.enabled == !blocked,
          ),
          isTrue,
        );
      }
    }
    expect(tester.takeException(), isNull);
  }

  for (final cangjingge in [true, false]) {
    final screen = cangjingge ? '藏经阁' : '角色奇遇招式';
    for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
      testWidgets(
        '$screen ${size.width.toInt()}×${size.height.toInt()} 在庄成员灰显并提示，非成员可用',
        (tester) async {
          for (final occupied in [true, false]) {
            await pumpLoadoutUi(
              tester,
              cangjingge: cangjingge,
              size: size,
              loadRun: () async => BossGauntletRun()
                ..sessionPhase = GauntletPhase.interlude
                ..members = [
                  ActivityMemberSnapshot()
                    ..characterId = occupied ? characterId : characterId + 100,
                ],
            );
            expectLoadoutControls(
              tester,
              cangjingge: cangjingge,
              blocked: occupied,
            );
            expect(
              find.text(UiStrings.gauntletSkillLoadoutOccupied),
              occupied ? findsOneWidget : findsNothing,
            );
          }
        },
      );
    }

    for (final error in [false, true]) {
      testWidgets('$screen 会话${error ? '异常' : '加载'}时禁用手动装卸', (tester) async {
        final pending = Completer<BossGauntletRun?>();
        await pumpLoadoutUi(
          tester,
          cangjingge: cangjingge,
          size: const Size(1280, 720),
          loadRun: () => error
              ? Future.error(StateError('gauntlet read failed'))
              : pending.future,
        );
        expectLoadoutControls(tester, cangjingge: cangjingge, blocked: true);
        expect(find.text(UiStrings.gauntletSkillLoadoutOccupied), findsNothing);
        if (!error) {
          pending.complete(null);
          await tester.pump();
          await tester.pump();
          expectLoadoutControls(tester, cangjingge: cangjingge, blocked: false);
        }
      });
    }
  }
}
