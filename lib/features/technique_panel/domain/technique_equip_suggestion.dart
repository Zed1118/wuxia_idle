import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/technique_def.dart';
import '../../../data/numbers_config.dart';
import '../../battle/domain/derived_stats.dart';

enum TechniqueEquipSuggestionStatus {
  alreadyMain,
  alreadyAssist,
  readyForMain,
  readyForAssist,
  realmLocked,
  assistSlotsFull,
  insufficientInsight,
}

enum TechniqueEquipSuggestionReason {
  sameSchool,
  fillsMainSlot,
  fillsAssistSlot,
  tierFitsRealm,
  highEnlightenment,
  alreadyPracticed,
}

class TechniqueEquipSuggestion {
  const TechniqueEquipSuggestion({
    required this.character,
    required this.status,
    required this.reasons,
    required this.requiredTier,
    required this.currentCap,
    required this.requiredInsight,
    required this.score,
  });

  final Character character;
  final TechniqueEquipSuggestionStatus status;
  final List<TechniqueEquipSuggestionReason> reasons;
  final TechniqueTier requiredTier;
  final TechniqueTier currentCap;
  final int requiredInsight;
  final int score;

  bool get isEquipable =>
      status == TechniqueEquipSuggestionStatus.alreadyMain ||
      status == TechniqueEquipSuggestionStatus.alreadyAssist ||
      status == TechniqueEquipSuggestionStatus.readyForMain ||
      status == TechniqueEquipSuggestionStatus.readyForAssist;
}

class TechniqueEquipSuggestionService {
  const TechniqueEquipSuggestionService._();

  static List<TechniqueEquipSuggestion> buildSuggestions({
    required TechniqueDef technique,
    required List<Character> characters,
    required Map<int, List<Technique>> learnedTechniquesByCharacter,
    required LearningCostConfig learningCost,
    TechniqueTier Function(RealmTier tier) techniqueTierCapOf =
        RealmUtils.techniqueTierCapOf,
    int limit = 4,
  }) {
    final suggestions = <TechniqueEquipSuggestion>[];
    for (final character in characters) {
      suggestions.add(
        _forCharacter(
          technique: technique,
          character: character,
          learnedTechniques:
              learnedTechniquesByCharacter[character.id] ?? const [],
          learningCost: learningCost,
          techniqueTierCapOf: techniqueTierCapOf,
        ),
      );
    }
    suggestions.sort(_compareSuggestions);
    return suggestions.take(limit).toList(growable: false);
  }

  static TechniqueEquipSuggestion _forCharacter({
    required TechniqueDef technique,
    required Character character,
    required List<Technique> learnedTechniques,
    required LearningCostConfig learningCost,
    required TechniqueTier Function(RealmTier tier) techniqueTierCapOf,
  }) {
    final currentCap = techniqueTierCapOf(character.realmTier);
    final reasons = <TechniqueEquipSuggestionReason>[];

    Technique? learnedSameDef;
    for (final learned in learnedTechniques) {
      if (learned.defId == technique.id) {
        learnedSameDef = learned;
        break;
      }
    }

    if (character.school == technique.school) {
      reasons.add(TechniqueEquipSuggestionReason.sameSchool);
    }
    if (technique.tier.index == currentCap.index) {
      reasons.add(TechniqueEquipSuggestionReason.tierFitsRealm);
    }
    if (character.attributes.enlightenment >= 7) {
      reasons.add(TechniqueEquipSuggestionReason.highEnlightenment);
    }
    if (learnedSameDef != null) {
      reasons.add(TechniqueEquipSuggestionReason.alreadyPracticed);
    }

    final baseScore = _score(
      technique: technique,
      character: character,
      currentCap: currentCap,
      learnedSameDef: learnedSameDef,
    );

    if (technique.tier.index > currentCap.index) {
      return TechniqueEquipSuggestion(
        character: character,
        status: TechniqueEquipSuggestionStatus.realmLocked,
        reasons: reasons,
        requiredTier: technique.tier,
        currentCap: currentCap,
        requiredInsight: 0,
        score: baseScore,
      );
    }

    if (learnedSameDef?.role == TechniqueRole.main) {
      return TechniqueEquipSuggestion(
        character: character,
        status: TechniqueEquipSuggestionStatus.alreadyMain,
        reasons: reasons,
        requiredTier: technique.tier,
        currentCap: currentCap,
        requiredInsight: 0,
        score: baseScore + 40,
      );
    }

    if (learnedSameDef?.role == TechniqueRole.assist) {
      return TechniqueEquipSuggestion(
        character: character,
        status: TechniqueEquipSuggestionStatus.alreadyAssist,
        reasons: reasons,
        requiredTier: technique.tier,
        currentCap: currentCap,
        requiredInsight: 0,
        score: baseScore + 34,
      );
    }

    final role = character.mainTechniqueId == null
        ? TechniqueRole.main
        : TechniqueRole.assist;
    if (role == TechniqueRole.assist &&
        character.assistTechniqueIds.length >= 3) {
      return TechniqueEquipSuggestion(
        character: character,
        status: TechniqueEquipSuggestionStatus.assistSlotsFull,
        reasons: reasons,
        requiredTier: technique.tier,
        currentCap: currentCap,
        requiredInsight: 0,
        score: baseScore,
      );
    }

    final requiredInsight = learningCost.costFor(role);
    if (character.insightPoints < requiredInsight) {
      return TechniqueEquipSuggestion(
        character: character,
        status: TechniqueEquipSuggestionStatus.insufficientInsight,
        reasons: reasons,
        requiredTier: technique.tier,
        currentCap: currentCap,
        requiredInsight: requiredInsight,
        score: baseScore,
      );
    }

    reasons.add(
      role == TechniqueRole.main
          ? TechniqueEquipSuggestionReason.fillsMainSlot
          : TechniqueEquipSuggestionReason.fillsAssistSlot,
    );
    return TechniqueEquipSuggestion(
      character: character,
      status: role == TechniqueRole.main
          ? TechniqueEquipSuggestionStatus.readyForMain
          : TechniqueEquipSuggestionStatus.readyForAssist,
      reasons: reasons,
      requiredTier: technique.tier,
      currentCap: currentCap,
      requiredInsight: requiredInsight,
      score: baseScore + (role == TechniqueRole.main ? 28 : 22),
    );
  }

  static int _score({
    required TechniqueDef technique,
    required Character character,
    required TechniqueTier currentCap,
    required Technique? learnedSameDef,
  }) {
    var score = 0;
    if (learnedSameDef != null) score += 20;
    if (character.school == technique.school) score += 18;
    score += character.attributes.enlightenment * 2;
    if (technique.tier.index == currentCap.index) {
      score += 12;
    } else if (technique.tier.index < currentCap.index) {
      score += 4;
    }
    return score;
  }

  static int _compareSuggestions(
    TechniqueEquipSuggestion a,
    TechniqueEquipSuggestion b,
  ) {
    if (a.isEquipable != b.isEquipable) {
      return a.isEquipable ? -1 : 1;
    }
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.character.id.compareTo(b.character.id);
  }
}
