import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/battle_log.dart';
import '../../combat/battle_state.dart';
import '../../combat/damage_calculator.dart';
import '../../combat/enum_localizations.dart';
import '../../data/defs/skill_def.dart';
import '../../data/models/enums.dart';
import '../../data/numbers_config.dart';
import '../../providers/battle_providers.dart';
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

/// 3v3 战斗主屏（phase1_tasks T14 静态布局 + T15 动画/飘字 + T16 Riverpod 串接）。
///
/// **T16 起切换到 [ConsumerStatefulWidget]**：状态来源从外部 `state` 参数改为
/// [battleNotifierProvider]。Timer 不再播放预算 actionLog，而是驱动
/// [BattleNotifier.advance]，引擎实时 tick 产生新 action 后由 `ref.listen`
/// 触发动画。结构：
/// - `ref.watch(battleNotifierProvider)` 提供子组件渲染数据
/// - `ref.listen` 三类边沿：team 从空 → 非空启动 Timer / actionLog 增长触发
///   动画 + 解除大招置灰 / result 翻转弹结算 dialog
///
/// [animConfig] 默认 [AnimationNumbers.defaults]（与 numbers.yaml 同值）；
/// 测试可注入更短时序加速。
class BattleScreen extends ConsumerStatefulWidget {
  final AnimationNumbers animConfig;

  /// 顶部提示文案（T17 测试场景用）；null 则不显示。
  final String? hint;

  /// 战斗结束关闭 dialog 后的回调（T17 返回调试菜单用）；null 则无额外动作。
  final VoidCallback? onBattleEnd;

  const BattleScreen({
    super.key,
    this.animConfig = AnimationNumbers.defaults,
    this.hint,
    this.onBattleEnd,
  });

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  // 6 个攻击动画 controller（slotKey = teamSide*3 + slotIndex）
  late final List<AnimationController> _attackControllers;

  // 屏震 controller（暴击时触发）
  late final AnimationController _shakeCtrl;

  // 飘字状态：slotKey → 活跃飘字列表
  final Map<int, List<_PopupEntry>> _popups = {};
  int _nextPopupId = 0;

  // 实时 tick 定时器（advance() 驱动）
  Timer? _playTimer;
  bool _isFastForward = false;

  // 大招按钮按下后置灰：char.id ∈ set 时按钮 disabled，下次该角色行动后解除。
  // **本地 state，不污染 BattleState**（spec §16.2 注：UI 状态属于 UI 层）。
  final Set<int> _disabledUltimateChars = {};

  // 战斗结算 dialog 已显示标志，避免 result 字段连续触发多次弹窗
  bool _resultDialogShown = false;

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
    // Timer 不在 initState 启动，等 ref.listen 看到 startBattle 完成后再启动。
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

  // ─── Timer / advance 驱动 ────────────────────────────────────────────────

