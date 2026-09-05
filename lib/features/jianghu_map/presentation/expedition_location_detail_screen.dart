import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../expedition/domain/expedition_run.dart';
import '../../expedition/presentation/expedition_overview_screen.dart';
import '../application/expedition_location_detail_provider.dart';
import '../domain/expedition_location_detail.dart';

class ExpeditionLocationDetailScreen extends ConsumerWidget {
  const ExpeditionLocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(expeditionLocationDetailProvider);
    return Scaffold(
      key: const ValueKey('expedition-location-detail-screen'),
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.expeditionLocationDetailTitle,
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
        key: ValueKey('expedition-location-detail-unavailable'),
        child: Text(
          UiStrings.expeditionLocationUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaUi.ink, height: 1.5),
        ),
      ),
    ],
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final ExpeditionLocationDetail detail;

  @override
  Widget build(BuildContext context) {
    final canEnter = detail.hasActiveRun || detail.availableCandidateCount > 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        LightPaperPanel(
          key: const ValueKey('expedition-location-detail-intel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                label: UiStrings.expeditionLocationProgressLabel,
                value: _progressSummary(detail),
              ),
              _DetailRow(
                label: UiStrings.expeditionLocationRecommendedRealmLabel,
                value: EnumL10n.realmTier(detail.recommendedRealm),
              ),
              _DetailRow(
                label: UiStrings.expeditionLocationEnemyEcologyLabel,
                value: _enemySummary(detail),
              ),
              _DetailRow(
                label: UiStrings.expeditionLocationRouteEcologyLabel,
                value: UiStrings.expeditionLocationRouteEcology(
                  detail.normalNodeMinutes,
                  detail.eliteNodeMinutes,
                  ExpeditionPolicy.values
                      .map(EnumL10n.expeditionPolicy)
                      .join('、'),
                ),
              ),
              _DetailRow(
                label: UiStrings.expeditionLocationCoreRewardLabel,
                value: UiStrings.expeditionLocationCoreRewards(
                  detail.coreRewardItemNames,
                  detail.includesExperienceReward,
                ),
              ),
              if (detail.activePolicy != null)
                _DetailRow(
                  label: UiStrings.expeditionActivePolicyLabel,
                  value: EnumL10n.expeditionPolicy(detail.activePolicy!),
                ),
              _DetailRow(
                label: UiStrings.expeditionLocationParticipantLabel,
                value: detail.hasActiveRun
                    ? detail.activeParticipantNames.join('、')
                    : UiStrings.expeditionLocationParticipantCandidates(
                        detail.availableCandidateCount,
                        detail.candidateCount,
                      ),
              ),
              const _DetailRow(
                label: UiStrings.expeditionLocationEntryModeLabel,
                value: UiStrings.expeditionLocationEntryModeDispatch,
              ),
              const _DetailRow(
                label: UiStrings.expeditionLocationOccupancyLabel,
                value: UiStrings.expeditionLocationExpectedOccupancy,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WuxiaInkButton(
          key: const ValueKey('expedition-location-detail-enter'),
          label: detail.hasActiveRun
              ? UiStrings.expeditionLocationResume
              : UiStrings.expeditionLocationEnter,
          hint: detail.hasActiveRun
              ? UiStrings.expeditionLocationResumeHint
              : UiStrings.expeditionLocationEnterHint,
          icon: Icons.travel_explore_outlined,
          disabled: !canEnter,
          onTap: canEnter
              ? () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const ExpeditionOverviewScreen(),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  String _progressSummary(ExpeditionLocationDetail value) {
    final activeDepth = value.activeDepth;
    if (activeDepth != null) {
      return UiStrings.expeditionLocationActiveProgress(
        activeDepth,
        value.activeDefeated,
        cycleIndex: value.activeCycleIndex,
      );
    }
    return UiStrings.expeditionLocationHistoricalProgress(
      value.historicalMaxDepth,
    );
  }

  String _enemySummary(ExpeditionLocationDetail value) => [
    UiStrings.expeditionLocationEnemyPool(
      false,
      value.normalEnemyTeams
          .expand((team) => team.enemies)
          .map(_enemyLabel)
          .toSet()
          .join('、'),
    ),
    UiStrings.expeditionLocationEnemyPool(
      true,
      value.eliteEnemyTeams
          .expand((team) => team.enemies)
          .map(_enemyLabel)
          .toSet()
          .join('、'),
    ),
  ].join('\n');

  String _enemyLabel(ExpeditionLocationEnemySummary enemy) =>
      UiStrings.expeditionLocationEnemy(
        enemy.name,
        EnumL10n.realmTier(enemy.realmTier),
        EnumL10n.school(enemy.school),
      );
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
              color: WuxiaUi.muted,
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
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
