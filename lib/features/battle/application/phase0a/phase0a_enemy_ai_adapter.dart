import '../../../../core/domain/enums.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_enemy_skill_binding.dart';
import '../../domain/phase0a/phase0a_defense_tuning.dart';

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
    this.defenseTuning,
  });

  final double attackRange;
  final double attackHalfArcRadians;
  final double attackCooldownSeconds;
  final Map<String, List<Phase0aEnemySkillBinding>> skillBindingsByActor;
  final Map<String, int> basicQiDeltaByActor;
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
          enemy.staggerTicksRemaining > 0) {
        continue;
      }
      final delta = player.position - enemy.position;
      if (delta.lengthSquared > attackRange * attackRange) {
        intents.add(
          Phase0aMoveIntent(actorId: enemy.id, direction: delta.normalized()),
        );
        continue;
      }
      final skill = _pickSkill(enemy);
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
            defenseFlags: defenseTuning?.skillAttackFlags,
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
          defenseFlags: defenseTuning?.basicAttackFlags,
        ),
      );
    }
    return intents;
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
}
