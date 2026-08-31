import '../../../../core/domain/enums.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_enemy_behavior_profile.dart';
import 'phase0a_enemy_skill_binding.dart';
import '../../domain/phase0a/phase0a_defense_tuning.dart';
import '../../domain/phase0a/posture.dart';

/// 敌方 AI 适配器:从同一只读 state 产生与玩家同型的 intent,
/// 供同一 reducer 结算(在线=离线:手动与无头共用同一模拟核)。
///
/// 策略最小口径:射程外朝玩家移动,射程内普攻;目标选择与命中判定
/// 全部在 reducer 内完成,本层不复制任何结算规则。
final class Phase0aEnemyAiAdapter {
  const Phase0aEnemyAiAdapter({
    required this.attackRange,
    required this.attackHalfArcRadians,
    required this.attackCooldownSeconds,
    this.skillBindingsByActor = const {},
    this.basicQiDeltaByActor = const {},
    this.basicPowerMultiplierByActor = const {},
    required this.postureBasicPowerMultiplier,
    this.uniformBasicPowerMultiplier,
    this.behaviorProfilesByActor = const {},
    this.defendedEntityTargetIdByActor = const {},
    this.defenseTuning,
  });

  final double attackRange;
  final double attackHalfArcRadians;
  final double attackCooldownSeconds;
  final Map<String, List<Phase0aEnemySkillBinding>> skillBindingsByActor;
  final Map<String, int> basicQiDeltaByActor;
  final Map<String, int> basicPowerMultiplierByActor;
  final int postureBasicPowerMultiplier;
  final int? uniformBasicPowerMultiplier;
  final Map<String, Phase0aEnemyBehaviorProfile> behaviorProfilesByActor;
  final Map<String, String> defendedEntityTargetIdByActor;
  final Phase0aDefenseTuning? defenseTuning;

