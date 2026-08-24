import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../light_foot/application/light_foot_service.dart';
import '../../light_foot/presentation/light_foot_screen.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mass_battle/application/mass_battle_service.dart';
import '../../mass_battle/presentation/mass_battle_screen.dart';
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

({bool locked, String status}) jianghuMapLightFootLocationState(
  MainlineProgress progress,
) {
  final config = GameRepository.instance.numbers.lightFoot;
  final stageIds = LightFootService.orderedStageIds(config);
  if (stageIds.isEmpty) {
    return (locked: true, status: UiStrings.lightFootEmpty);
  }
  final cleared = progress.clearedStageIds.toSet();
  final firstStagePrerequisites = config.unlockTriggers.entries
      .where((entry) => entry.value == stageIds.first)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (firstStagePrerequisites.length != 1) {
    return (locked: true, status: UiStrings.lightFootEmpty);
  }
  final firstStatus = LightFootService.statusOf(
    stageId: stageIds.first,
    config: config,
    clearedStageIds: cleared,
  );
  final locked =
      !cleared.contains(firstStagePrerequisites.single) ||
      firstStatus == LightFootStageStatus.locked;
  final clearedCount = stageIds.where(cleared.contains).length;
  return (
    locked: locked,
    status: locked
        ? UiStrings.mainMenuLateGameLockedHint
        : UiStrings.jianghuMapLightFootProgress(clearedCount, stageIds.length),
  );
}

({bool locked, String status}) jianghuMapMassBattleLocationState(
  MainlineProgress progress,
) {
  final config = GameRepository.instance.numbers.massBattle;
  final stageIds = MassBattleService.orderedStageIds(config);
  if (stageIds.isEmpty) {
    return (locked: true, status: UiStrings.massBattleEmpty);
  }
  final cleared = progress.clearedStageIds.toSet();
  final firstStagePrerequisites = config.unlockTriggers.entries
      .where((entry) => entry.value == stageIds.first)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (firstStagePrerequisites.length != 1) {
    return (locked: true, status: UiStrings.massBattleEmpty);
  }
  final firstStatus = MassBattleService.statusOf(
    stageId: stageIds.first,
    config: config,
    clearedStageIds: cleared,
  );
  final locked =
      !cleared.contains(firstStagePrerequisites.single) ||
      firstStatus == MassBattleStageStatus.locked;
  final clearedCount = stageIds.where(cleared.contains).length;
  return (
    locked: locked,
    status: locked
        ? UiStrings.mainMenuLateGameLockedHint
        : UiStrings.jianghuMapMassBattleProgress(clearedCount, stageIds.length),
  );
}

class JianghuMapScreen extends ConsumerWidget {
  const JianghuMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final towerStatus = ref
        .watch(towerProgressProvider)
        .maybeWhen(data: jianghuMapTowerStatus, orElse: () => null);
    final lightFootState = ref
        .watch(mainlineProgressProvider)
        .maybeWhen(data: jianghuMapLightFootLocationState, orElse: () => null);
    final massBattleState = ref
        .watch(mainlineProgressProvider)
        .maybeWhen(data: jianghuMapMassBattleLocationState, orElse: () => null);

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
                const SizedBox(height: 12),
                WuxiaInkButton(
                  key: const ValueKey('jianghu-map-light-foot-location'),
                  label: UiStrings.mainMenuLightFoot,
                  hint: UiStrings.mainMenuLightFootHint,
                  status: lightFootState?.status,
                  icon: Icons.directions_run,
                  thumbnailPath: WuxiaUi.entryLightFoot,
                  disabled: lightFootState == null || lightFootState.locked,
                  locked: lightFootState == null || lightFootState.locked,
                  onTap: () => guardBattleEntry(
                    context: context,
                    ref: ref,
                    onAllowed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const LightFootScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                WuxiaInkButton(
                  key: const ValueKey('jianghu-map-mass-battle-location'),
                  label: UiStrings.mainMenuMassBattle,
                  hint: UiStrings.mainMenuMassBattleHint,
                  status: massBattleState?.status,
                  icon: Icons.groups_2_outlined,
                  thumbnailPath: WuxiaUi.entryJianghu,
                  disabled: massBattleState == null || massBattleState.locked,
                  locked: massBattleState == null || massBattleState.locked,
                  onTap: () => guardBattleEntry(
                    context: context,
                    ref: ref,
                    onAllowed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const MassBattleScreen(),
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
