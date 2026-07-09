import 'package:flutter/material.dart';

import '../../domain/battle_state.dart';
import '../../../../data/numbers_config.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../attack_animation.dart';
import '../battle_vfx_entries.dart';
import '../character_avatar.dart';
import '../damage_popup.dart';
import '../hit_flash.dart';

class BattleField extends StatelessWidget {
  final BattleState state;
  final List<AnimationController> attackControllers;
  final Map<int, List<PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  // 读秒环节拍 + 破绽窗口时长(供头像上蓄力/内伤/破绽环)。
  final Animation<double> beat;
  final int staggerWindowTicks;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final List<AnimationController> hitFlashControllers;
  final Map<int, Color> hitFlashColors;
  // 两段点选:点敌头像出手回调(仅右队/敌方非空);待发态(敌头像可点 + 高亮)。
  final void Function(int enemyId) onEnemyTap;
  final bool pendingActive;
  final int? hoveredEnemyId;
  final void Function(int enemyId, bool hovering) onEnemyHover;

  const BattleField({
    super.key,
    required this.state,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.beat,
    required this.staggerWindowTicks,
    required this.onPopupComplete,
    required this.hitFlashControllers,
    required this.hitFlashColors,
    required this.onEnemyTap,
    required this.pendingActive,
    required this.hoveredEnemyId,
    required this.onEnemyHover,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 168,
            child: TeamColumn(
              team: state.leftTeam,
              battleState: state,
              isLeftTeam: true,
              alignment: CrossAxisAlignment.start,
              attackControllers: attackControllers,
              popups: popups,
              animConfig: animConfig,
              chargeMaxTicks: chargeMaxTicks,
              beat: beat,
              staggerWindowTicks: staggerWindowTicks,
              onPopupComplete: onPopupComplete,
              hitFlashControllers: hitFlashControllers,
              hitFlashColors: hitFlashColors,
              onEnemyTap: null,
              pendingActive: false,
              hoveredEnemyId: null,
              onEnemyHover: null,
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
          SizedBox(
            width: 168,
            child: TeamColumn(
              team: state.rightTeam,
              battleState: state,
              isLeftTeam: false,
              alignment: CrossAxisAlignment.end,
              attackControllers: attackControllers,
              popups: popups,
              animConfig: animConfig,
              chargeMaxTicks: chargeMaxTicks,
              beat: beat,
              staggerWindowTicks: staggerWindowTicks,
              onPopupComplete: onPopupComplete,
              hitFlashControllers: hitFlashControllers,
              hitFlashColors: hitFlashColors,
              onEnemyTap: onEnemyTap,
              pendingActive: pendingActive,
              hoveredEnemyId: hoveredEnemyId,
              onEnemyHover: onEnemyHover,
            ),
          ),
        ],
      ),
    );
  }
}

class TeamColumn extends StatelessWidget {
  final List<BattleCharacter> team;
  // floor30 护法结界(Task 6):完整战场快照,逐槽透传给 CharacterAvatar 判定结界。
  final BattleState battleState;
  final bool isLeftTeam;
  final CrossAxisAlignment alignment;
  final List<AnimationController> attackControllers;
  final Map<int, List<PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  final Animation<double> beat;
  final int staggerWindowTicks;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final List<AnimationController> hitFlashControllers;
  final Map<int, Color> hitFlashColors;
  // 两段点选:点敌头像出手回调(仅右队/敌方非空,我方队为 null);
  // pendingActive = 待发态(敌头像可点 + 全员存活敌高亮为可选目标)。
  final void Function(int enemyId)? onEnemyTap;
  final bool pendingActive;
  final int? hoveredEnemyId;
  final void Function(int enemyId, bool hovering)? onEnemyHover;

