import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/presentation/encounter_dialog.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_pending_jianghu_affair_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement_journal_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_pending_jianghu_affair.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
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
      'mainline_encounter_outcome_sequence_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets('下一关待处理机缘等待结果浮层关闭并覆盖常规桌面视口', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final seeded = await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      final founder = Character.create(
        name: '机缘时序测试掌门',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()..fortune = 10,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime.utc(2026, 8, 30),
        internalForce: 3000,
      );
      await isar.writeTxn(() async {
        await isar.characters.put(founder);
        final save = (await isar.saveDatas.get(0))!;
        save
          ..activeCharacterIds = [founder.id]
          ..founderCharacterId = founder.id;
        await isar.saveDatas.put(save);
      });
      final numbers = GameRepository.instance.numbers;
      await EncounterService(
        isar: isar,
        attributeGainCap: numbers.adventureAttributeLifetimeCap,
        attributeEffects: numbers.attributeEffects,
      ).getOrCreate(saveDataId: IsarSetup.currentSlotId);

      final identity = MainlineSettlementIdentity(
        runId: 'encounter-outcome-sequence',
        stageId: 'stage_01_03',
        loadoutVersion: 3,
        participantId: founder.id,
      );
      final journalService = MainlineSettlementJournalService(isar);
      await journalService.prepare(
        saveDataId: IsarSetup.currentSlotId,
        identity: identity,
        loadoutSnapshotId: 'snapshot-3',
        loadoutSnapshotIds: const ['snapshot-1', 'snapshot-2', 'snapshot-3'],
        now: DateTime.utc(2026, 8, 30),
      );
      final affair = MainlinePendingJianghuAffairRef.encounterChoice(
        settlementId: identity.canonical,
        encounterId: 'du_ke_wen_dao',
        ordinal: 1,
        resolutionSeed: 17,
      );
      await MainlinePendingJianghuAffairService(journalService).commitCore(
        identity: identity,
        now: DateTime.utc(2026, 8, 30, 0, 1),
        applyInTxn: () async => [affair],
      );
      return (
        stage: GameRepository.instance.getStage('stage_01_03'),
        settlement: (service: journalService, identity: identity),
      );
    });
    final evidence = seeded!;
    var resultText = 'pending';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => StatefulBuilder(
              builder: (context, setState) {
                return _SequenceHarness(
                  child: resultText == 'pending'
                      ? const Text('pending')
                      : Text(resultText, key: const Key('sequence-result')),
                  onStart: () async {
                    final drained =
                        await drainMainlinePendingJianghuAffairsForTest(
                          context: context,
                          ref: ref,
                          stage: evidence.stage,
                          durableSettlement: evidence.settlement,
                          includeStageBossRecruit: false,
                        );
                    if (!context.mounted) return;
                    setState(() {
                      resultText = drained
                          ? 'next-stage-ready'
                          : 'flow-stopped';
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('sequence-start')));
    await _pumpUntil(tester, find.text('渡客问道'));
    await tester.tap(find.text('辞酒不饮'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.encounterDialogConfirmButton));
    await _pumpUntil(tester, find.byType(EncounterOutcomeOverlay));

    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.byType(EncounterOutcomeOverlay), findsOneWidget);
    expect(find.byKey(const Key('sequence-result')), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await _pumpUntil(tester, find.byKey(const Key('sequence-result')));
    expect(find.text('next-stage-ready'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pump();
    await tester.tap(find.byKey(const Key('layout-smoke-trigger')));
    await _pumpUntil(tester, find.byType(EncounterOutcomeOverlay));
    expect(
      tester.getSize(find.byType(EncounterOutcomeOverlay)),
      const Size(1440, 900),
    );
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
  });
}

class _SequenceHarness extends StatelessWidget {
  const _SequenceHarness({required this.child, required this.onStart});

  final Widget child;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            key: const Key('sequence-start'),
            onPressed: onStart,
            child: const Text('start'),
          ),
          TextButton(
            key: const Key('layout-smoke-trigger'),
            onPressed: () async {
              await showEncounterOutcomeBanner(
                context: context,
                applied: const NoneOutcome(),
              );
            },
            child: const Text('layout-smoke'),
          ),
          child,
        ],
      ),
    );
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(finder, findsOneWidget);
}
