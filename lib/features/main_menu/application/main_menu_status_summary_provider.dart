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
  final int? targetCharacterId;
  final RealmTier? targetRealmTier;

  const MainMenuStatusSummaryItem({
    required this.kind,
    required this.route,
    required this.title,
    required this.detail,
    this.targetCharacterId,
    this.targetRealmTier,
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

      final characters = await _activeCharacters(ref);

      final retreat = await ref.watch(activeRetreatSessionProvider.future);
      final retreatItem = _retreatItem(retreat, characters);
      if (retreatItem != null) items.add(retreatItem);

      final save = await ref.watch(mainMenuSaveSnapshotProvider.future);
      final islandItem = _islandItem(save);
      if (islandItem != null) items.add(islandItem);

      final injuryItem = _injuryItem(characters);
      if (injuryItem != null) items.add(injuryItem);

      final repository = GameRepository.instance;
      final breakthroughItem = _breakthroughItem(
        characters,
        (character) => repository
            .getRealm(character.realmTier, character.realmLayer)
            .experienceToNext,
      );
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

MainMenuStatusSummaryItem? _retreatItem(
  RetreatSession? session,
  List<Character> characters,
) {
  if (session == null || session.id <= 0) return null;
  final participants = characters
      .where((character) => character.currentRetreatSessionId == session.id)
      .toList(growable: false);
  if (participants.length != 1) return null;
  final participant = participants.single;
  final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
  final elapsed =
      DateTime.now().difference(session.startedAt).inSeconds / 3600.0;
  final detail = UiStrings.mainMenuStatusRetreatDetail(
    mapDef.mapName,
    (elapsed < 0 ? 0.0 : elapsed).toStringAsFixed(1),
  );
  return MainMenuStatusSummaryItem(
    kind: MainMenuStatusKind.retreat,
    route: MainMenuStatusRoute.retreat,
    title: UiStrings.mainMenuStatusRetreatTitle,
    detail: detail,
    targetCharacterId: participant.id,
    targetRealmTier: participant.realmTier,
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
  Character? firstInjured;
  for (final character in characters) {
    final hours = character.injuryHoursRemaining;
    final injured =
        hours > 0 ||
        character.lightInjuryStacks > 0 ||
        character.innerBreathDisorderHoursRemaining > 0;
    if (!injured) continue;
    firstInjured ??= character;
    count += 1;
    if (hours > maxHours) maxHours = hours;
  }
  if (count <= 0 || firstInjured == null) return null;
  return MainMenuStatusSummaryItem(
    kind: MainMenuStatusKind.injury,
    route: MainMenuStatusRoute.character,
    title: UiStrings.mainMenuStatusInjuryTitle,
    detail: UiStrings.mainMenuStatusInjuryDetail(count, maxHours),
    targetCharacterId: firstInjured.id,
  );
}

MainMenuStatusSummaryItem? _breakthroughItem(
  List<Character> characters,
  int Function(Character character) thresholdFor,
) {
  for (final character in characters) {
    final threshold = thresholdFor(character);
    if (threshold <= 0 || character.experience < threshold) continue;
    return MainMenuStatusSummaryItem(
      kind: MainMenuStatusKind.breakthrough,
      route: MainMenuStatusRoute.character,
      title: UiStrings.mainMenuStatusBreakthroughTitle,
      detail: UiStrings.mainMenuStatusBreakthroughDetail(character.name),
      targetCharacterId: character.id,
    );
  }
  return null;
}

MainMenuStatusSummaryItem? _mainlineItem(MainlineProgress progress) {
  for (var chapterIndex = 1; chapterIndex <= 21; chapterIndex++) {
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
