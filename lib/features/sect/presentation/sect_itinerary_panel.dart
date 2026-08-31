import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../activity/domain/activity_occupancy.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';
import '../application/sect_itinerary_provider.dart';
import '../domain/sect_itinerary_summary.dart';

class SectItineraryPanel extends ConsumerWidget {
  const SectItineraryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerary = ref.watch(sectItineraryProvider);
    return LightPaperPanel(
      key: const ValueKey('sect-itinerary-panel'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.sectItineraryTitle),
          const SizedBox(height: 8),
          itinerary.when(
            loading: () =>
                const _ItineraryLine(text: UiStrings.sectItineraryLoading),
            error: (_, _) =>
                const _ItineraryLine(text: UiStrings.sectItineraryUnavailable),
            data: (summary) => _SectItineraryContent(summary: summary),
          ),
        ],
      ),
    );
  }
}

class _SectItineraryContent extends StatelessWidget {
  const _SectItineraryContent({required this.summary});

  final SectItinerarySummary summary;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      UiStrings.sectItineraryLeader(summary.leaderName, _leaderStatus(summary)),
      ..._occupancyLines([
        for (final member in summary.occupiedMembers)
          if (member.characterId != summary.leaderId) member,
      ]),
      summary.expeditionDepth == null
          ? UiStrings.sectItineraryExpeditionIdle
          : UiStrings.sectItineraryExpeditionActive(
              summary.expeditionDepth!,
              summary.expeditionDefeated,
            ),
      summary.gauntletStage == null || summary.gauntletPhase == null
          ? UiStrings.sectItineraryGauntletIdle
          : UiStrings.sectItineraryGauntletActive(
              summary.gauntletStage!,
              _gauntletPhaseLabel(summary.gauntletPhase!),
            ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _ItineraryLine(text: lines[i]),
        ],
      ],
    );
  }

  List<String> _occupancyLines(List<SectItineraryOccupiedMember> members) {
    if (members.isEmpty) return const [UiStrings.sectItineraryNoOccupancy];
    return [
      for (final activity in ActivityKind.values)
        if (members.any((member) => member.activity == activity))
          UiStrings.sectItineraryOccupiedMembers(_activityLabel(activity), [
            for (final member in members)
              if (member.activity == activity) member.name,
          ]),
    ];
  }

  String _leaderStatus(SectItinerarySummary summary) {
    for (final member in summary.occupiedMembers) {
      if (member.characterId == summary.leaderId) {
        return _activityLabel(member.activity);
      }
    }
    return UiStrings.sectItineraryLeaderAtSect;
  }

  String _activityLabel(ActivityKind activity) => switch (activity) {
    ActivityKind.retreat => UiStrings.sectItineraryActivityRetreat,
    ActivityKind.expedition => UiStrings.sectItineraryActivityExpedition,
    ActivityKind.bossGauntlet => UiStrings.sectItineraryActivityGauntlet,
    ActivityKind.lightFoot => UiStrings.mainMenuLightFoot,
    ActivityKind.massBattle => UiStrings.mainMenuMassBattle,
  };

  String _gauntletPhaseLabel(GauntletPhase phase) => switch (phase) {
    GauntletPhase.inBattle => UiStrings.gauntletPhaseInBattle,
    GauntletPhase.interlude => UiStrings.gauntletPhaseInterlude,
    GauntletPhase.awaitingRewardChoice => UiStrings.gauntletPhaseAwaitingReward,
    GauntletPhase.settled => UiStrings.gauntletPhaseSettled,
  };
}

class _ItineraryLine extends StatelessWidget {
  const _ItineraryLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: WuxiaUi.ink, fontSize: 13, height: 1.4),
  );
}
