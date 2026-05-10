import 'package:flutter/material.dart';

import '../../combat/battle_log.dart';
import '../../combat/battle_state.dart';
import '../../combat/enum_localizations.dart';
import '../../data/defs/skill_def.dart';
import '../../data/models/enums.dart';
import '../strings.dart';
import '../theme/colors.dart';
import 'character_avatar.dart';

/// 3v3 战斗主屏静态布局（phase1_tasks.md T14）。
///
/// 结构（从外向内）：
///   Scaffold
///   └ Column
///     ├ _Header           顶栏：标题 / 回合 / 结果
///     ├ Expanded Row
///     │   ├ _LogSidebar   左侧战斗日志（220 px）
///     │   └ _BattleField  中央 3v3 角色区
///     └ _BottomBar        底栏：3 个大招按钮 + 快进按钮
///
/// 全程不用 Stack + Positioned（§798）。`onUltimate` / `onFastForward` 在 T14
/// 阶段允许为 null，T16 接 Riverpod 时由外层注入。
class BattleScreen extends StatelessWidget {
  final BattleState state;
  final void Function(int slotIndex)? onUltimate;
  final VoidCallback? onFastForward;

  const BattleScreen({
    super.key,
    required this.state,
    this.onUltimate,
    this.onFastForward,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(state: state),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LogSidebar(state: state),
                  Expanded(child: _BattleField(state: state)),
                ],
              ),
            ),
            _BottomBar(
              state: state,
              onUltimate: onUltimate,
              onFastForward: onFastForward,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final BattleState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final aliveLeft = state.leftTeam.where((c) => c.isAlive).length;
    final aliveRight = state.rightTeam.where((c) => c.isAlive).length;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(bottom: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        children: [
          Text(
            UiStrings.battleTitle(aliveLeft, aliveRight),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (state.result != null) ...[
            Text(
              EnumL10n.battleResult(state.result!),
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            '${UiStrings.tickPrefix} ${state.tick}',
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogSidebar extends StatelessWidget {
  final BattleState state;
  const _LogSidebar({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasLog = state.actionLog.isNotEmpty;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: WuxiaColors.sidebar,
        border: Border(right: BorderSide(color: WuxiaColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: WuxiaColors.panel,
              border: Border(bottom: BorderSide(color: WuxiaColors.border)),
            ),
            child: const Text(
              UiStrings.battleLog,
              style: TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: hasLog
                ? ListView.separated(
                    padding: const EdgeInsets.all(8),
                    reverse: true,
                    itemCount: state.actionLog.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (_, idx) {
                      final i = state.actionLog.length - 1 - idx;
                      final action = state.actionLog[i];
                      return Text(
                        BattleLog.formatAction(action, state),
                        style: const TextStyle(
                          color: WuxiaColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      UiStrings.emptyLog,
                      style: TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BattleField extends StatelessWidget {
  final BattleState state;
  const _BattleField({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _TeamColumn(
              team: state.leftTeam,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _TeamColumn(
              team: state.rightTeam,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final List<BattleCharacter> team;
  final CrossAxisAlignment alignment;

  const _TeamColumn({required this.team, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: alignment,
      children: [
        for (var i = 0; i < 3; i++)
          if (i < team.length)
            CharacterAvatar(character: team[i])
          else
            const SizedBox(width: 160, height: 80),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final BattleState state;
  final void Function(int slotIndex)? onUltimate;
  final VoidCallback? onFastForward;

  const _BottomBar({
    required this.state,
    this.onUltimate,
    this.onFastForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _UltimateButton(
              character:
                  i < state.leftTeam.length ? state.leftTeam[i] : null,
              onPressed:
                  onUltimate == null ? null : () => onUltimate!(i),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
          const Spacer(),
          _FastForwardButton(onPressed: onFastForward),
        ],
      ),
    );
  }
}

class _UltimateButton extends StatelessWidget {
  final BattleCharacter? character;
  final VoidCallback? onPressed;

  const _UltimateButton({this.character, this.onPressed});

  /// 取该角色"主修可用大招"。当前实现：第一个 `type == ultimate` 的招式。
  /// 若该角色没有大招（如普攻位/强力技能位），返回 null → 按钮永久置灰。
  static SkillDef? _findUltimate(BattleCharacter c) {
    for (final skill in c.availableSkills) {
      if (skill.type == SkillType.ultimate) return skill;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = character;
    SkillDef? ultimate;
    bool ready = false;
    if (c != null && c.isAlive) {
      ultimate = _findUltimate(c);
      if (ultimate != null) {
        final cd = c.skillCooldowns[ultimate.id] ?? 0;
        ready = c.currentInternalForce >= ultimate.internalForceCost && cd <= 0;
      }
    }

    final activeColor = c == null
        ? WuxiaColors.buttonDisabled
        : WuxiaColors.schoolColor(c.school);

    return SizedBox(
      width: 96,
      height: 52,
      child: ElevatedButton(
        onPressed: ready ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          disabledBackgroundColor: WuxiaColors.buttonDisabled,
          foregroundColor: WuxiaColors.textPrimary,
          disabledForegroundColor: WuxiaColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              UiStrings.ultimate,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (c != null)
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, height: 1.2),
              ),
          ],
        ),
      ),
    );
  }
}

class _FastForwardButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _FastForwardButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: WuxiaColors.textPrimary,
          side: const BorderSide(color: WuxiaColors.textSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: const Text(
          UiStrings.fastForward,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
