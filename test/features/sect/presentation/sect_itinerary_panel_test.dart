import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/sect/application/sect_itinerary_provider.dart';
import 'package:wuxia_idle/features/sect/domain/sect_itinerary_summary.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_hub_screen.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_itinerary_panel.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  const summary = SectItinerarySummary(
    leaderId: 1,
    leaderName: '沈掌门',
    occupiedMembers: [
      SectItineraryOccupiedMember(
        characterId: 2,
        name: '叶问舟',
        activity: ActivityKind.retreat,
      ),
      SectItineraryOccupiedMember(
        characterId: 3,
        name: '程青崖',
        activity: ActivityKind.expedition,
      ),
      SectItineraryOccupiedMember(
        characterId: 4,
        name: '顾长风',
        activity: ActivityKind.bossGauntlet,
      ),
    ],
    expeditionDepth: 6,
    expeditionDefeated: false,
    gauntletStage: 2,
    gauntletPhase: GauntletPhase.interlude,
  );

  testWidgets('宗门 Hub 顶部展示宗门行止当前态面板', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: SectHubScreen(
            seclusionLocked: false,
            taohuaLocked: false,
            sectLocked: false,
            expeditionUnlocked: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('sect-itinerary-panel')), findsOneWidget);
    expect(find.text(UiStrings.sectItineraryTitle), findsOneWidget);
  });

  testWidgets('面板展示真实掌门、占用与两类 active 进度', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sectItineraryProvider.overrideWith((ref) async => summary)],
        child: const MaterialApp(home: Scaffold(body: SectItineraryPanel())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.sectItineraryLeader(
          '沈掌门',
          UiStrings.sectItineraryLeaderAtSect,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        UiStrings.sectItineraryOccupiedMembers(
          UiStrings.sectItineraryActivityRetreat,
          const ['叶问舟'],
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.sectItineraryExpeditionActive(6, false)),
      findsOneWidget,
    );
    expect(
      find.text(
        UiStrings.sectItineraryGauntletActive(
          2,
          UiStrings.gauntletPhaseInterlude,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('数据异常时面板 fail closed，不猜测掌门', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sectItineraryProvider.overrideWith(
            (ref) => Future.error(StateError('dangling leader')),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SectItineraryPanel())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.sectItineraryUnavailable), findsOneWidget);
    expect(find.textContaining('沈掌门'), findsNothing);
  });
}
