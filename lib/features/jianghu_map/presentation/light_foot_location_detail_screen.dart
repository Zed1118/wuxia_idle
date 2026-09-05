import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../light_foot/presentation/light_foot_screen.dart';
import '../../loot_preview/domain/drop_name_resolver.dart';
import '../application/light_foot_location_detail_provider.dart';
import '../domain/light_foot_location_detail.dart';

class LightFootLocationDetailScreen extends ConsumerWidget {
  const LightFootLocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(lightFootLocationDetailProvider);
    return Scaffold(
      key: const ValueKey('light-foot-location-detail-screen'),
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.lightFootLocationDetailTitle,
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
        key: ValueKey('light-foot-location-detail-unavailable'),
        child: Text(
          UiStrings.lightFootLocationUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaUi.ink, height: 1.5),
        ),
      ),
    ],
  );
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.detail});

  final LightFootLocationDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        LightPaperPanel(
          key: const ValueKey('light-foot-location-detail-intel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                label: UiStrings.lightFootLocationProgressLabel,
                value: detail.isComplete
                    ? UiStrings.lightFootLocationCompleteProgress(
                        detail.clearedRoutes,
                        detail.totalRoutes,
                      )
                    : UiStrings.lightFootLocationProgress(
                        detail.clearedRoutes,
                        detail.totalRoutes,
                        detail.nextStageName!,
                      ),
              ),
              _DetailRow(
                label: UiStrings.lightFootLocationRecommendedRealmLabel,
                value: detail.recommendedRealm == null
                    ? UiStrings.lightFootLocationNoNextRoute
                    : EnumL10n.realmTier(detail.recommendedRealm!),
              ),
              _DetailRow(
                label: UiStrings.lightFootLocationTerrainLabel,
                value: detail.terrainBiome == null
                    ? UiStrings.lightFootLocationNoNextRoute
                    : EnumL10n.terrainBiome(detail.terrainBiome),
              ),
              _DetailRow(
                label: UiStrings.lightFootLocationEnemyEcologyLabel,
                value: detail.enemies.isEmpty
                    ? UiStrings.lightFootLocationNoNextRoute
                    : detail.enemies
                          .map(
                            (enemy) => UiStrings.lightFootLocationEnemy(
                              enemy.name,
                              EnumL10n.school(enemy.school),
                            ),
                          )
                          .join(' · '),
              ),
              _DetailRow(
                label: UiStrings.lightFootLocationCoreRewardLabel,
                value: _rewardSummary(detail),
              ),
              _DetailRow(
                label: UiStrings.lightFootLocationParticipantLabel,
                value: UiStrings.lightFootLocationEligibleParticipants(
                  detail.eligibleParticipantCount,
                ),
              ),
              _DetailRow(
                label: UiStrings.lightFootLocationEntryModeLabel,
                value: [
                  UiStrings.lightFootParticipantAvailable,
                  UiStrings.expeditionDispatchTeamSection,
                ].join(UiStrings.offlineRecapDetailSeparator),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WuxiaInkButton(
          key: const ValueKey('light-foot-location-detail-enter'),
          label: UiStrings.lightFootLocationEnter,
          hint: detail.isComplete
              ? UiStrings.lightFootLocationEnterReplayHint
              : UiStrings.lightFootLocationEnterHint,
          icon: Icons.directions_run,
          disabled: !detail.hasEligibleParticipant,
          onTap: detail.hasEligibleParticipant
              ? () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const LightFootScreen()),
                )
              : null,
        ),
      ],
    );
  }

  String _rewardSummary(LightFootLocationDetail value) {
    if (value.baseExpReward == null || value.rewardRumor == null) {
      return UiStrings.lightFootLocationNoNextRoute;
    }
    final names = value.rewardRumor!
        .topRepresentatives(3)
        .map(
          (entry) => entry.isEquipment
              ? DropNameResolver.equipmentName(entry.defId)
              : DropNameResolver.itemName(entry.defId),
        )
        .toList(growable: false);
    return UiStrings.lightFootLocationCoreReward(value.baseExpReward!, names);
  }
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
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
