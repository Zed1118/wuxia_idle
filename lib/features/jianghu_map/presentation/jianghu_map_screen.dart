import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../seclusion/presentation/seclusion_gate.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/application/tower_providers.dart';
import '../../tower/domain/tower_progress.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';

String jianghuMapTowerStatus(TowerProgress progress) {
  final highest = progress.highestClearedFloor;
  if (!GameRepository.isLoaded) {
    return UiStrings.mainMenuTowerStatus(highest, highest + 1);
  }
  final maxFloor = GameRepository.instance.towerMaxFloor;
  if (highest >= maxFloor) return UiStrings.mainMenuTowerCompleteStatus;
  final next = TowerProgressService.availableFloor(
    progress,
    maxFloor: maxFloor,
  );
  final nextIsBoss = GameRepository.instance.towerFloors.any(
    (floor) => floor.floorIndex == next && floor.isBoss,
  );
  return nextIsBoss
      ? UiStrings.mainMenuTowerBossStatus(highest, next)
      : UiStrings.mainMenuTowerStatus(highest, next);
}

class JianghuMapScreen extends ConsumerWidget {
  const JianghuMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final towerStatus = ref
        .watch(towerProgressProvider)
        .maybeWhen(data: jianghuMapTowerStatus, orElse: () => null);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.jianghuMapTitle,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                const Text(
                  UiStrings.jianghuMapSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                const _MapSectionLabel(),
                const SizedBox(height: 12),
                WuxiaInkButton(
                  key: const ValueKey('jianghu-map-tower-location'),
                  label: UiStrings.mainMenuTower,
                  hint: UiStrings.mainMenuTowerHint,
                  status: towerStatus,
                  icon: Icons.filter_hdr_outlined,
                  thumbnailPath: WuxiaUi.entryTower,
                  onTap: () => guardBattleEntry(
                    context: context,
                    ref: ref,
                    onAllowed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const TowerFloorListScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapSectionLabel extends StatelessWidget {
  const _MapSectionLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: WuxiaUi.paper.withValues(alpha: 0.24)),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiStrings.jianghuMapKnownLocations,
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              UiStrings.jianghuMapKnownLocationsHint,
              style: TextStyle(color: WuxiaUi.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