  List<Phase0aIntent> intentsFor({required Phase0aArenaState state}) {
    final player = state.player;
    if (!player.isAlive) return const [];
    final intents = <Phase0aIntent>[];
    final enemies = List<Phase0aActor>.of(state.enemies)
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final enemy in enemies) {
      if (!enemy.isAlive) continue;
      // 蓄力/踉跄中整条行动跳过(对齐旧引擎「蓄力/踉跄跳过行动」):
      // 不移动、不普攻、不放技能——reducer 另有同口径压制闸为双保险。
      if (enemy.chargingCast != null ||
          enemy.chargeTicksRemaining > 0 ||
          enemy.staggerTicksRemaining > 0 ||
          enemy.gatherControlTicksRemaining > 0) {
        continue;
      }
      final defendedEntity = state.defendedEntity;
      final defendedTargetId = defendedEntityTargetIdByActor[enemy.id];
      final targetsDefendedEntity =
          defendedTargetId != null &&
          defendedEntity?.id == defendedTargetId &&
          defendedEntity!.isAlive;
      final targetPosition = targetsDefendedEntity
          ? defendedEntity.position
          : player.position;
      final delta = targetPosition - enemy.position;
      final behaviorProfile = behaviorProfilesByActor[enemy.id];
      final movement = _movementFor(
        profile: behaviorProfile,
        actor: enemy,
        delta: delta,
      );
      if (movement != null) {
        intents.add(
          Phase0aMoveIntent(
            actorId: enemy.id,
            direction: movement,
            behaviorProfile: behaviorProfile,
          ),
        );
        continue;
      }
      final skill = targetsDefendedEntity ? null : _pickSkill(enemy);
      if (skill != null) {
        intents.add(
          Phase0aEnemySkillIntent(
            actorId: enemy.id,
            skill: skill.skill,
            aimDirection: delta.lengthSquared > 0
                ? delta.normalized()
                : ArenaVector.zero,
            range: skill.attackRange,
            halfArcRadians: skill.halfArcRadians,
            effectRadius: skill.effectRadius,
            cooldownSeconds: skill.cooldownSeconds,
            actionCooldownSeconds: attackCooldownSeconds,
            postureDamage: skill.postureDamageFor(
              basicPowerMultiplier: _requirePostureBasicPower(),
            ),
            postureHitKind: PostureHitKind.heavy,
            defenseFlags: defenseTuning?.skillAttackFlags,
            behaviorProfile: behaviorProfile,
          ),
        );
        continue;
      }
      intents.add(
        Phase0aAttackIntent(
          actorId: enemy.id,
          range: attackRange,
          halfArcRadians: attackHalfArcRadians,
          cooldownSeconds: attackCooldownSeconds,
          moveKind: Phase0aMoveKind.light,
          aimDirection: delta.lengthSquared > 0
              ? delta.normalized()
              : ArenaVector.zero,
          qiDelta: basicQiDeltaByActor[enemy.id] ?? 0,
          postureDamage: powerMultiplierToPostureDamage(
            _requireBasicPower(enemy.id),
            basicPowerMultiplier: _requirePostureBasicPower(),
          ),
          postureHitKind: PostureHitKind.light,
          defenseFlags: defenseTuning?.basicAttackFlags,
          behaviorProfile: behaviorProfile,
          preferredTargetId: targetsDefendedEntity ? defendedTargetId : null,
        ),
      );
    }
    return intents;
  }

  ArenaVector? _movementFor({
    required Phase0aEnemyBehaviorProfile? profile,
    required Phase0aActor actor,
    required ArenaVector delta,
  }) {
    final policy =
        profile?.movementPolicy ?? Phase0aEnemyMovementPolicy.directAdvance;
    final inRange = delta.lengthSquared <= attackRange * attackRange;
    switch (policy) {
      case Phase0aEnemyMovementPolicy.directAdvance:
        return inRange ? null : delta.normalized();
      case Phase0aEnemyMovementPolicy.holdDistance:
        if (!inRange) return delta.normalized();
        if (actor.attackCooldownRemaining > 0) {
          return delta.lengthSquared > 0
              ? ArenaVector(-delta.x, -delta.y).normalized()
              : ArenaVector.zero;
        }
        return null;
      case Phase0aEnemyMovementPolicy.lateralFlank:
        if (inRange) {
          if (actor.attackCooldownRemaining <= 0) return null;
          return delta.lengthSquared > 0
              ? ArenaVector(-delta.y, delta.x).normalized()
              : ArenaVector.zero;
        }
        final toward = delta.normalized();
        return (toward + ArenaVector(-toward.y, toward.x)).normalized();
      case Phase0aEnemyMovementPolicy.guardedPosition:
        return inRange ? null : ArenaVector.zero;
      case Phase0aEnemyMovementPolicy.pursuitEvasion:
        return delta.lengthSquared > 0
            ? ArenaVector(-delta.x, -delta.y).normalized()
            : ArenaVector.zero;
    }
  }

  Phase0aEnemySkillBinding? _pickSkill(Phase0aActor actor) {
    final bindings = skillBindingsByActor[actor.id];
    if (bindings == null || bindings.isEmpty) return null;
    Phase0aEnemySkillBinding? best;
    for (final binding in bindings) {
      final skill = binding.skill;
      // 顶层招牌蓄力技旁路阶段 unlock 门(charge profile 即唯一闸门,
      // reducer 起手蓄力分支同口径);其余技能仍按阶段解锁消费。
      if ((!actor.unlockedEnemySkillIds.contains(skill.id) &&
              skill.id != actor.chargeCast?.skill.id) ||
          !binding.isAutoSkill ||
          (skill.type == SkillType.ultimate && !actor.autoUltimate) ||
          skill.aiUsePolicy == AiUsePolicy.saveForInterrupt ||
          (actor.enemySkillCooldowns[skill.id] ?? 0) > 0 ||
          actor.qiCurrent < skill.qiCost) {
        continue;
      }
      if (best == null ||
          skill.powerMultiplier > best.skill.powerMultiplier ||
          (skill.powerMultiplier == best.skill.powerMultiplier &&
              skill.id.compareTo(best.skill.id) < 0)) {
        best = binding;
      }
    }
    return best;
  }

  int _requirePostureBasicPower() {
    return postureBasicPowerMultiplier;
  }

  int _requireBasicPower(String actorId) {
    final value =
        basicPowerMultiplierByActor[actorId] ?? uniformBasicPowerMultiplier;
    if (value == null) {
      throw StateError(
        'basicPowerMultiplierByActor[$actorId] is required for basic attacks',
      );
    }
    return value;
  }
}
