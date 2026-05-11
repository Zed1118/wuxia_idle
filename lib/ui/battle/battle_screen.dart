import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../combat/battle_log.dart';
import '../../combat/battle_state.dart';
import '../../combat/damage_calculator.dart';
import '../../combat/enum_localizations.dart';
import '../../data/defs/skill_def.dart';
import '../../data/models/enums.dart';
import '../../data/numbers_config.dart';
import '../strings.dart';
import '../theme/colors.dart';
import 'attack_animation.dart';
import 'character_avatar.dart';
import 'damage_popup.dart';

/// 单个飘字条目（id + 数据）。
class _PopupEntry {
  final int id;
  final DamagePopupData data;
  const _PopupEntry({required this.id, required this.data});
}

/// 3v3 战斗主屏（phase1_tasks T14 静态布局 + T15 攻击动画 + 伤害飘字）。
///
/// 从 T15 起改为 StatefulWidget，使用 TickerProviderStateMixin 统一管理
/// 6 个攻击 AnimationController + 1 个屏震 AnimationController。
/// Timer 驱动 actionLog 顺序播放，每个 action 触发攻击动画 + 飘字。
///
/// [animConfig] 默认为 [AnimationNumbers.defaults]（与 numbers.yaml 同值），
/// 测试时可传入更短的时序以加速。
class BattleScreen extends StatefulWidget {
  final BattleState state;
  final AnimationNumbers animConfig;
  final void Function(int slotIndex)? onUltimate;
  final VoidCallback? onFastForward;

