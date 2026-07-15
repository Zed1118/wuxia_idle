import 'package:flutter/material.dart';

import '../../domain/battle_state.dart';
import '../../../../data/numbers_config.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../attack_animation.dart';
import '../battle_layout_tokens.dart';
import '../battle_stage_geometry.dart';
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
    final slots = <_StageSlotData>[
      for (var i = 0; i < state.leftTeam.length; i++)
        _StageSlotData(
          teamSide: 0,
          slotIndex: i,
          teamSize: state.leftTeam.length,
          character: state.leftTeam[i],
        ),
      for (var i = 0; i < state.rightTeam.length; i++)
        _StageSlotData(
          teamSide: 1,
          slotIndex: i,
          teamSize: state.rightTeam.length,
          character: state.rightTeam[i],
        ),
    ]..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BattleLayoutTokens.stageHorizontalPadding,
        vertical: BattleLayoutTokens.stageVerticalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final baseWidth =
              (constraints.maxWidth * BattleLayoutTokens.stageWidthFraction)
                  .clamp(132.0, BattleLayoutTokens.stageMaxStandeeWidth);
          final baseHeight =
              (constraints.maxHeight * BattleLayoutTokens.stageHeightFraction)
                  .clamp(176.0, BattleLayoutTokens.stageMaxStandeeHeight);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final slot in slots)
                Builder(
                  builder: (context) {
                    final scale = battleStageScale(
                      slot.slotIndex,
                      slot.teamSize,
                    );
                    final width = baseWidth * scale;
                    final height = baseHeight * scale;
                    final left =
                        (slot.anchor.dx * constraints.maxWidth - width / 2)
                            .clamp(0.0, constraints.maxWidth - width);
                    final top =
                        (slot.anchor.dy * constraints.maxHeight - height / 2)
                            .clamp(0.0, constraints.maxHeight - height);
                    final slotKey = slot.teamSide * 3 + slot.slotIndex;
                    final isLeftTeam = slot.teamSide == 0;

                    return Positioned(
                      left: left,
                      top: top,
                      width: width,
                      height: height,
                      child: RepaintBoundary(
                        key: ValueKey(
                          'battle.characterSlot.repaint.${slot.teamSide}.${slot.slotIndex}',
                        ),
                        child: SizedBox(
                          key: ValueKey(
                            'battle.stageCharacter.${slot.teamSide}.${slot.slotIndex}',
                          ),
                          child: CharacterSlot(
                            character: slot.character,
                            battleState: state,
                            isLeftTeam: isLeftTeam,
                            attackController: attackControllers[slotKey],
                            slotPopups: popups[slotKey] ?? const [],
                            animConfig: animConfig,
                            chargeMaxTicks: chargeMaxTicks,
                            beat: beat,
                            staggerWindowTicks: staggerWindowTicks,
                            slotKey: slotKey,
                            onPopupComplete: onPopupComplete,
                            hitFlashController: hitFlashControllers[slotKey],
                            flashColor: hitFlashColors[slotKey] ?? Colors.white,
                            standeeWidth: width,
                            standeeHeight: height,
                            onTap:
                                (!isLeftTeam &&
                                    pendingActive &&
                                    slot.character.isAlive)
                                ? () => onEnemyTap(slot.character.characterId)
                                : null,
                            hovered:
                                hoveredEnemyId == slot.character.characterId,
                            targetable:
                                !isLeftTeam &&
                                pendingActive &&
                                slot.character.isAlive,
                            onHoverChanged:
                                (!isLeftTeam &&
                                    pendingActive &&
                                    slot.character.isAlive)
                                ? (hovering) => onEnemyHover(
                                    slot.character.characterId,
                                    hovering,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StageSlotData {
  const _StageSlotData({
    required this.teamSide,
    required this.slotIndex,
    required this.teamSize,
    required this.character,
  });

  final int teamSide;
  final int slotIndex;
  final int teamSize;
  final BattleCharacter character;

  Offset get anchor => battleStageAnchor(teamSide, slotIndex, teamSize);
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
  final double standeeWidth;
  final double standeeHeight;
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
    required this.standeeWidth,
    required this.standeeHeight,
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
          displayMode: CharacterDisplayMode.stageStandee,
          standeeWidth: standeeWidth,
          standeeHeight: standeeHeight,
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
      avatar = Semantics(
        button: true,
        enabled: character.isAlive,
        label: '${character.name} ${UiStrings.skillTargetable}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onHover: onHoverChanged,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            child: avatar,
          ),
        ),
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
