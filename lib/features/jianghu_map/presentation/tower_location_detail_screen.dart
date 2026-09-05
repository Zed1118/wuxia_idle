import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../loot_preview/domain/drop_name_resolver.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';
import '../application/tower_location_detail_provider.dart';
import '../domain/tower_location_detail.dart';

class TowerLocationDetailScreen extends ConsumerWidget {
  const TowerLocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(towerLocationDetailProvider);
    return Scaffold(
      key: const ValueKey('tower-location-detail-screen'),
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.towerLocationDetailTitle,
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
        key: ValueKey('tower-location-detail-unavailable'),
        child: Text(
          UiStrings.towerLocationUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaUi.ink, height: 1.5),
        ),
      ),
    ],
  );
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.detail});

  final TowerLocationDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        LightPaperPanel(
          key: const ValueKey('tower-location-detail-intel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                label: UiStrings.towerLocationProgressLabel,
                value: detail.isComplete
                    ? UiStrings.towerLocationCompleteProgress(
                        detail.highestClearedFloor,
                        detail.totalFloors,
                      )
                    : UiStrings.towerLocationProgress(
                        detail.highestClearedFloor,
                        detail.totalFloors,
                        detail.nextFloorIndex!,
                      ),
              ),
              _DetailRow(
                label: UiStrings.towerLocationRecommendedRealmLabel,
                value: detail.recommendedRealm == null
                    ? UiStrings.towerLocationNoNextFloor
                    : EnumL10n.realmTier(detail.recommendedRealm!),
              ),
              _DetailRow(
                label: UiStrings.towerLocationEnemyEcologyLabel,
                value: detail.enemies.isEmpty
                    ? UiStrings.towerLocationNoNextFloor
                    : detail.enemies
                          .map(
                            (enemy) => UiStrings.towerLocationEnemy(
                              enemy.name,
                              EnumL10n.school(enemy.school),
                            ),
                          )
                          .join(' · '),
              ),
              _DetailRow(
                label: UiStrings.towerLocationCoreRewardLabel,
                value: _rewardSummary(detail),
              ),
              _DetailRow(
                label: UiStrings.towerLocationParticipantLabel,
                value: UiStrings.towerLocationEligibleParticipants(
                  detail.eligibleParticipantCount,
                ),
              ),
              const _DetailRow(
                label: UiStrings.towerLocationEntryModeLabel,
                value: UiStrings.towerLocationEntryModeDirect,
              ),
              const _DetailRow(
                label: UiStrings.towerLocationOccupancyLabel,
                value: UiStrings.towerLocationExpectedOccupancy,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WuxiaInkButton(
          key: const ValueKey('tower-location-detail-enter'),
          label: UiStrings.towerLocationEnter,
          hint: detail.isComplete
              ? UiStrings.towerLocationEnterReplayHint
              : UiStrings.towerLocationEnterHint,
          icon: Icons.filter_hdr_outlined,
          disabled: detail.eligibleParticipantCount == 0,
          onTap: detail.eligibleParticipantCount == 0
              ? null
              : () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const TowerFloorListScreen(),
                  ),
                ),
        ),
      ],
    );
  }

  String _rewardSummary(TowerLocationDetail value) {
    if (value.baseExpReward == null || value.rewardRumor == null) {
      return UiStrings.towerLocationNoNextFloor;
    }
    final names = value.rewardRumor!
        .topRepresentatives(3)
        .map(
          (entry) => entry.isEquipment
              ? DropNameResolver.equipmentName(entry.defId)
              : DropNameResolver.itemName(entry.defId),
        )
        .toList(growable: false);
    return UiStrings.towerLocationCoreReward(value.baseExpReward!, names);
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
