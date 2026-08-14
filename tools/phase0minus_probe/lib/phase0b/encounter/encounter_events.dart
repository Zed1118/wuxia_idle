import 'package:flame/components.dart';

import '../playable/style_profiles.dart';

/// Neutral, copy-free encounter events for the Phase 0B encounter layer.
///
/// NOT FINAL — probe-local only. Events carry stable fields and a stable
/// `signature` so deterministic replays can be compared; they contain no
/// presentation copy, no loot payloads, and no feedback-layer dependency.
sealed class EncounterEvent {
  const EncounterEvent({required this.time});

  final double time;

  String get signature;
}

final class EncounterStarted extends EncounterEvent {
  const EncounterStarted({
    required super.time,
    required this.seed,
    required this.style,
  });

  final int seed;
  final DraftStyleKind style;

  @override
  String get signature => 'EncounterStarted($seed,${style.name})';
}

final class EnemyEntered extends EncounterEvent {
  const EnemyEntered({
    required super.time,
    required this.groupId,
    required this.enemyId,
  });

  final int groupId;
  final int enemyId;

  @override
  String get signature => 'EnemyEntered($groupId,$enemyId)';
}

final class EnemyTelegraphStarted extends EncounterEvent {
  const EnemyTelegraphStarted({
    required super.time,
    required this.groupId,
    required this.enemyId,
  });

  final int groupId;
  final int enemyId;

  @override
  String get signature => 'EnemyTelegraphStarted($groupId,$enemyId)';
}

final class EnemyStrikeResolved extends EncounterEvent {
  const EnemyStrikeResolved({
    required super.time,
    required this.groupId,
    required this.enemyId,
    required this.hitHero,
    required this.damage,
  });

  final int groupId;
  final int enemyId;
  final bool hitHero;
  final double damage;

  @override
  String get signature =>
      'EnemyStrikeResolved($groupId,$enemyId,$hitHero,${damage.toStringAsFixed(1)})';
}

final class EnemyRetreated extends EncounterEvent {
  const EnemyRetreated({
    required super.time,
    required this.groupId,
    required this.enemyId,
  });

  final int groupId;
  final int enemyId;

  @override
  String get signature => 'EnemyRetreated($groupId,$enemyId)';
}

final class EnemyDamaged extends EncounterEvent {
  const EnemyDamaged({
    required super.time,
    required this.groupId,
    required this.enemyId,
    required this.damage,
    required this.defeated,
  });

  final int groupId;
  final int enemyId;
  final double damage;
  final bool defeated;

  @override
  String get signature =>
      'EnemyDamaged($groupId,$enemyId,${damage.toStringAsFixed(1)},$defeated)';
}

enum EncounterDangerShape { circle, arc }

final class BossTelegraphStarted extends EncounterEvent {
  const BossTelegraphStarted({
    required super.time,
    required this.shape,
    required this.center,
    required this.radius,
    required this.halfArcRadians,
    required this.direction,
  });

  final EncounterDangerShape shape;
  final Vector2 center;
  final double radius;
  final double halfArcRadians;
  final Vector2? direction;

  @override
  String get signature =>
      'BossTelegraphStarted(${shape.name},${center.x.toStringAsFixed(1)},'
      '${center.y.toStringAsFixed(1)},${radius.toStringAsFixed(1)})';
}

enum EncounterBossStrikeKind { slam, sweep }

final class BossStrikeResolved extends EncounterEvent {
  const BossStrikeResolved({
    required super.time,
    required this.kind,
    required this.hitHero,
    required this.damage,
  });

  final EncounterBossStrikeKind kind;
  final bool hitHero;
  final double damage;

  @override
  String get signature =>
      'BossStrikeResolved(${kind.name},$hitHero,${damage.toStringAsFixed(1)})';
}

final class BossPhaseChanged extends EncounterEvent {
  const BossPhaseChanged({
    required super.time,
    required this.phase,
    required this.total,
  });

  final int phase;
  final int total;

  @override
  String get signature => 'BossPhaseChanged($phase/$total)';
}

final class BossExhaustedStarted extends EncounterEvent {
  const BossExhaustedStarted({required super.time});

  @override
  String get signature => 'BossExhaustedStarted';
}

final class BossDamaged extends EncounterEvent {
  const BossDamaged({
    required super.time,
    required this.damage,
    required this.defeated,
  });

  final double damage;
  final bool defeated;

  @override
  String get signature => 'BossDamaged(${damage.toStringAsFixed(1)},$defeated)';
}

final class BossDefeated extends EncounterEvent {
  const BossDefeated({required super.time});

  @override
  String get signature => 'BossDefeated';
}

final class HeroDamaged extends EncounterEvent {
  const HeroDamaged({
    required super.time,
    required this.amount,
    required this.healthAfter,
  });

  final double amount;
  final double healthAfter;

  @override
  String get signature =>
      'HeroDamaged(${amount.toStringAsFixed(1)},${healthAfter.toStringAsFixed(1)})';
}

final class HeroResourceChanged extends EncounterEvent {
  const HeroResourceChanged({
    required super.time,
    required this.delta,
    required this.value,
  });

  final double delta;
  final double value;

  @override
  String get signature =>
      'HeroResourceChanged(${delta.toStringAsFixed(1)},${value.toStringAsFixed(1)})';
}

final class HeroStyleChanged extends EncounterEvent {
  const HeroStyleChanged({required super.time, required this.style});

  final DraftStyleKind style;

  @override
  String get signature => 'HeroStyleChanged(${style.name})';
}

final class GroupCleared extends EncounterEvent {
  const GroupCleared({required super.time, required this.groupId});

  final int groupId;

  @override
  String get signature => 'GroupCleared($groupId)';
}

final class LootRequested extends EncounterEvent {
  const LootRequested({required super.time, required this.sourceId});

  final String sourceId;

  @override
  String get signature => 'LootRequested($sourceId)';
}

enum EncounterOutcome { victory, defeat }

final class BattleConcluded extends EncounterEvent {
  const BattleConcluded({required super.time, required this.outcome});

  final EncounterOutcome outcome;

  @override
  String get signature => 'BattleConcluded(${outcome.name})';
}
