import '../../core/domain/save_data.dart';

typedef CurrentLeaderCharacterExists = Future<bool> Function(int characterId);

/// Resolves the sole current-leader pointer for battle entry points.
final class CurrentLeaderResolver {
  const CurrentLeaderResolver._();

  static Future<int> resolve({
    required SaveData? save,
    required CurrentLeaderCharacterExists characterExists,
  }) async {
    final characterId = save?.founderCharacterId;
    if (characterId == null) {
      throw StateError(
        'Current leader pointer missing: SaveData.founderCharacterId',
      );
    }
    if (!await characterExists(characterId)) {
      throw StateError(
        'Current leader pointer invalid: '
        'SaveData.founderCharacterId=$characterId has no Character',
      );
    }
    return characterId;
  }
}