  const TeamColumn({
    super.key,
    required this.team,
    required this.battleState,
    required this.isLeftTeam,
    required this.alignment,
    required this.attackControllers,
    required this.popups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.beat,
    required this.staggerWindowTicks,
    required this.onPopupComplete,
    required this.hitFlashControllers,
    required this.hitFlashColors,
    required this.onEnemyTap,
    required this.pendingActive,
    required this.hoveredEnemyId,
    required this.onEnemyHover,
  });

  @override
  Widget build(BuildContext context) {
    final teamSide = isLeftTeam ? 0 : 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: alignment,
      children: [
        // 2026-06-25:只渲染 team.length 个槽(去掉末尾空占位),Column 等分 → 1 怪
        // 居中 / 2 怪上下对称 / 3 怪不变,与 _slotFrac 的 slotVerticalFraction 同步。
        // P0-2 fix(2026-06-04 Codex 报 RenderFlex overflow @1280×720):每槽包
        // Expanded+FittedBox(scaleDown)——大窗保持原尺寸,最小窗自动等比微缩不溢出;
        // alignment 锁外缘,头像维持 0.12/0.88 与 projectile 比例坐标对齐。
        for (var i = 0; i < team.length; i++)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: isLeftTeam
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: RepaintBoundary(
                key: ValueKey('battle.characterSlot.repaint.$teamSide.$i'),
                child: CharacterSlot(
                  character: team[i],
                  battleState: battleState,
                  isLeftTeam: isLeftTeam,
                  attackController: attackControllers[teamSide * 3 + i],
                  slotPopups: popups[teamSide * 3 + i] ?? const [],
                  animConfig: animConfig,
                  chargeMaxTicks: chargeMaxTicks,
                  beat: beat,
                  staggerWindowTicks: staggerWindowTicks,
                  slotKey: teamSide * 3 + i,
                  onPopupComplete: onPopupComplete,
                  hitFlashController: hitFlashControllers[teamSide * 3 + i],
                  flashColor: hitFlashColors[teamSide * 3 + i] ?? Colors.white,
                  // 待发态:存活敌头像可点选为目标 + 高亮提示。
                  onTap:
                      (onEnemyTap != null && pendingActive && team[i].isAlive)
                      ? () => onEnemyTap!(team[i].characterId)
                      : null,
                  hovered: hoveredEnemyId == team[i].characterId,
                  targetable: pendingActive && team[i].isAlive,
                  onHoverChanged:
                      (onEnemyHover != null && pendingActive && team[i].isAlive)
                      ? (hovering) =>
                            onEnemyHover!(team[i].characterId, hovering)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 单个角色槽：攻击动画包 + 头像 + 飘字（Stack 叠加，clipBehavior: none 允许溢出）。
class CharacterSlot extends StatelessWidget {
  final BattleCharacter character;
  // floor30 护法结界(Task 6):完整战场快照,透传给 CharacterAvatar 判定结界。
  final BattleState battleState;
  final bool isLeftTeam;
  final AnimationController attackController;
  final List<PopupEntry> slotPopups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  final Animation<double> beat;
  final int staggerWindowTicks;
  final int slotKey;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final AnimationController hitFlashController;
  final Color flashColor;
  // 两段点选:待发态下敌头像点选目标的回调(null=不可点);待发态高亮。
  final VoidCallback? onTap;
  final bool hovered;
  final bool targetable;
  final ValueChanged<bool>? onHoverChanged;

  const CharacterSlot({
    super.key,
    required this.character,
    required this.battleState,
    required this.isLeftTeam,
    required this.attackController,
    required this.slotPopups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.beat,
    required this.staggerWindowTicks,
    required this.slotKey,
    required this.onPopupComplete,
    required this.hitFlashController,
    required this.flashColor,
    this.onTap,
    this.hovered = false,
    this.targetable = false,
    this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    final avatarCore = Stack(
      clipBehavior: Clip.none,
      children: [
        CharacterAvatar(
          character: character,
          battleState: battleState,
          chargeMaxTicks: chargeMaxTicks,
          beat: beat,
          staggerWindowTicks: staggerWindowTicks,
          avatarSize: 92,
          barWidth: 140,
        ),
        if (targetable)
          Positioned(
            key: ValueKey('enemy_target_hint_${character.characterId}'),
            top: -4,
            right: -6,
            child: EnemyTargetHint(active: hovered),
          ),
      ],
    );
    Widget avatar = AttackAnimationWidget(
      animation: attackController,
      isLeftTeam: isLeftTeam,
      config: animConfig,
      child: HitFlash(
        animation: hitFlashController,
        color: flashColor,
        child: GlowAura(
          hovered: hovered,
          // 第六阶段：staggerTicksRemaining>0 → 破绽集火高亮（绛红脉动）。
          // 仅限敌方（isLeftTeam==false）；我方被硬直不显示集火指示。
          staggered: !isLeftTeam && character.staggerTicksRemaining > 0,
          characterId: character.characterId,
          child: avatarCore,
        ),
      ),
    );
    if (onTap != null) {
      avatar = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatar,
      );
    }
    if (onHoverChanged != null) {
      avatar = MouseRegion(
        onEnter: (_) => onHoverChanged!(true),
        onExit: (_) => onHoverChanged!(false),
        child: avatar,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        for (var i = 0; i < slotPopups.length; i++)
          _buildPopupPositioned(
            slotPopups[i],
            animConfig,
            slotKey,
            isLeftTeam,
            onPopupComplete,
          ),
      ],
    );
  }

  static Widget _buildPopupPositioned(
    PopupEntry entry,
    AnimationNumbers config,
    int slotKey,
    bool isLeftTeam,
    void Function(int, int) onComplete,
  ) {
    final placement = _popupPlacement(entry.anchor, isLeftTeam);
    return Positioned(
      top: placement.top,
      right: placement.right,
      bottom: placement.bottom,
      left: placement.left,
      child: Align(
        alignment: placement.alignment,
        child: Transform.rotate(
          angle: placement.rotation,
          child: IgnorePointer(
            child: DamagePopup(
              key: ValueKey(entry.id),
              data: entry.data,
              config: config,
              durationMsOverride: entry.popupDurationMs,
              onComplete: () => onComplete(slotKey, entry.id),
            ),
          ),
        ),
      ),
    );
  }

  static _PopupPlacement _popupPlacement(
    DamagePopupAnchor anchor,
    bool isLeftTeam,
  ) {
    if (isLeftTeam) {
      return switch (anchor) {
        DamagePopupAnchor.upperLeft => const _PopupPlacement(
          left: 12,
          top: -18,
          alignment: Alignment.centerLeft,
          rotation: -0.03,
        ),
        DamagePopupAnchor.upperRight => const _PopupPlacement(
          left: 56,
          top: -26,
          alignment: Alignment.centerLeft,
          rotation: 0.035,
        ),
        DamagePopupAnchor.centerBurst => const _PopupPlacement(
          left: 4,
          right: -92,
          top: 8,
          alignment: Alignment.center,
        ),
        DamagePopupAnchor.lowerLeft => const _PopupPlacement(
          left: 16,
          bottom: 24,
          alignment: Alignment.centerLeft,
          rotation: 0.03,
        ),
        DamagePopupAnchor.lowerRight => const _PopupPlacement(
          left: 58,
          bottom: 16,
          alignment: Alignment.centerLeft,
          rotation: -0.025,
        ),
      };
    }
    return switch (anchor) {
      DamagePopupAnchor.upperLeft => const _PopupPlacement(
        right: 56,
        top: -26,
        alignment: Alignment.centerRight,
        rotation: -0.04,
      ),
      DamagePopupAnchor.upperRight => const _PopupPlacement(
        right: 12,
        top: -18,
        alignment: Alignment.centerRight,
        rotation: 0.035,
      ),
      DamagePopupAnchor.centerBurst => const _PopupPlacement(
        left: -92,
        right: 4,
        top: 8,
        alignment: Alignment.center,
      ),
      DamagePopupAnchor.lowerLeft => const _PopupPlacement(
        right: 58,
        bottom: 16,
        alignment: Alignment.centerRight,
        rotation: 0.03,
      ),
      DamagePopupAnchor.lowerRight => const _PopupPlacement(
        right: 16,
        bottom: 24,
        alignment: Alignment.centerRight,
        rotation: -0.025,
      ),
    };
  }
}

class _PopupPlacement {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final Alignment alignment;
  final double rotation;

  const _PopupPlacement({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.alignment,
    this.rotation = 0,
  });
}

class EnemyTargetHint extends StatelessWidget {
  const EnemyTargetHint({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? WuxiaColors.resultHighlight
            : WuxiaColors.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? WuxiaColors.textPrimary : WuxiaColors.resultHighlight,
          width: active ? 2 : 1,
        ),
        boxShadow: [
          if (active)
            BoxShadow(
              color: WuxiaColors.resultHighlight.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.my_location,
              size: 10,
              color: active ? WuxiaColors.panel : WuxiaColors.resultHighlight,
            ),
            const SizedBox(width: 3),
            Text(
              active ? UiStrings.skillTargetLocked : UiStrings.skillTargetable,
              style: TextStyle(
                color: active ? WuxiaColors.panel : WuxiaColors.resultHighlight,
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase 4 拖招表现层:角色头像光晕。
/// - [hovered](拖招悬停命中敌头像):静态浅金强光,优先级最高。
/// - 均不满足:无光晕,直接返回 child(等价旧 boxShadow 为空)。
class GlowAura extends StatefulWidget {
  final bool hovered;
  // 第六阶段：破绽窗口集火指示（staggerTicksRemaining>0）。
  final bool staggered;
  // 用于给破绽高亮 DecoratedBox 挂 Key，供 widget 测查找。
  final int characterId;
  final Widget child;
  const GlowAura({
    super.key,
    required this.hovered,
    required this.staggered,
    required this.characterId,
    required this.child,
  });

  @override
  State<GlowAura> createState() => _GlowAuraState();
}

class _GlowAuraState extends State<GlowAura>
    with SingleTickerProviderStateMixin {
  // eager 初始化(非 late):懒初始化会在非蓄势 slot 的 dispose() 才首次构造,
  // 此时树已 deactivate → createTicker 查 TickerMode 崩溃。
  late final AnimationController _pulse;

  // hovered 优先级最高(静态强光),只有「破绽且未被悬停」才脉动。
  // 第六阶段：破绽窗口驱动呼吸（绛红集火），优先级低于 hovered。
  bool get _pulsing => widget.staggered && !widget.hovered;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    if (_pulsing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GlowAura old) {
    super.didUpdateWidget(old);
    if (_pulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_pulsing && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 浅金静态强光(hovered) 优先;
    // 第六阶段：破绽窗口绛红脉动（集火指示）次之；都无则裸 child。
    if (widget.hovered) {
      return _box(WuxiaColors.resultHighlight, 0.85, 22.0, 4.0, widget.child);
    }
    if (!widget.staggered) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        // 破绽窗口：绛红呼吸脉动（集火指示），水墨克制——稍弱于蓄势强光。
        return KeyedSubtree(
          key: ValueKey('stagger_highlight_${widget.characterId}'),
          child: _box(
            WuxiaColors.gangMeng, // 绛红 = WuxiaColors.gangMeng（刚猛流派色 / 攻击色）
            0.35 + 0.35 * t, // alpha 0.35 → 0.70（克制，不刺眼）
            10.0 + 8.0 * t, // blur 10 → 18
            1.0 + 1.5 * t, // spread 1.0 → 2.5
            child!,
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _box(
    Color color,
    double alpha,
    double blur,
    double spread,
    Widget child,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}
