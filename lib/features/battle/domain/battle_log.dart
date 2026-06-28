import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../cultivation/application/skill_proficiency_formatter.dart';
import 'battle_state.dart';
import 'enum_localizations.dart';

/// 战斗事件日志（phase1_tasks.md T13）。
///
/// 把 [BattleState.actionLog] 里的 [BattleAction] 转为人类可读的中文日志串。
/// **不修改 BattleState**，纯字符串生成。用作调试 + UI 侧边栏 + 底部战报条。
///
/// **CLAUDE.md §5.6 正名的合法集中式 sink(v1.20)**:战报格式化文本(大量
/// 插值句子)集中维护在本文件,与 `EnumL10n` / `UiStrings` 同类,不算「散写硬
/// 编码」。新增战报文本进本文件,不要在调用点内联。
///
/// 与 [DamageCalculator] 解耦（phase1_tasks T13 §752）：本文件只读
/// [AttackResult] 已计算好的字段，不重算公式。
class BattleLog {
  BattleLog._();

  /// 把一个 [BattleAction] 转为单行中文日志。
  ///
  /// 覆盖闪避 / 暴击 / 流派克制 / 击杀 4 类标识。actor / target 名字从
  /// `state` 的 leftTeam + rightTeam 中按 characterId 查（包含已死亡的，因为
  /// 行动写入时尸体仍在阵列）。
  ///
  /// 例：
  /// - `[第 23 回合] 祖师对 鬼影刀客 使用「青龙拳」，暴击造成 2340 伤害（刚猛克阴柔 ×1.25 / 附带震伤）`
  /// - `[第 5 回合] 学徒对 武僧 使用「直拳」，被闪避（闪避率 12%）`
  /// - `[第 47 回合] 祖师对 山贼头子 使用「破阵斩」，造成 980 伤害（击杀）`
  static String formatAction(BattleAction action, BattleState state) {
    final actorName = _findName(state, action.actorId) ?? '未知';
    final skillName = action.skill?.name ?? '未知招式';
    final r = action.attackResult;
    final tickStr = '[第 ${action.tick} 回合]';

    if (r == null || action.targetId == null) {
      // 非攻击行动（Phase 1 暂无 buff/被动行动；保留兜底）
      return '$tickStr $actorName ${action.description}';
    }

    final targetName = _findName(state, action.targetId!) ?? '未知';

    if (r.isDodged) {
      final ev = (r.evasionRate * 100).toStringAsFixed(0);
      return '$tickStr $actorName 对 $targetName 使用「$skillName」，'
          '被闪避（闪避率 $ev%）';
    }

    final critTag = r.isCritical ? '暴击' : '';
    final markers = <String>[];
    if (r.schoolCounterMultiplier != 1.0) {
      // 找出克制方向：当前 actor.school 克制 target.school 时倍率 > 1.0
      final actor = _findChar(state, action.actorId);
      final target = _findChar(state, action.targetId!);
      if (actor != null && target != null) {
        final atkS = EnumL10n.school(actor.school);
        final defS = EnumL10n.school(target.school);
        // multiplier > 1.0: attacker 克 defender；< 1.0: defender 克 attacker
        // （GDD §4.4 三流派单向克制环：刚猛→阴柔→灵巧→刚猛）
        final relation = r.schoolCounterMultiplier > 1.0
            ? '$atkS克$defS'
            : '$defS克$atkS';
        markers.add('$relation ×${_fmt(r.schoolCounterMultiplier)}');
      } else {
        markers.add('流派克制 ×${_fmt(r.schoolCounterMultiplier)}');
      }
    }
    for (final eff in r.appliedEffects) {
      markers.add(EnumL10n.attackEffect(eff));
    }

    if (r.lifestealHeal > 0) markers.add('吸血 +${r.lifestealHeal}');

    final actor = _findChar(state, action.actorId);
    if (actor?.attackPowerMultiplierSource ==
            AttackPowerMultiplierSource.jianghuEnmity &&
        actor!.attackPowerMultiplier > 1.0) {
      markers.add('江湖恩怨 ×${_fmt(actor.attackPowerMultiplier)}');
    }

    if (actor != null && action.skill != null && GameRepository.isLoaded) {
      markers.add(
        SkillProficiencyFormatter.compactEffect(
          skill: action.skill!,
          uses: actor.skillUses[action.skill!.id] ?? 0,
          cfg: GameRepository.instance.numbers.skillProficiency,
        ),
      );
    }

    final target = _findChar(state, action.targetId!);
    final killed = target != null && !target.isAlive;
    if (killed) markers.add('击杀');

    final markerStr = markers.isEmpty ? '' : '（${markers.join(' / ')}）';
    return '$tickStr $actorName 对 $targetName 使用「$skillName」，'
        '$critTag造成 ${r.finalDamage} 伤害$markerStr';
  }

