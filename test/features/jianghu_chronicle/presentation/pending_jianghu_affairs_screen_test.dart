import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu_chronicle/presentation/pending_jianghu_affairs_screen.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_pending_jianghu_affair_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_pending_jianghu_affair.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  final identity = MainlineSettlementIdentity(
    runId: 'run-pending-ui',
    stageId: 'stage_01_03',
    loadoutVersion: 1,
    participantId: 42,
  );

  MainlinePendingJianghuAffairsSnapshot snapshot() => (
    identity: identity,
    stageId: identity.stageId,
    affairs: [
      MainlinePendingJianghuAffairRef.encounterChoice(
        settlementId: identity.canonical,
        encounterId: 'encounter-a',
        ordinal: 1,
        resolutionSeed: 101,
      ),
      MainlinePendingJianghuAffairRef.stageBossRecruit(
        settlementId: identity.canonical,
        stageId: identity.stageId,
        candidateRef: 'candidate-a',
        ordinal: 2,
        resolutionSeed: 102,
      ),
    ],
  );

  testWidgets('按 typed FIFO 展示事项，处理按钮调用既有恢复流并刷新空态', (tester) async {
    var resumed = 0;
    var loadCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PendingJianghuAffairsScreen(
          loaderForTest: () async => loadCount++ == 0 ? snapshot() : null,
          resumeForTest: (context, ref, value) async {
            expect(value.identity, identity);
            resumed++;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(UiStrings.pendingJianghuAffairEncounterChoice),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.pendingJianghuAffairBossRecruit),
      findsOneWidget,
    );

    await tester.tap(find.text(UiStrings.pendingJianghuAffairsResume));
    await tester.pump();
    await tester.pump();

    expect(resumed, 1);
    expect(find.text(UiStrings.pendingJianghuAffairsEmpty), findsOneWidget);
  });

  testWidgets('无 active outbox 时显示空态且不提供伪处理入口', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PendingJianghuAffairsScreen(loaderForTest: () async => null),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.pendingJianghuAffairsEmpty), findsOneWidget);
    expect(find.text(UiStrings.pendingJianghuAffairsResume), findsNothing);
  });

  testWidgets('损坏或多 active journal 读取失败时 fail closed', (tester) async {
    var resumed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PendingJianghuAffairsScreen(
          loaderForTest: () => Future.error(StateError('broken journal')),
          resumeForTest: (context, ref, value) async => resumed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(UiStrings.pendingJianghuAffairsUnavailable),
      findsOneWidget,
    );
    expect(find.text(UiStrings.pendingJianghuAffairsResume), findsNothing);
    expect(resumed, isFalse);
  });
}
