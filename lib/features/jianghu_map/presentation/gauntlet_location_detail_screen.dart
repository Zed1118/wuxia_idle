import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';
import '../../boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import '../application/gauntlet_location_detail_provider.dart';
import '../domain/gauntlet_location_detail.dart';

class GauntletLocationDetailScreen extends ConsumerWidget {
  const GauntletLocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(gauntletLocationDetailProvider);
    return Scaffold(
      key: const ValueKey('gauntlet-location-detail-screen'),
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.gauntletLocationDetailTitle,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const _UnavailableContent(),
              data: (value) => _DetailContent(detail: value),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: const [
      LightPaperPanel(
        key: ValueKey('gauntlet-location-detail-unavailable'),
        child: Text(
          UiStrings.gauntletLocationUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaUi.ink, height: 1.5),
        ),
      ),
    ],
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final GauntletLocationDetail detail;

  @override
  Widget build(BuildContext context) {
    final canEnter = detail.hasActiveRun || detail.availableCandidateCount > 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        LightPaperPanel(
          key: const ValueKey('gauntlet-location-detail-intel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                label: UiStrings.gauntletLocationProgressLabel,
                value: _progressSummary(detail),
              ),
              _DetailRow(
                label: UiStrings.gauntletLocationRecommendedRealmLabel,
                value: EnumL10n.realmTier(detail.recommendedRealm),
              ),
              _DetailRow(
                label: UiStrings.gauntletLocationEnemyEcologyLabel,
                value: _enemySummary(detail),
              ),
              _DetailRow(
                label: UiStrings.gauntletLocationCoreRewardLabel,
                value: UiStrings.gauntletLocationCoreReward(
                  detail.rewardSkillName,
                  detail.rewardEquipmentNames,
                  detail.firstClearRewardExp,
                  detail.firstClearRewardInsight,
                  detail.eliteRewardExp,
                ),
              ),
              _DetailRow(
                label: UiStrings.gauntletLocationTicketLabel,
                value: UiStrings.gauntletLocationTicketAndSupply(
                  detail.ticketCount,
                  detail.supplyCap,
                ),
              ),
              _DetailRow(
                label: UiStrings.gauntletLocationParticipantLabel,
                value: detail.hasActiveRun
                    ? detail.activeParticipantNames.join('、')
                    : UiStrings.gauntletLocationParticipantCandidates(
                        detail.availableCandidateCount,
                        detail.candidateCount,
                      ),
              ),
              const _DetailRow(
                label: UiStrings.gauntletLocationEntryModeLabel,
                value: UiStrings.gauntletLocationEntryModeDirect,
              ),
              const _DetailRow(
                label: UiStrings.gauntletLocationOccupancyLabel,
                value: UiStrings.gauntletLocationExpectedOccupancy,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WuxiaInkButton(
          key: const ValueKey('gauntlet-location-detail-enter'),
          label: detail.hasActiveRun
              ? UiStrings.gauntletLocationResume
              : UiStrings.gauntletLocationEnter,
          hint: detail.hasActiveRun
              ? UiStrings.gauntletLocationResumeHint
              : UiStrings.gauntletLocationEnterHint,
          icon: Icons.whatshot_outlined,
          disabled: !canEnter,
          onTap: canEnter
              ? () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const GauntletLoadoutScreen(),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  String _progressSummary(GauntletLocationDetail value) {
    final stage = value.activeStage;
    final phase = value.activePhase;
    if (stage != null && phase != null) {
      return UiStrings.gauntletLocationActiveProgress(
        stage,
        value.totalStages,
        switch (phase) {
          GauntletPhase.inBattle => UiStrings.gauntletPhaseInBattle,
          GauntletPhase.interlude => UiStrings.gauntletPhaseInterlude,
          GauntletPhase.awaitingRewardChoice =>
            UiStrings.gauntletPhaseAwaitingReward,
          GauntletPhase.settled => UiStrings.gauntletPhaseSettled,
        },
      );
    }
    if (value.clearedCyclesMax == 0) {
      return UiStrings.gauntletLocationFreshProgress(value.totalStages);
    }
    return UiStrings.gauntletLocationProgress(
      value.clearedCyclesMax,
      value.totalStages,
    );
  }

  String _enemySummary(GauntletLocationDetail value) => value.stages
      .map(
        (stage) => UiStrings.gauntletLocationStageEnemy(
          stage.ordinal,
          stage.isBoss,
          stage.enemies
              .map(
                (enemy) => UiStrings.gauntletLocationEnemy(
                  enemy.name,
                  EnumL10n.school(enemy.school),
                ),
              )
              .join('、'),
        ),
      )
      .join('\n');
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
