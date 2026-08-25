import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../jianghu/presentation/reputation_panel_screen.dart';
import '../application/reputation_location_detail_provider.dart';
import '../domain/reputation_location_detail.dart';

class ReputationLocationDetailScreen extends ConsumerWidget {
  const ReputationLocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(reputationLocationDetailProvider);
    return Scaffold(
      key: const ValueKey('reputation-location-detail-screen'),
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.reputationLocationDetailTitle,
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
        key: ValueKey('reputation-location-detail-unavailable'),
        child: Text(
          UiStrings.reputationLocationUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaUi.ink, height: 1.5),
        ),
      ),
    ],
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final ReputationLocationDetail detail;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    children: [
      LightPaperPanel(
        key: const ValueKey('reputation-location-detail-intel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(
              label: UiStrings.reputationLocationOverviewLabel,
              value: UiStrings.reputationLocationOverview(
                detail.trackedFactionCount,
                detail.factions.length,
              ),
            ),
            _DetailRow(
              label: UiStrings.reputationLocationFactionLabel,
              value: detail.factions.map(_factionSummary).join('\n'),
            ),
            _DetailRow(
              label: UiStrings.reputationLocationTierLabel,
              value: detail.tiers.map(_tierSummary).join('；'),
            ),
            _DetailRow(
              label: UiStrings.reputationLocationSourceLabel,
              value: UiStrings.reputationLocationSources(
                detail.stageBossKillDelta,
                detail.stageBossKillRivalDelta,
                detail.encounterNpcDeltaMin,
                detail.encounterNpcDeltaMax,
              ),
            ),
            const _DetailRow(
              label: UiStrings.reputationLocationEnmityLabel,
              value: UiStrings.reputationLocationEnmityBoundary,
              isLast: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      WuxiaInkButton(
        key: const ValueKey('reputation-location-detail-enter'),
        label: UiStrings.reputationLocationEnter,
        hint: UiStrings.reputationLocationEnterHint,
        icon: Icons.handshake_outlined,
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const ReputationPanelScreen()),
        ),
      ),
    ],
  );

  String _factionSummary(ReputationLocationFactionSummary faction) {
    final relation = faction.value == null
        ? UiStrings.reputationLocationUnrecorded
        : UiStrings.reputationLocationRecorded(
            faction.tierLabel!,
            faction.value!,
          );
    return UiStrings.reputationLocationFaction(
      faction.name,
      UiStrings.reputationLocationAlignment(faction.alignment),
      relation,
    );
  }

  String _tierSummary(ReputationLocationTierSummary tier) =>
      UiStrings.reputationLocationTierRange(tier.label, tier.min, tier.max);
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
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
