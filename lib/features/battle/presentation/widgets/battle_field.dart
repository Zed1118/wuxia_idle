import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/battle_state.dart';
import '../../../../data/numbers_config.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../attack_animation.dart';
import '../battle_action_template.dart';
import '../battle_layout_tokens.dart';
import '../battle_stage_geometry.dart';
import '../battle_standee_fusion.dart';
import '../../../../shared/theme/combat_typography.dart';
import '../battle_visual_roster.dart';
import '../battle_vfx_entries.dart';
import '../character_avatar.dart';
import '../damage_popup.dart';
import '../hit_flash.dart';

class BattleField extends StatefulWidget {
  final BattleState state;
  final BattleStageLayoutMode stageLayout;
  final List<AnimationController> attackControllers;
  final List<BattleActionTemplate> actionTemplates;
  final Map<int, List<PopupEntry>> popups;
  final AnimationNumbers animConfig;
  final int chargeMaxTicks;
  // 读秒环节拍 + 破绽窗口时长(供头像上蓄力/内伤/破绽环)。
  final Animation<double> beat;
  final int staggerWindowTicks;
  final void Function(int slotKey, int popupId) onPopupComplete;
  final List<AnimationController> hitFlashControllers;
  final Map<int, Color> hitFlashColors;
  // 两段点选:点敌头像出手回调；仅 [targetableEnemyIds] 中的敌人可点 + 高亮。
  final void Function(int enemyId) onEnemyTap;
  final Set<int> targetableEnemyIds;
  final int? hoveredEnemyId;
  final void Function(int enemyId, bool hovering) onEnemyHover;
  // 立绘大气融合档(B3 方案 B):由 battle_screen 按场景背景算好后整场统一下发。
  final BattleStandeeFusion standeeFusion;

  const BattleField({
    super.key,
    required this.state,
    this.stageLayout = BattleStageLayoutMode.standard,
    required this.attackControllers,
    required this.actionTemplates,
    required this.popups,
    required this.animConfig,
    required this.chargeMaxTicks,
    required this.beat,
    required this.staggerWindowTicks,
    required this.onPopupComplete,
    required this.hitFlashControllers,
    required this.hitFlashColors,
    required this.onEnemyTap,
    this.targetableEnemyIds = const <int>{},
    required this.hoveredEnemyId,
    required this.onEnemyHover,
    this.standeeFusion = BattleStandeeFusion.baseline,
  });

  @override
  State<BattleField> createState() => _BattleFieldState();
}

class _BattleFieldState extends State<BattleField> {
  Timer? _rotationTimer;
  late List<int?> _leftCharacterIds;
  late List<int?> _rightCharacterIds;

  @override
  void initState() {
    super.initState();
    _applyRoster(BattleVisualRoster.fromState(widget.state));
  }

