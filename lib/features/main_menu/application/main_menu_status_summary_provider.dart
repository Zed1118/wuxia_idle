import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/presentation/seclusion_gate.dart';

enum MainMenuStatusKind { retreat, island, injury, breakthrough, mainline }

enum MainMenuStatusRoute { retreat, island, character, mainline }

class MainMenuStatusSummaryItem {
  final MainMenuStatusKind kind;
  final MainMenuStatusRoute route;
  final String title;
  final String detail;

  const MainMenuStatusSummaryItem({
    required this.kind,
    required this.route,
    required this.title,
    required this.detail,
  });
}

final mainMenuSaveSnapshotProvider = FutureProvider.autoDispose<SaveData?>((
  ref,
) async {
  if (IsarSetup.instanceOrNull == null) return null;
  return IsarSetup.currentSaveData();
});

final mainMenuStatusSummaryProvider =
    FutureProvider.autoDispose<List<MainMenuStatusSummaryItem>>((ref) async {
      final items = <MainMenuStatusSummaryItem>[];
      if (!GameRepository.isLoaded) return items;

      final retreat = await ref.watch(activeRetreatSessionProvider.future);
      final retreatItem = _retreatItem(retreat);
      if (retreatItem != null) items.add(retreatItem);

      final save = await ref.watch(mainMenuSaveSnapshotProvider.future);
      final islandItem = _islandItem(save);
      if (islandItem != null) items.add(islandItem);

      final characters = await _activeCharacters(ref);
      final injuryItem = _injuryItem(characters);
      if (injuryItem != null) items.add(injuryItem);

      final breakthroughItem = _breakthroughItem(characters);
      if (breakthroughItem != null) items.add(breakthroughItem);

      final progress = await ref.watch(mainlineProgressProvider.future);
      final mainlineItem = _mainlineItem(progress);
      if (mainlineItem != null) items.add(mainlineItem);

      return List.unmodifiable(items.take(5));
    });

Future<List<Character>> _activeCharacters(Ref ref) async {
  final ids = await ref.watch(activeCharacterIdsProvider.future);
  final characters = <Character>[];
  for (final id in ids) {
    final character = await ref.watch(characterByIdProvider(id).future);
    if (character != null) characters.add(character);
  }
  return characters;
}

MainMenuStatusSummaryItem? _retreatItem(RetreatSession? session) {
  if (session == null) return null;
  final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
  final plannedMin = session.durationHours * 60;
  final capMin = (GameRepository.instance.numbers.retreat.capHours * 60)
      .round();
  final elapsedMin = DateTime.now().difference(session.startedAt).inMinutes;
  final remainingMin = (plannedMin - elapsedMin).clamp(0, plannedMin);
  final isCapped = capMin <= plannedMin && elapsedMin >= capMin;
  final detail = isCapped
      ? UiStrings.mainMenuStatusRetreatCappedDetail(mapDef.mapName)
      : UiStrings.mainMenuStatusRetreatDetail(
          mapDef.mapName,
          UiStrings.retreatRemainingText(remainingMin ~/ 60, remainingMin % 60),
        );
  return MainMenuStatusSummaryItem(
    kind: MainMenuStatusKind.retreat,
    route: MainMenuStatusRoute.retreat,
    title: UiStrings.mainMenuStatusRetreatTitle,
    detail: detail,
  );
}

MainMenuStatusSummaryItem? _islandItem(SaveData? save) {
  if (save == null) return null;
  final claimable = save.islandBuildings.fold<int>(
    0,
    (sum, building) => sum + building.stored.floor(),
  );
  if (claimable <= 0) return null;
  return MainMenuStatusSummaryItem(
    kind: MainMenuStatusKind.island,
    route: MainMenuStatusRoute.island,
    title: UiStrings.mainMenuStatusIslandTitle,
    detail: UiStrings.mainMenuStatusIslandDetail(claimable),
  );
}

MainMenuStatusSummaryItem? _injuryItem(List<Character> characters) {
  var count = 0;
  double maxHours = 0;
  for (final character in characters) {
    final hours = character.injuryHoursRemaining;
    final injured =
        hours > 0 ||
        character.lightInjuryStacks > 0 ||
        character.innerDemonResidueHoursRemaining > 0;
    if (!injured) continue;
    count += 1;
    if (hours > maxHours) maxHours = hours;
  }
  if (count <= 0) return null;
  return MainMenuStatusSummaryItem(
    kind: MainMenuStatusKind.injury,
    route: MainMenuStatusRoute.character,
    title: UiStrings.mainMenuStatusInjuryTitle,
    detail: UiStrings.mainMenuStatusInjuryDetail(count, maxHours),
  );
}

MainMenuStatusSummaryItem? _breakthroughItem(List<Character> characters) {
  for (final character in characters) {
    if (character.experienceToNextLayer <= 0) continue;
    if (character.experience < character.experienceToNextLayer) continue;
    return MainMenuStatusSummaryItem(
      kind: MainMenuStatusKind.breakthrough,
      route: MainMenuStatusRoute.character,
      title: UiStrings.mainMenuStatusBreakthroughTitle,
      detail: UiStrings.mainMenuStatusBreakthroughDetail(character.name),
    );
  }
  return null;
}

MainMenuStatusSummaryItem? _mainlineItem(MainlineProgress progress) {
  for (var chapterIndex = 1; chapterIndex <= 6; chapterIndex++) {
    final stages = MainlineProgressService.availableStages(
      progress: progress,
      chapterIndex: chapterIndex,
    );
    for (final entry in stages) {
      if (entry.status != StageStatus.available) continue;
      return MainMenuStatusSummaryItem(
        kind: MainMenuStatusKind.mainline,
        route: MainMenuStatusRoute.mainline,
        title: UiStrings.mainMenuStatusMainlineTitle,
        detail: UiStrings.mainMenuStatusMainlineDetail(
          chapterIndex,
          entry.def.name,
        ),
      );
    }
  }
  return const MainMenuStatusSummaryItem(
    kind: MainMenuStatusKind.mainline,
    route: MainMenuStatusRoute.mainline,
    title: UiStrings.mainMenuStatusMainlineTitle,
    detail: UiStrings.mainMenuStatusMainlineCompleteDetail,
  );
}
