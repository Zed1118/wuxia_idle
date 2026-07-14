import '../../../core/domain/enums.dart';
import '../domain/battle_skill_utils.dart';
import '../domain/battle_state.dart';

/// 首通展示帧节拍类型（开局亮相由 [FirstClearShowcaseDirector.consumeOpening]
/// 单独走 timer 起手路径，不在此枚举）。
enum ShowcaseBeat {
  /// 玩家首个非普攻真命中技能：慢镜（额外顿帧 + 命中特写）。
  firstSkill,

  /// 玩家首次破招成功：题字强化（峰值字号 + 辉光 + 闪白）。
  interruptFlourish,
}

/// 首通脚本化展示帧导演（玩法评估 §十三 #2）。
///
/// 纯表现层状态机：只读 action/state 元数据判定「整场首次」边沿，每拍至多
/// 消费一次；不写 BattleState、不参与结算（守 §5.4）。非首通不实例化
/// （caller 据 [BattleScreenPlaybackConfig.firstClearShowcase] 决定），
/// 快进态由 caller 决定是否呈现——本类只管「首次」判定与消费。
class FirstClearShowcaseDirector {
  bool _openingPlayed = false;
  bool _firstSkillPlayed = false;
  bool _chargeCuePlayed = false;
  bool _interruptFlourishPlayed = false;

  /// 开局亮相：首次调用 true（caller 播题字 + 延迟起手），此后恒 false。
  bool consumeOpening() {
    if (_openingPlayed) return false;
    _openingPlayed = true;
    return true;
  }

  /// 敌方首次起手蓄力边沿：prev/next 逐敌方角色（teamSide==1）判
  /// chargingSkill null→非null（镜像 [chargeTransitionSfx] 体例），整场仅
  /// 消费一次；非边沿不消费。prev 为 null（开局）→ false。
  bool consumeEnemyChargeCue(BattleState? prev, BattleState next) {
    if (_chargeCuePlayed || prev == null) return false;
    if (!_enemyChargeStarted(prev, next)) return false;
    _chargeCuePlayed = true;
    return true;
  }

  static bool _enemyChargeStarted(BattleState prev, BattleState next) {
    final prevById = <int, BattleCharacter>{
      for (final c in prev.rightTeam) c.characterId: c,
    };
    for (final c in next.rightTeam) {
      final p = prevById[c.characterId];
      if (p == null) continue;
      if (p.chargingSkill == null && c.chargingSkill != null) return true;
    }
    return false;
  }

  /// actionLog 边沿：返回本动作触发的展示帧节拍（null=无）。只认玩家侧
  /// （teamSide==0）动作：
  /// - [ShowcaseBeat.interruptFlourish]：首次破招成功（优先于 firstSkill，
  ///   同一动作二者互斥，firstSkill 留给下一个技能动作）。
  /// - [ShowcaseBeat.firstSkill]：首个非普攻且真命中（attackResult 非空）
  ///   的技能动作。
  ShowcaseBeat? onAction(BattleAction action, BattleState s) {
    final actor = findCharacter(action.actorId, s);
    if (actor == null || actor.teamSide != 0) return null;
    if (action.interrupted) {
      if (_interruptFlourishPlayed) return null;
      _interruptFlourishPlayed = true;
      return ShowcaseBeat.interruptFlourish;
    }
    final skill = action.skill;
    if (!_firstSkillPlayed &&
        skill != null &&
        skill.type != SkillType.normalAttack &&
        action.attackResult != null) {
      _firstSkillPlayed = true;
      return ShowcaseBeat.firstSkill;
    }
    return null;
  }
}
