import 'dart:collection';

import 'skill_def.dart';

final class CombatRuntimeArenaBounds {
  const CombatRuntimeArenaBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  bool contains(double x, double y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;
}

/// Typed policies declared by the production runtime binding.
enum CombatRuntimeTargetPolicy { nearestPlayer }

enum CombatRuntimeMovementPolicy {
  directAdvance,
  holdDistance,
  lateralFlank,
  guardedPosition,
}

enum CombatRuntimeAttackPolicy {
  closeRange,
  rangedPressure,
  chargeAndReposition,
  supportPulse,
}

enum CombatRuntimeTokenPolicy { melee, ranged, charge, support }

final class CombatRuntimePoint {
  const CombatRuntimePoint({required this.x, required this.y});

  final double x;
  final double y;
}

final class CombatRuntimeAiProfile {
  const CombatRuntimeAiProfile({
    required this.id,
    required this.targetPolicy,
    required this.movementPolicy,
    required this.attackPolicy,
  });

  final String id;
  final CombatRuntimeTargetPolicy targetPolicy;
  final CombatRuntimeMovementPolicy movementPolicy;
  final CombatRuntimeAttackPolicy attackPolicy;
}

final class CombatRuntimeBehaviorBinding {
  const CombatRuntimeBehaviorBinding({
    required this.id,
    required this.aiProfile,
    required this.tokenPolicy,
    required this.priority,
    required this.isOffscreen,
    required this.isHighImpact,
    required this.isUnblockableArea,
    required this.spawnGraceTicksRemaining,
    required this.telegraphReady,
  });

  final String id;
  final CombatRuntimeAiProfile aiProfile;
  final CombatRuntimeTokenPolicy tokenPolicy;
  final int priority;
  final bool isOffscreen;
  final bool isHighImpact;
  final bool isUnblockableArea;
  final int spawnGraceTicksRemaining;
  final bool telegraphReady;
}

final class CombatRuntimeAttackSet {
  CombatRuntimeAttackSet({required this.id, required Iterable<SkillDef> skills})
    : skills = List<SkillDef>.unmodifiable(skills);

  final String id;
  final List<SkillDef> skills;

  List<String> get skillIds =>
      List<String>.unmodifiable(skills.map((skill) => skill.id));
}

final class CombatRuntimeVisualVariant {
  const CombatRuntimeVisualVariant({required this.id, required this.assetPath});

  final String id;
  final String assetPath;
}

/// Verified-only namespaces are intentionally not runtime behavior.
final class CombatRuntimeVerifiedOnlyReferences {
  CombatRuntimeVerifiedOnlyReferences({
    required Iterable<String> postureProfileIds,
    required Iterable<String> dropGroupIds,
    required Iterable<String> sfxGroupIds,
  }) : postureProfileIds = UnmodifiableSetView(
         Set<String>.unmodifiable(postureProfileIds),
       ),
       dropGroupIds = UnmodifiableSetView(
         Set<String>.unmodifiable(dropGroupIds),
       ),
       sfxGroupIds = UnmodifiableSetView(Set<String>.unmodifiable(sfxGroupIds));

  final UnmodifiableSetView<String> postureProfileIds;
  final UnmodifiableSetView<String> dropGroupIds;
  final UnmodifiableSetView<String> sfxGroupIds;

  /// Always `none` for this schema. Kept explicit so consumers cannot infer
  /// that these verified references are already host-wired.
  String get hostConsumption => 'none';
}

/// The resolved binding for one catalog spawn entry.
final class CombatRuntimeEnemyBinding {
  const CombatRuntimeEnemyBinding({
    required this.entryId,
    required this.baseEnemyId,
    required this.archetypeId,
    required this.roleId,
    required this.entranceId,
    required this.entrance,
    required this.positionId,
    required this.position,
    required this.behavior,
    required this.attackSet,
    required this.visualVariant,
  });

  final String entryId;
  final String baseEnemyId;
  final String archetypeId;
  final String roleId;
  final String entranceId;
  final CombatRuntimePoint entrance;
  final String positionId;
  final CombatRuntimePoint position;
  final CombatRuntimeBehaviorBinding behavior;
  final CombatRuntimeAttackSet attackSet;
  final CombatRuntimeVisualVariant visualVariant;
}

final class CombatRuntimeStageBinding {
  CombatRuntimeStageBinding({
    required this.stageId,
    required this.encounterId,
    required this.baseEnemyId,
    required Map<String, CombatRuntimePoint> entrances,
    required Map<String, CombatRuntimePoint> positions,
    required Map<String, CombatRuntimeBehaviorBinding> behaviors,
    required Map<String, CombatRuntimeAiProfile> aiProfiles,
    required Map<String, CombatRuntimeAttackSet> attackSets,
    required Map<String, CombatRuntimeVisualVariant> visualVariants,
    required Iterable<CombatRuntimeEnemyBinding> enemyBindings,
    required this.verifiedOnlyReferences,
  }) : entrances = _unmodifiableMap(entrances),
       positions = _unmodifiableMap(positions),
       behaviors = _unmodifiableMap(behaviors),
       aiProfiles = _unmodifiableMap(aiProfiles),
       attackSets = _unmodifiableMap(attackSets),
       visualVariants = _unmodifiableMap(visualVariants),
       enemyBindings = List<CombatRuntimeEnemyBinding>.unmodifiable(
         enemyBindings,
       );

  final String stageId;
  final String encounterId;
  final String baseEnemyId;
  final UnmodifiableMapView<String, CombatRuntimePoint> entrances;
  final UnmodifiableMapView<String, CombatRuntimePoint> positions;
  final UnmodifiableMapView<String, CombatRuntimeBehaviorBinding> behaviors;
  final UnmodifiableMapView<String, CombatRuntimeAiProfile> aiProfiles;
  final UnmodifiableMapView<String, CombatRuntimeAttackSet> attackSets;
  final UnmodifiableMapView<String, CombatRuntimeVisualVariant> visualVariants;
  final List<CombatRuntimeEnemyBinding> enemyBindings;
  final CombatRuntimeVerifiedOnlyReferences verifiedOnlyReferences;

  CombatRuntimeEnemyBinding? bindingForEntry(String entryId) {
    for (final binding in enemyBindings) {
      if (binding.entryId == entryId) return binding;
    }
    return null;
  }
}

final class CombatRuntimeBindingCatalog {
  CombatRuntimeBindingCatalog(Iterable<CombatRuntimeStageBinding> bindings)
    : stageBindings = List<CombatRuntimeStageBinding>.unmodifiable(bindings) {
    final ids = <String>{};
    for (final binding in stageBindings) {
      if (!ids.add(binding.stageId)) {
        throw ArgumentError.value(
          binding.stageId,
          'stageBindings',
          'duplicate stage id',
        );
      }
    }
  }

  final List<CombatRuntimeStageBinding> stageBindings;

  CombatRuntimeStageBinding? bindingForStage(String stageId) {
    for (final binding in stageBindings) {
      if (binding.stageId == stageId) return binding;
    }
    return null;
  }
}

UnmodifiableMapView<String, T> _unmodifiableMap<T>(Map<String, T> values) =>
    UnmodifiableMapView(Map<String, T>.unmodifiable(values));