  @override
  void didUpdateWidget(BattleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desired = BattleVisualRoster.fromState(widget.state);
    _leftCharacterIds = desired.leftSlots;

    final currentTeamIds = {
      for (final character in widget.state.rightTeam) character.characterId,
    };
    final isNewWave = _rightCharacterIds.whereType<int>().any(
      (characterId) => !currentTeamIds.contains(characterId),
    );
    final needsDefeatBeat =
        !isNewWave &&
        _hasDefeatedOutgoingCharacter(
          current: _rightCharacterIds,
          desired: desired.rightSlots,
        );

    if (!needsDefeatBeat) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
      _rightCharacterIds = desired.rightSlots;
      return;
    }
    _rotationTimer ??= Timer(
      Duration(milliseconds: widget.animConfig.damagePopupMs),
      () {
        if (!mounted) return;
        setState(() {
          _rightCharacterIds = BattleVisualRoster.fromState(
            widget.state,
          ).rightSlots;
          _rotationTimer = null;
        });
      },
    );
  }

  bool _hasDefeatedOutgoingCharacter({
    required List<int?> current,
    required List<int?> desired,
  }) {
    final rightById = {
      for (final character in widget.state.rightTeam)
        character.characterId: character,
    };
    for (var slotIndex = 0; slotIndex < current.length; slotIndex++) {
      final currentId = current[slotIndex];
      final desiredId = slotIndex < desired.length ? desired[slotIndex] : null;
      if (currentId == null || currentId == desiredId) {
        continue;
      }
      if (rightById[currentId]?.isAlive == false) return true;
    }
    return false;
  }

  void _applyRoster(BattleVisualRoster roster) {
    _leftCharacterIds = roster.leftSlots;
    _rightCharacterIds = roster.rightSlots;
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final stageLayout = widget.stageLayout;
    final standeeFusion = widget.standeeFusion;
    final attackControllers = widget.attackControllers;
    final actionTemplates = widget.actionTemplates;
    final popups = widget.popups;
    final animConfig = widget.animConfig;
    final chargeMaxTicks = widget.chargeMaxTicks;
    final beat = widget.beat;
    final staggerWindowTicks = widget.staggerWindowTicks;
    final onPopupComplete = widget.onPopupComplete;
    final hitFlashControllers = widget.hitFlashControllers;
    final hitFlashColors = widget.hitFlashColors;
    final onEnemyTap = widget.onEnemyTap;
    final targetableEnemyIds = widget.targetableEnemyIds;
    final hoveredEnemyId = widget.hoveredEnemyId;
    final onEnemyHover = widget.onEnemyHover;
    final leftById = {
      for (final character in state.leftTeam) character.characterId: character,
    };
    final rightById = {
      for (final character in state.rightTeam) character.characterId: character,
    };
    final leftTeamSize = _leftCharacterIds.length.clamp(1, 3);
    final rightTeamSize = _rightCharacterIds.length.clamp(1, 3);
    final visibleRightIds = _rightCharacterIds.whereType<int>().toSet();
    final queuedAliveEnemyCount = state.rightTeam
        .where(
          (character) =>
              character.isAlive &&
              !visibleRightIds.contains(character.characterId),
        )
        .length;
    final slots = <_StageSlotData>[
      for (var i = 0; i < _leftCharacterIds.length; i++)
        if (leftById[_leftCharacterIds[i]] != null)
          _StageSlotData(
            teamSide: 0,
            slotIndex: i,
            teamSize: leftTeamSize,
            character: leftById[_leftCharacterIds[i]]!,
            stageLayout: stageLayout,
          ),
      for (var i = 0; i < _rightCharacterIds.length; i++)
        if (rightById[_rightCharacterIds[i]] != null)
          _StageSlotData(
            teamSide: 1,
            slotIndex: i,
            teamSize: rightTeamSize,
            character: rightById[_rightCharacterIds[i]]!,
            stageLayout: stageLayout,
          ),
    ]..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BattleLayoutTokens.stageHorizontalPadding,
        vertical: BattleLayoutTokens.stageVerticalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return const SizedBox.shrink();
          }
          final baseWidth =
              (constraints.maxWidth * BattleLayoutTokens.stageWidthFraction)
                  .clamp(132.0, BattleLayoutTokens.stageMaxStandeeWidth);
          final baseHeight =
              (constraints.maxHeight * BattleLayoutTokens.stageHeightFraction)
                  .clamp(176.0, BattleLayoutTokens.stageMaxStandeeHeight);
          final layouts = <_StageSlotLayout>[
            for (final slot in slots)
              _StageSlotLayout.fromConstraints(
                slot: slot,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                baseWidth: baseWidth,
                baseHeight: baseHeight,
              ),
          ];

          return Stack(
            key: const ValueKey('battle.stageLayerStack'),
            clipBehavior: Clip.none,
            children: [
              if (stageLayout == BattleStageLayoutMode.massBattle &&
                  queuedAliveEnemyCount > 0)
                Positioned(
                  key: const ValueKey('battle.massBattleInkQueue'),
                  right: constraints.maxWidth * 0.02,
                  top: constraints.maxHeight * 0.08,
                  width: constraints.maxWidth * 0.18,
                  height: constraints.maxHeight * 0.70,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _MassBattleInkQueuePainter(
                        count: queuedAliveEnemyCount,
                      ),
                      key: ValueKey(
                        'battle.massBattleInkQueue.count.$queuedAliveEnemyCount',
                      ),
                    ),
                  ),
                ),
              // 人物层：保持按脚下深度排序，前景人物可以自然压住后排立绘。
              for (final layout in layouts)
                Builder(
                  builder: (context) {
                    final slot = layout.slot;
                    final width = layout.width;
                    final height = layout.height;
                    final slotKey = slot.teamSide * 3 + slot.slotIndex;
                    final isLeftTeam = slot.teamSide == 0;

                    return Positioned(
                      key: ValueKey(
                        'battle.stageCharacterLayer.${slot.teamSide}.${slot.slotIndex}',
                      ),
                      left: layout.left,
                      top: layout.top,
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
                            key: ValueKey(
                              'battle.stageCharacterId.${slot.character.characterId}',
                            ),
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
                            standeeFusion: standeeFusion,
                            showStageStatusOverlay: false,
                            inkMirror:
                                stageLayout ==
                                    BattleStageLayoutMode.innerDemon &&
                                !isLeftTeam,
                            clashTravelPx:
                                templateMovesToClash(actionTemplates[slotKey])
                                ? ((0.5 - slot.anchor.dx).abs() *
                                              constraints.maxWidth -
                                          width * 0.42)
                                      .clamp(0.0, constraints.maxWidth)
                                      .toDouble()
                                : 0,
                            onTap:
                                (!isLeftTeam &&
                                    targetableEnemyIds.contains(
                                      slot.character.characterId,
                                    ))
                                ? () => onEnemyTap(slot.character.characterId)
                                : null,
                            hovered:
                                hoveredEnemyId == slot.character.characterId,
                            targetable:
                                !isLeftTeam &&
                                targetableEnemyIds.contains(
                                  slot.character.characterId,
                                ),
                            onHoverChanged:
                                (!isLeftTeam &&
                                    targetableEnemyIds.contains(
                                      slot.character.characterId,
                                    ))
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
              // 状态层：全部人物画完后再统一叠加。状态牌仍跟随各自脚底锚点，
              // 但不会再被前景人物的透明立绘遮住。
              for (final layout in layouts)
                Positioned(
                  key: ValueKey(
                    'battle.stageStatusOverlay.${layout.slot.teamSide}.${layout.slot.slotIndex}',
                  ),
                  left: layout.left,
                  top: layout.top,
                  width: layout.width,
                  height: layout.height,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: layout.width,
                      height: layout.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          StageCharacterStatusOverlay(
                            character: layout.slot.character,
                            battleState: state,
                            width: layout.width,
                            height: layout.height,
                            teamSize: layout.slot.teamSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StageSlotLayout {
  const _StageSlotLayout({
    required this.slot,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory _StageSlotLayout.fromConstraints({
    required _StageSlotData slot,
    required double maxWidth,
    required double maxHeight,
    required double baseWidth,
    required double baseHeight,
  }) {
    final scale = battleStageScale(
      slot.slotIndex,
      slot.teamSize,
      isBoss: slot.character.isBoss,
    );
    final rawWidth = baseWidth * scale;
    final rawHeight = baseHeight * scale;
    final fitScale = [
      1.0,
      maxWidth / rawWidth,
      maxHeight / rawHeight,
    ].reduce((a, b) => a < b ? a : b);
    final width = (rawWidth * fitScale).clamp(0.0, maxWidth);
    final height = (rawHeight * fitScale).clamp(0.0, maxHeight);
    final left = (slot.anchor.dx * maxWidth - width / 2).clamp(
      0.0,
      maxWidth - width,
    );
    final bottomOverflow =
        height *
        battleStageBottomOverflowFraction(
          slot.teamSide,
          slot.slotIndex,
          slot.teamSize,
          mode: slot.stageLayout,
        );
    final top = (slot.anchor.dy * maxHeight - height / 2).clamp(
      0.0,
      maxHeight - height + bottomOverflow,
    );
    return _StageSlotLayout(
      slot: slot,
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }

  final _StageSlotData slot;
  final double left;
  final double top;
  final double width;
  final double height;
}

class _StageSlotData {
  const _StageSlotData({
    required this.teamSide,
    required this.slotIndex,
    required this.teamSize,
    required this.character,
    required this.stageLayout,
  });

  final int teamSide;
  final int slotIndex;
  final int teamSize;
  final BattleCharacter character;
  final BattleStageLayoutMode stageLayout;

  Offset get anchor =>
      battleStageAnchor(teamSide, slotIndex, teamSize, mode: stageLayout);
}

class _MassBattleInkQueuePainter extends CustomPainter {
  const _MassBattleInkQueuePainter({required this.count});

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final visibleCount = count.clamp(1, 4);
    for (var i = 0; i < visibleCount; i++) {
      final t = visibleCount == 1 ? 0.5 : i / (visibleCount - 1);
      final x = size.width * (0.24 + (i.isEven ? 0.10 : 0.48));
      final y = size.height * (0.18 + t * 0.60);
      final scale = 0.72 + t * 0.18;
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.22 + t * 0.12);
      canvas.drawCircle(Offset(x, y), 7 * scale, paint);
      final body = Path()
        ..moveTo(x, y + 7 * scale)
        ..quadraticBezierTo(
          x - 15 * scale,
          y + 30 * scale,
          x - 10 * scale,
          y + 64 * scale,
        )
        ..lineTo(x + 10 * scale, y + 64 * scale)
        ..quadraticBezierTo(x + 15 * scale, y + 30 * scale, x, y + 7 * scale)
        ..close();
      canvas.drawPath(body, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MassBattleInkQueuePainter oldDelegate) =>
      oldDelegate.count != count;
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
  final bool showStageStatusOverlay;
  final double clashTravelPx;
  final bool inkMirror;
  // 两段点选:待发态下敌头像点选目标的回调(null=不可点);待发态高亮。
  final VoidCallback? onTap;
  final bool hovered;
  final bool targetable;
  final ValueChanged<bool>? onHoverChanged;
  // 立绘大气融合档(B3 方案 B):按场景背景合成明度自适应,缺省为既有观感。
  final BattleStandeeFusion standeeFusion;

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
    this.showStageStatusOverlay = true,
    required this.clashTravelPx,
    this.inkMirror = false,
    this.onTap,
    this.hovered = false,
    this.targetable = false,
    this.onHoverChanged,
    this.standeeFusion = BattleStandeeFusion.baseline,
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
          showStageStatusOverlay: showStageStatusOverlay,
          inkMirror: inkMirror,
          standeeFusion: standeeFusion,
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
      rushOffsetPx: clashTravelPx,
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
    // 同带错层:top 定位向上、bottom 定位也向上(加 bottom),不侵占邻槽横向空间。
    final shift = entry.stackShift;
    return Positioned(
      top: placement.top == null ? null : placement.top! - shift,
      right: placement.right,
      bottom: placement.bottom == null ? null : placement.bottom! + shift,
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
    return Transform.rotate(
      angle: active ? -0.025 : 0.018,
      child: DecoratedBox(
        key: const ValueKey('battle.targetHint.inkSeal'),
        decoration: BoxDecoration(
          color: active ? const Color(0xE6842F25) : const Color(0xE6292722),
          border: Border.all(
            color: active ? const Color(0xFFD1AC66) : const Color(0xFF806B49),
            width: active ? 1.4 : 1,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
            if (active)
              const BoxShadow(
                color: Color(0x42D1AC66),
                blurRadius: 9,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Text(
            active ? UiStrings.skillTargetLocked : UiStrings.skillTargetable,
            style: const TextStyle(
              color: WuxiaUi.paper2,
              fontFamily: BattleTypography.displayFamily,
              fontFamilyFallback: BattleTypography.displayFallback,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: Color(0x80000000),
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 角色状态表现层。
/// - [hovered](点选目标命中敌方):轻微放大,优先级最高。
/// - [staggered]:脚下绛红破绽印,避免整个人物槽位出现矩形光框。
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
      return Transform.scale(scale: 1.025, child: widget.child);
    }
    if (!widget.staggered) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        // 破绽窗口：绛红呼吸脉动（集火指示）。只落在脚下，
        // 不再对整个 CharacterSlot 施加 boxShadow，以免暴露矩形组件边界。
        return KeyedSubtree(
          key: ValueKey('stagger_highlight_${widget.characterId}'),
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _StaggerGroundSealPainter(pulse: t),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _StaggerGroundSealPainter extends CustomPainter {
  const _StaggerGroundSealPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.82);
    final width = size.width * (0.46 + pulse * 0.04);
    final height = size.height * (0.045 + pulse * 0.008);
    final sealRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    canvas.drawOval(
      sealRect,
      Paint()
        ..color = WuxiaColors.gangMeng.withValues(alpha: 0.12 + pulse * 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + pulse * 3),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1 + pulse * 0.7
      ..color = WuxiaColors.gangMeng.withValues(alpha: 0.48 + pulse * 0.18);
    canvas.drawArc(sealRect, 3.34, 2.32, false, ringPaint);
    canvas.drawArc(sealRect.deflate(3), 0.20, 2.18, false, ringPaint);

    final fleckPaint = Paint()
      ..color = WuxiaColors.gangMeng.withValues(alpha: 0.35 + pulse * 0.18);
    canvas.drawCircle(
      Offset(center.dx - width * 0.42, center.dy - height * 0.55),
      1.1 + pulse * 0.6,
      fleckPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.36, center.dy + height * 0.32),
      0.8 + pulse * 0.5,
      fleckPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StaggerGroundSealPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
