import '../application/character_advancement_service.dart';

class AdvancementEntry {
  final int characterId;
  final String chName;
  final AdvancementResult result;

  const AdvancementEntry({
    required this.characterId,
    required this.chName,
    required this.result,
  });
}
