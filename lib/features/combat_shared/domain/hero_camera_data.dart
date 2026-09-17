import '../../../core/domain/character.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;

/// 引擎中立英雄镜头数据值对象。
/// 由 caller 从 TopDamageContributor 组装，纯数据无副作用。
class HeroCameraData {
  final String? portraitPath;
  final String heroName;
  final String realmLabel;
  final String bossName;
  final int topDamage;

  const HeroCameraData({
    required this.portraitPath,
    required this.heroName,
    required this.realmLabel,
    required this.bossName,
    required this.topDamage,
  });
}

/// 从引擎中立的结算快照推导英雄镜头数据。
HeroCameraData? deriveHeroCameraDataFromDamageTotals({
  required Map<int, int> damageByCharacterId,
  required List<Character> characters,
  required String bossName,
}) {
  Character? hero;
  var topDamage = -1;
  for (final character in characters) {
    final damage = damageByCharacterId[character.id];
    if (damage == null) continue;
    if (hero == null || damage > topDamage) {
      hero = character;
      topDamage = damage;
    }
  }
  if (hero == null) return null;
  return HeroCameraData(
    portraitPath: hero.portraitPath,
    heroName: hero.name,
    realmLabel: EnumL10n.realmTier(hero.realmTier),
    bossName: bossName,
    topDamage: topDamage,
  );
}
