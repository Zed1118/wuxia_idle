import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/character.dart';
import '../../../data/game_repository.dart';
import '../../main_menu/application/main_menu_status_summary_provider.dart';
import '../../mainline/application/mainline_providers.dart';
import '../domain/progressive_unlock.dart';
import 'progressive_unlock_projection.dart';

class CurrentProgressiveUnlockObservation {
  const CurrentProgressiveUnlockObservation({
    required this.saveDataId,
    required this.snapshot,
  });

  final int saveDataId;
  final ProgressiveUnlockSnapshot snapshot;

  String get signature =>
      '$saveDataId:${ProgressiveUnlockId.values.map((unlockId) => snapshot[unlockId].name).join(',')}';
}

/// Keeps U11 attached to the same provider invalidations already emitted by
/// mainline settlement, journey unlock, roster changes, and character growth.
final currentProgressiveUnlockObservationProvider =
    FutureProvider.autoDispose<CurrentProgressiveUnlockObservation?>((
      ref,
    ) async {
      if (!GameRepository.isLoaded) return null;
      final save = await ref.watch(mainMenuSaveSnapshotProvider.future);
      if (save == null) return null;
      final progress = await ref.watch(mainlineProgressProvider.future);
      final activeCharacters = <Character>[];
      for (final characterId in save.activeCharacterIds) {
        final character = await ref.watch(
          characterByIdProvider(characterId).future,
        );
        if (character == null) {
          throw StateError(
            'Progressive unlock references missing active character: '
            '$characterId',
          );
        }
        activeCharacters.add(character);
      }
      final repository = GameRepository.instance;
      return CurrentProgressiveUnlockObservation(
        saveDataId: save.slotId,
        snapshot: projectCurrentProgressiveUnlocks(
          save: save,
          mainlineProgress: progress,
          activeCharacters: activeCharacters,
          lightFoot: repository.numbers.lightFoot,
          massBattle: repository.numbers.massBattle,
          innerDemon: repository.numbers.innerDemon,
        ),
      );
    });
