import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../loot_preview/domain/drop_name_resolver.dart';
import '../../mass_battle/presentation/mass_battle_screen.dart';
import '../../seclusion/presentation/seclusion_gate.dart';
import '../application/mass_battle_location_detail_provider.dart';
import '../domain/mass_battle_location_detail.dart';

class MassBattleLocationDetailScreen extends ConsumerWidget {
  const MassBattleLocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(massBattleLocationDetailProvider);
    return Scaffold(
      key: const ValueKey('mass-battle-location-detail-screen'),
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.massBattleLocationDetailTitle,
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
        key: ValueKey('mass-battle-location-detail-unavailable'),
        child: Text(
          UiStrings.massBattleLocationUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaUi.ink, height: 1.5),
        ),
      ),
    ],
  );
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.detail});

  final MassBattleLocationDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        LightPaperPanel(
          key: const ValueKey('mass-battle-location-detail-intel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                label: UiStrings.massBattleLocationProgressLabel,
                value: detail.isComplete
                    ? UiStrings.massBattleLocationCompleteProgress(
                        detail.clearedRoutes,
                        detail.totalRoutes,
                      )
                    : UiStrings.massBattleLocationProgress(
                        detail.clearedRoutes,
                        detail.totalRoutes,
                        detail.nextStageName!,
                      ),
              ),
              _DetailRow(
                label: UiStrings.massBattleLocationRecommendedRealmLabel,
                value: detail.recommendedRealm == null
                    ? UiStrings.massBattleLocationNoNextStage
                    : EnumL10n.realmTier(detail.recommendedRealm!),
              ),
              _DetailRow(
                label: UiStrings.massBattleLocationBattlePlanLabel,
                value:
                    detail.formation == null ||
                        detail.waveCount == null ||
                        detail.enemyTotal == null
                    ? UiStrings.massBattleLocationNoNextStage
                    : UiStrings.massBattleLocationBattlePlan(
                        detail.waveCount!,
                        detail.enemyTotal!,
                        EnumL10n.formation(detail.formation!),
                      ),
              ),
              _DetailRow(
                label: UiStrings.massBattleLocationEnemyEcologyLabel,
                value: detail.enemies.isEmpty
                    ? UiStrings.massBattleLocationNoNextStage
                    : detail.enemies
                          .map(
                            (enemy) => UiStrings.massBattleLocationEnemy(
                              enemy.name,
                              EnumL10n.school(enemy.school),
                            ),
                          )
                          .join(' · '),
              ),
              _DetailRow(
                label: UiStrings.massBattleLocationCoreRewardLabel,
                value: _rewardSummary(detail),
              ),
              _DetailRow(
                label: UiStrings.massBattleLocationParticipantLabel,
                value: UiStrings.massBattleLocationEligibleParticipants(
                  detail.eligibleParticipantCount,
                ),
              ),
              const _DetailRow(
                label: UiStrings.massBattleLocationEntryModeLabel,
                value: UiStrings.massBattleLocationEntryModeDirect,
              ),
              const _DetailRow(
                label: UiStrings.massBattleLocationOccupancyLabel,
                value: UiStrings.massBattleLocationExpectedOccupancy,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WuxiaInkButton(
          key: const ValueKey('mass-battle-location-detail-enter'),
          label: UiStrings.massBattleLocationEnter,
          hint: detail.isComplete
              ? UiStrings.massBattleLocationEnterReplayHint
              : UiStrings.massBattleLocationEnterHint,
          icon: Icons.groups_2_outlined,
          disabled: !detail.hasEligibleParticipant,
          onTap: detail.hasEligibleParticipant
              ? () => guardBattleEntry(
                  context: context,
                  ref: ref,
                  onAllowed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const MassBattleScreen()),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  String _rewardSummary(MassBattleLocationDetail value) {
    if (value.baseExpReward == null || value.rewardRumor == null) {
      return UiStrings.massBattleLocationNoNextStage;
    }
    final names = value.rewardRumor!
        .topRepresentatives(3)
        .map(
          (entry) => entry.isEquipment
              ? DropNameResolver.equipmentName(entry.defId)
              : DropNameResolver.itemName(entry.defId),
        )
        .toList(growable: false);
    return UiStrings.massBattleLocationCoreReward(value.baseExpReward!, names);
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