  /// 战斗结束总结（phase1_tasks.md T13 §740）。
  ///
  /// 输出多行：胜负 + 总回合 + 最高单次伤害 + 被击杀角色。无攻击发生（极端
  /// 情况，例如双方一开战就 result）时降级到只报胜负 + 回合。
  ///
  /// 例：
  /// ```
  /// 战斗结束（左队胜）。共 87 回合。
  /// 最高单次伤害：祖师 8420（对 鬼影刀客）。
  /// 被击杀：鬼影刀客 / 山贼头子 / 武僧。
  /// ```
  static String formatSummary(BattleState s) {
    final result = s.result;
    final resultStr = result == null ? '未结束' : EnumL10n.battleResult(result);
    final lines = <String>['战斗结束（$resultStr）。共 ${s.tick} 回合。'];

    // 最高单次伤害
    BattleAction? top;
    for (final a in s.actionLog) {
      final dmg = a.attackResult?.finalDamage ?? 0;
      if (dmg <= 0) continue;
      if (top == null ||
          (a.attackResult!.finalDamage > top.attackResult!.finalDamage)) {
        top = a;
      }
    }
    if (top != null) {
      final actor = _findName(s, top.actorId) ?? '未知';
      final target = _findName(s, top.targetId!) ?? '未知';
      lines.add('最高单次伤害：$actor ${top.attackResult!.finalDamage}（对 $target）。');
    }

    // 被击杀的角色
    final dead = <String>[];
    for (final c in s.leftTeam) {
      if (!c.isAlive) dead.add(c.name);
    }
    for (final c in s.rightTeam) {
      if (!c.isAlive) dead.add(c.name);
    }
    if (dead.isNotEmpty) {
      lines.add('被击杀：${dead.join(' / ')}。');
    }

    return lines.join('\n');
  }

  /// 把整场战斗的 actionLog 拼成多行字符串（UI 侧边栏直接用）。
  static String formatAllActions(BattleState s) =>
      s.actionLog.map((a) => formatAction(a, s)).join('\n');

  // ───────────────────────────────────────────────────────────────────────
  // T3 底部战报条：从 actionLog 里挑"关键"事件做紧凑展示。
  // ───────────────────────────────────────────────────────────────────────

  /// 是否为"关键战报"：大招命中 / 破招技命中 / 暴击 / 击杀。
  /// 蓄势由顶部危险条([_DangerBar])呈现、战败由结算 overlay 呈现，不在此列。
  static bool isKeyAction(BattleAction a, BattleState state) {
    final r = a.attackResult;
    if (r == null || r.isDodged) return false;
    if (r.isCritical) return true;
    final skill = a.skill;
    if (skill != null &&
        (skill.type == SkillType.ultimate ||
            skill.type == SkillType.jointSkill ||
            skill.canInterrupt)) {
      return true;
    }
    if (a.targetId != null) {
      final target = _findChar(state, a.targetId!);
      if (target != null && !target.isAlive) return true; // 击杀
    }
    return false;
  }

  /// 最近 [limit] 条关键战报，**最新在前**（index 0 = 最近）。
  static List<BattleAction> recentKeyActions(
    BattleState state, {
    int limit = 3,
  }) {
    final out = <BattleAction>[];
    for (
      var i = state.actionLog.length - 1;
      i >= 0 && out.length < limit;
      i--
    ) {
      if (isKeyAction(state.actionLog[i], state)) out.add(state.actionLog[i]);
    }
    return out;
  }

  /// 紧凑单行（无"[第 N 回合]"前缀，给底部战报条用）。
  /// 例：`祖师 「青锋绝」2340 伤（暴击·击杀）`。
  static String formatActionCompact(BattleAction a, BattleState state) {
    final actorName = _findName(state, a.actorId) ?? '未知';
    final skillName = a.skill?.name ?? '普攻';
    final r = a.attackResult;
    if (r == null) return '$actorName $skillName';
    if (r.isDodged) return '$actorName 「$skillName」被闪避';
    final tags = <String>[];
    if (r.isCritical) tags.add('暴击');
    if (a.targetId != null) {
      final target = _findChar(state, a.targetId!);
      if (target != null && !target.isAlive) tags.add('击杀');
    }
    final tagStr = tags.isEmpty ? '' : '（${tags.join('·')}）';
    return '$actorName 「$skillName」${r.finalDamage} 伤$tagStr';
  }

  // ───────────────────────────────────────────────────────────────────────
  static String? _findName(BattleState s, int characterId) =>
      _findChar(s, characterId)?.name;

  static BattleCharacter? _findChar(BattleState s, int characterId) {
    for (final c in s.leftTeam) {
      if (c.characterId == characterId) return c;
    }
    for (final c in s.rightTeam) {
      if (c.characterId == characterId) return c;
    }
    return null;
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(1);
    return v.toString();
  }
}
