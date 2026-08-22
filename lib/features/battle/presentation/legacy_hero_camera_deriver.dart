import '../../../core/domain/character.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;
import '../../combat_shared/presentation/hero_camera_overlay.dart';
import '../domain/battle_state.dart';
import '../domain/top_damage_contributor.dart';

/// Legacy 3v3 state adapter for the engine-neutral hero camera value object.
HeroCameraData? deriveLegacyHeroCameraData({
  required BattleState finalState,
  required List<Character> characters,
  required String bossName,
}) {
  final top = TopDamageContributor.from(finalState);
  if (top == null) return null;
  Character? hero;
  for (final character in characters) {
    if (character.id == top.actorId) {
      hero = character;
      break;
    }
  }
  if (hero == null) return null;
  return HeroCameraData(
    portraitPath: hero.portraitPath,
    heroName: hero.name,
    realmLabel: EnumL10n.realmTier(hero.realmTier),
    bossName: bossName,
    topDamage: top.totalDamage,
  );
}