  void _startTimer() {
    _playTimer?.cancel();
    final interval = _isFastForward
        ? widget.animConfig.fastForwardIntervalMs
        : widget.animConfig.actionIntervalMs;
    _playTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) {
        if (!mounted) return;
        ref.read(battleNotifierProvider.notifier).advance();
      },
    );
  }

  void _toggleFastForward() {
    setState(() => _isFastForward = !_isFastForward);
    if (_playTimer != null) _startTimer();
  }

  // ─── 动画 / 飘字 ─────────────────────────────────────────────────────────

  void _playAction(BattleAction action, BattleState s) {
    final actor = _findCharacter(action.actorId, s);
    if (actor != null) {
      final key = _slotKey(actor.teamSide, actor.slotIndex);
      _attackControllers[key].forward(from: 0.0);
    }
    if (action.attackResult != null && action.targetId != null) {
      final target = _findCharacter(action.targetId!, s);
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

  // ─── 大招 ────────────────────────────────────────────────────────────────

  void _onUltimatePressed(int slotIndex) {
    final s = ref.read(battleNotifierProvider);
    if (slotIndex >= s.leftTeam.length) return;
    final c = s.leftTeam[slotIndex];
    final ultimate = _findUltimateOf(c);
    if (!_isUltimateReady(c, ultimate)) return;
    if (_disabledUltimateChars.contains(c.characterId)) return;

    ref
        .read(battleNotifierProvider.notifier)
        .requestUltimate(c.characterId, ultimate!);
    setState(() => _disabledUltimateChars.add(c.characterId));
  }

  static SkillDef? _findUltimateOf(BattleCharacter c) {
    for (final skill in c.availableSkills) {
      if (skill.type == SkillType.ultimate) return skill;
    }
    return null;
  }

  static bool _isUltimateReady(BattleCharacter c, SkillDef? ultimate) {
    if (!c.isAlive || ultimate == null) return false;
    final cd = c.skillCooldowns[ultimate.id] ?? 0;
    return c.currentInternalForce >= ultimate.internalForceCost && cd <= 0;
  }

  // ─── 结算 dialog ─────────────────────────────────────────────────────────

  void _showResultDialog(BattleResult result, BattleState s) {
    if (_resultDialogShown || !mounted) return;
    _resultDialogShown = true;

    final totalDamage = s.actionLog
        .map((a) => a.attackResult?.finalDamage ?? 0)
        .fold<int>(0, (sum, d) => sum + d);
    final critCount = s.actionLog
        .where((a) => a.attackResult?.isCritical ?? false)
        .length;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: WuxiaColors.panel,
        title: Text(
          EnumL10n.battleResult(result),
          style: const TextStyle(
            color: WuxiaColors.resultHighlight,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          UiStrings.battleSummary(totalDamage, critCount, s.tick),
          style: const TextStyle(color: WuxiaColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBattleEnd?.call();
            },
            child: Text(
              widget.onBattleEnd != null
                  ? UiStrings.backToMenu
                  : UiStrings.close,
              style: const TextStyle(color: WuxiaColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 工具方法 ─────────────────────────────────────────────────────────────

  static int _slotKey(int teamSide, int slotIndex) => teamSide * 3 + slotIndex;

  BattleCharacter? _findCharacter(int characterId, BattleState s) {
    for (final c in s.leftTeam) {
      if (c.characterId == characterId) return c;
    }
    for (final c in s.rightTeam) {
      if (c.characterId == characterId) return c;
    }
    return null;
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleNotifierProvider);

    ref.listen<BattleState>(battleNotifierProvider, (prev, next) {
      // 1. 启动 Timer：team 从空 → 非空且未结束
      final wasEmpty = prev == null || prev.leftTeam.isEmpty;
      if (wasEmpty && next.leftTeam.isNotEmpty && !next.isFinished) {
        _startTimer();
      }

      // 2. 战斗结束：停 timer + 弹结算 dialog（postFrame 避免 build 期 setState）
      if ((prev?.result == null) && next.result != null) {
        _playTimer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showResultDialog(next.result!, next);
        });
      }

      // 3. actionLog 新增：触发动画 + 解除大招按钮置灰
      if (prev != null && next.actionLog.length > prev.actionLog.length) {
        final newActions = next.actionLog.sublist(prev.actionLog.length);
        for (final a in newActions) {
          _playAction(a, next);
        }
        if (_disabledUltimateChars.isNotEmpty) {
          setState(() {
            for (final a in newActions) {
              _disabledUltimateChars.remove(a.actorId);
            }
          });
        }
      }
    });

    // team 空时（startBattle 还未调用）渲染 placeholder
    if (state.leftTeam.isEmpty && state.rightTeam.isEmpty) {
      return const Scaffold(
        backgroundColor: WuxiaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: WuxiaColors.textMuted),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
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
              if (widget.hint != null) _HintBanner(hint: widget.hint!),
              _Header(state: state),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LogSidebar(state: state),
                    Expanded(
                      child: _BattleField(
                        state: state,
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
                state: state,
                disabledUltimateChars: _disabledUltimateChars,
                onUltimate: _onUltimatePressed,
                onFastForward: _toggleFastForward,
                isFastForward: _isFastForward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 场景 hint 横幅（T17）─────────────────────────────────────────────────

class _HintBanner extends StatelessWidget {
  final String hint;
  const _HintBanner({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF2A3A2A),
      child: Text(
        hint,
        style: const TextStyle(
          color: Color(0xFF8BC28B),
          fontSize: 13,
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
        AttackAnimationWidget(
          animation: attackController,
          isLeftTeam: isLeftTeam,
          config: animConfig,
          child: CharacterAvatar(character: character),
        ),
        for (var i = 0; i < slotPopups.length; i++)
          _buildPopupPositioned(
            i,
            slotPopups[i],
            animConfig,
            slotKey,
            onPopupComplete,
          ),
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
  final Set<int> disabledUltimateChars;
  final void Function(int slotIndex) onUltimate;
  final VoidCallback onFastForward;
  final bool isFastForward;

  const _BottomBar({
    required this.state,
    required this.disabledUltimateChars,
    required this.onUltimate,
    required this.onFastForward,
    required this.isFastForward,
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
              disabledByPress: i < state.leftTeam.length &&
                  disabledUltimateChars.contains(state.leftTeam[i].characterId),
              onPressed: () => onUltimate(i),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
          const Spacer(),
          _FastForwardButton(
            onPressed: onFastForward,
            isActive: isFastForward,
          ),
        ],
      ),
    );
  }
}

class _UltimateButton extends StatelessWidget {
  final BattleCharacter? character;
  final bool disabledByPress;
  final VoidCallback onPressed;

  const _UltimateButton({
    required this.character,
    required this.disabledByPress,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = character;
    final ultimate = c == null
        ? null
        : _BattleScreenState._findUltimateOf(c);
    final ready = c != null &&
        _BattleScreenState._isUltimateReady(c, ultimate) &&
        !disabledByPress;

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
  final VoidCallback onPressed;
  final bool isActive;
  const _FastForwardButton({required this.onPressed, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isActive
              ? WuxiaColors.resultHighlight
              : WuxiaColors.textPrimary,
          side: BorderSide(
            color: isActive
                ? WuxiaColors.resultHighlight
                : WuxiaColors.textSecondary,
          ),
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