  const BattleScreen({
    super.key,
    required this.state,
    this.animConfig = AnimationNumbers.defaults,
    this.onUltimate,
    this.onFastForward,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  // 6 个攻击动画 controller（slotKey = teamSide*3 + slotIndex）
  late final List<AnimationController> _attackControllers;

  // 屏震 controller（暴击时触发）
  late final AnimationController _shakeCtrl;

  // 飘字状态：slotKey → 活跃飘字列表
  final Map<int, List<_PopupEntry>> _popups = {};
  int _nextPopupId = 0;

  // 播放指针 & 定时器
  int _playingIndex = 0;
  Timer? _playTimer;
  bool _isFastForward = false;

  // ─── 生命周期 ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _attackControllers = List.generate(
      6,
      (_) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animConfig.attackTotalMs),
      ),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animConfig.shakeDurationMs),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    for (final c in _attackControllers) {
      c.dispose();
    }
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─── 播放逻辑 ────────────────────────────────────────────────────────────

  void _startTimer() {
    _playTimer?.cancel();
    final interval = _isFastForward
        ? widget.animConfig.fastForwardIntervalMs
        : widget.animConfig.actionIntervalMs;
    if (widget.state.actionLog.isEmpty) return;
    _playTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => _advancePlayback(),
    );
  }

  void _advancePlayback() {
    if (_playingIndex >= widget.state.actionLog.length) {
      _playTimer?.cancel();
      return;
    }
    final action = widget.state.actionLog[_playingIndex];
    _playingIndex++;
    _playAction(action);
  }

  void _playAction(BattleAction action) {
    // 攻击者前冲动画
    final actor = _findCharacter(action.actorId);
    if (actor != null) {
      final key = _slotKey(actor.teamSide, actor.slotIndex);
      _attackControllers[key].forward(from: 0.0);
    }

    // 伤害飘字
    if (action.attackResult != null && action.targetId != null) {
      final target = _findCharacter(action.targetId!);
      if (target != null) {
        _spawnPopup(target, action.attackResult!);
      }
    }
  }

  void _spawnPopup(BattleCharacter target, AttackResult result) {
    final key = _slotKey(target.teamSide, target.slotIndex);
    final data = _buildPopupData(result);
    final entry = _PopupEntry(id: _nextPopupId++, data: data);

    setState(() {
      (_popups[key] ??= []).add(entry);
    });

    if (result.isCritical) {
      _shakeCtrl.forward(from: 0.0);
    }
  }

  DamagePopupData _buildPopupData(AttackResult result) {
    if (result.isDodged) {
      return DamagePopupData(
        id: _nextPopupId,
        text: UiStrings.dodge,
        type: PopupType.dodge,
      );
    }
    return DamagePopupData(
      id: _nextPopupId,
      text: result.finalDamage.toString(),
      type: result.isCritical ? PopupType.critical : PopupType.normal,
      hasCounterUp: result.schoolCounterMultiplier > 1.0,
      hasCounterDown: result.schoolCounterMultiplier < 1.0,
    );
  }

  void _removePopup(int slotKey, int popupId) {
    setState(() {
      _popups[slotKey]?.removeWhere((e) => e.id == popupId);
    });
  }

  void _toggleFastForward() {
    setState(() => _isFastForward = !_isFastForward);
    _startTimer();
    widget.onFastForward?.call();
  }

  // ─── 工具方法 ─────────────────────────────────────────────────────────────

  static int _slotKey(int teamSide, int slotIndex) => teamSide * 3 + slotIndex;

  BattleCharacter? _findCharacter(int characterId) {
    for (final c in widget.state.leftTeam) {
      if (c.characterId == characterId) return c;
    }
    for (final c in widget.state.rightTeam) {
      if (c.characterId == characterId) return c;
    }
    return null;
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
        // 屏震：AnimatedBuilder 只重建 Transform，避免整棵树 setState
        child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (ctx, child) {
            final v = _shakeCtrl.value;
            final shakeAmt =
                math.sin(v * 2 * math.pi) * widget.animConfig.shakeOffsetPx;
            return Transform.translate(
              offset: Offset(shakeAmt, shakeAmt * 0.5),
              child: child,
            );
          },
          child: Column(
            children: [
              _Header(state: widget.state),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LogSidebar(state: widget.state),
                    Expanded(
                      child: _BattleField(
                        state: widget.state,
                        attackControllers: _attackControllers,
                        popups: _popups,
                        animConfig: widget.animConfig,
                        onPopupComplete: _removePopup,
                      ),
                    ),
                  ],
                ),
              ),
              _BottomBar(
                state: widget.state,
                onUltimate: widget.onUltimate,
                onFastForward: _toggleFastForward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 顶栏 ──────────────────────────────────────────────────────────────────

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

// ─── 日志侧栏 ──────────────────────────────────────────────────────────────

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

// ─── 战场区域 ──────────────────────────────────────────────────────────────

class _BattleField extends StatelessWidget {
  final BattleState state;
  final List<AnimationController> attackControllers;
  final Map<int, List<_PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final void Function(int slotKey, int popupId) onPopupComplete;

  const _BattleField({
    required this.state,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.onPopupComplete,
  });

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
              isLeftTeam: true,
              alignment: CrossAxisAlignment.start,
              attackControllers: attackControllers,
              popups: popups,
              animConfig: animConfig,
              onPopupComplete: onPopupComplete,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _TeamColumn(
              team: state.rightTeam,
              isLeftTeam: false,
              alignment: CrossAxisAlignment.end,
              attackControllers: attackControllers,
              popups: popups,
              animConfig: animConfig,
              onPopupComplete: onPopupComplete,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final List<BattleCharacter> team;
  final bool isLeftTeam;
  final CrossAxisAlignment alignment;
  final List<AnimationController> attackControllers;
  final Map<int, List<_PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final void Function(int slotKey, int popupId) onPopupComplete;

  const _TeamColumn({
    required this.team,
    required this.isLeftTeam,
    required this.alignment,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.onPopupComplete,
  });

  @override
  Widget build(BuildContext context) {
    final teamSide = isLeftTeam ? 0 : 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: alignment,
      children: [
        for (var i = 0; i < 3; i++)
          if (i < team.length)
            _CharacterSlot(
              character: team[i],
              isLeftTeam: isLeftTeam,
              attackController: attackControllers[teamSide * 3 + i],
              slotPopups: popups[teamSide * 3 + i] ?? const [],
              animConfig: animConfig,
              slotKey: teamSide * 3 + i,
              onPopupComplete: onPopupComplete,
            )
          else
            const SizedBox(width: 160, height: 80),
      ],
    );
  }
}

/// 单个角色槽：攻击动画包 + 头像 + 飘字（Stack 叠加，clipBehavior: none 允许溢出）。
class _CharacterSlot extends StatelessWidget {
  final BattleCharacter character;
  final bool isLeftTeam;
  final AnimationController attackController;
  final List<_PopupEntry> slotPopups;
  final AnimationNumbers animConfig;
  final int slotKey;
  final void Function(int slotKey, int popupId) onPopupComplete;

  const _CharacterSlot({
    required this.character,
    required this.isLeftTeam,
    required this.attackController,
    required this.slotPopups,
    required this.animConfig,
    required this.slotKey,
    required this.onPopupComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // CharacterAvatar（含 HP/内力条）整体随攻击动画平移
        AttackAnimationWidget(
          animation: attackController,
          isLeftTeam: isLeftTeam,
          config: animConfig,
          child: CharacterAvatar(character: character),
        ),
        // 飘字：向上堆叠，index 越大越靠上（避免重叠）。
        // 静态方法消除闭包捕获歧义，每个 popup 独立持有 entry 引用。
        for (var i = 0; i < slotPopups.length; i++)
          _buildPopupPositioned(i, slotPopups[i], animConfig, slotKey, onPopupComplete),
      ],
    );
  }

  static Widget _buildPopupPositioned(
    int index,
    _PopupEntry entry,
    AnimationNumbers config,
    int slotKey,
    void Function(int, int) onComplete,
  ) {
    return Positioned(
      top: -36.0 - index * 28.0,
      left: 0,
      right: 0,
      child: Center(
        child: DamagePopup(
          key: ValueKey(entry.id),
          data: entry.data,
          config: config,
          onComplete: () => onComplete(slotKey, entry.id),
        ),
      ),
    );
  }
}

// ─── 底栏 ──────────────────────────────────────────────────────────────────

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
              character: i < state.leftTeam.length ? state.leftTeam[i] : null,
              onPressed: onUltimate == null ? null : () => onUltimate!(i),
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
