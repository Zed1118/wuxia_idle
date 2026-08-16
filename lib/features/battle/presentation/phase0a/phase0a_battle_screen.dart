import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../application/phase0a/phase0a_player_input_adapter.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../hp_bar.dart';
import 'phase0a_battle_controller.dart';
import 'phase0a_presentation_tokens.dart';
import 'phase0a_skill_seals.dart';
import 'phase0a_stage.dart';
import 'phase0a_vfx_controller.dart';
import 'phase0a_visual_roster.dart';

final class Phase0aBattleScreen extends StatefulWidget {
  const Phase0aBattleScreen({super.key, required this.controller});

  final Phase0aBattleController controller;

  @override
  State<Phase0aBattleScreen> createState() => _Phase0aBattleScreenState();
}

class _Phase0aBattleScreenState extends State<Phase0aBattleScreen> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'phase0a-battle-input');
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant Phase0aBattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final command = switch (key) {
      LogicalKeyboardKey.keyA => const Phase0aPlayerCommand(left: true),
      LogicalKeyboardKey.keyD => const Phase0aPlayerCommand(right: true),
      LogicalKeyboardKey.keyW => const Phase0aPlayerCommand(up: true),
      LogicalKeyboardKey.keyS => const Phase0aPlayerCommand(down: true),
      LogicalKeyboardKey.keyJ => const Phase0aPlayerCommand(attack: true),
      LogicalKeyboardKey.keyQ => const Phase0aPlayerCommand(gather: true),
      LogicalKeyboardKey.keyR => const Phase0aPlayerCommand(clear: true),
      _ => null,
    };
    if (command == null) return KeyEventResult.ignored;
    widget.controller.enqueue(command);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: WuxiaUi.ink,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final stage = Phase0aStage(viewport: size);
            return Stack(
              key: const ValueKey('phase0a_battle_screen'),
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/scenes/battle_mountain_pass_stage_v2.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
                const ColoredBox(color: Color(0x380F0E0B)),
                const CustomPaint(painter: _StageWashPainter()),
                ..._buildActors(controller, stage),
                _FeedbackLayer(controller: controller, stage: stage),
                _PlayerHud(controller: controller),
                Positioned(
                  right: Phase0aPresentationTokens.skillHudRight,
                  bottom: Phase0aPresentationTokens.skillHudBottom,
                  child: Phase0aSkillSeals(
                    gatherSlot: _slot(controller.state, 'gather'),
                    clearSlot: _slot(controller.state, 'clear'),
                    qiCurrent: controller.state.player.qiCurrent,
                    onGather: () => controller.enqueue(
                      const Phase0aPlayerCommand(gather: true),
                    ),
                    onClear: () => controller.enqueue(
                      const Phase0aPlayerCommand(clear: true),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildActors(
    Phase0aBattleController controller,
    Phase0aStage stage,
  ) {
    final actors = stage.sortActors([
      controller.state.player,
      ...controller.state.enemies,
    ]);
    return [
      for (final actor in actors) _positionedActor(controller, stage, actor),
    ];
  }

  Widget _positionedActor(
    Phase0aBattleController controller,
    Phase0aStage stage,
    Phase0aActor actor,
  ) {
    final foot = stage.worldToScreen(actor.position);
    final scale = stage.depthScale(actor.position.y);
    final width = Phase0aPresentationTokens.actorWidth * scale;
    final height = Phase0aPresentationTokens.actorHeight * scale;
    return Positioned(
      left: foot.dx - width / 2,
      top: foot.dy - height,
      width: width,
      height: height,
      child: _ActorStandee(
        key: ValueKey('phase0a_standee_${actor.id}'),
        actor: actor,
        visual: controller.roster.visualFor(actor.id),
      ),
    );
  }

  static Phase0aSkillSlot _slot(Phase0aArenaState state, String id) =>
      state.skillSlots.firstWhere((slot) => slot.slot == id);
}

class _ActorStandee extends StatelessWidget {
  const _ActorStandee({super.key, required this.actor, required this.visual});

  final Phase0aActor actor;
  final Phase0aActorVisual visual;

  @override
  Widget build(BuildContext context) {
    final enemy = actor.side == Phase0aSide.enemy;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: Phase0aPresentationTokens.depthShadowWidth,
            height: Phase0aPresentationTokens.depthShadowHeight,
            decoration: BoxDecoration(
              color: WuxiaUi.ink.withValues(
                alpha: Phase0aPresentationTokens.depthShadowOpacity,
              ),
              borderRadius: BorderRadius.circular(
                Phase0aPresentationTokens.depthShadowHeight,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          height: Phase0aPresentationTokens.actorImageHeight,
          left: 0,
          right: 0,
          child: Image.asset(
            visual.assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
        if (enemy)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  visual.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WuxiaUi.paper,
                    fontSize: Phase0aPresentationTokens.actorNameFontSize,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: WuxiaUi.ink, blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: Phase0aPresentationTokens.actorLabelGap),
                SizedBox(
                  width: Phase0aPresentationTokens.actorHpWidth,
                  child: HpBar(
                    key: ValueKey('phase0a_hp_${actor.id}'),
                    current: actor.currentHealth,
                    max: actor.maxHealth,
                    height: Phase0aPresentationTokens.actorHpHeight,
                    tightLabel: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlayerHud extends StatelessWidget {
  const _PlayerHud({required this.controller});

  final Phase0aBattleController controller;

  @override
  Widget build(BuildContext context) {
    final player = controller.state.player;
    return Positioned(
      key: const ValueKey('phase0a_player_hud'),
      left: Phase0aPresentationTokens.hudInset,
      bottom: Phase0aPresentationTokens.hudInset,
      width: Phase0aPresentationTokens.hudWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(
            alpha: Phase0aPresentationTokens.hudPaperOpacity,
          ),
          border: Border.all(
            color: WuxiaUi.ink,
            width: Phase0aPresentationTokens.hudBorderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Phase0aPresentationTokens.hudPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.roster.nameOf(player.id),
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Phase0aPresentationTokens.hudGap),
              HpBar(
                key: const ValueKey('phase0a_hp_player'),
                current: player.currentHealth,
                max: player.maxHealth,
                height: Phase0aPresentationTokens.hudBarHeight,
                labelPrefix: '${UiStrings.phase0aPlayerHealth} ',
                tightLabel: true,
              ),
              const SizedBox(height: Phase0aPresentationTokens.hudGap),
              HpBar(
                key: const ValueKey('phase0a_player_qi'),
                current: player.qiCurrent,
                max: player.qiMax,
                height: Phase0aPresentationTokens.hudBarHeight,
                isInternalForce: true,
                labelPrefix: '${UiStrings.phase0aPlayerQi} ',
                tightLabel: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackLayer extends StatelessWidget {
  const _FeedbackLayer({required this.controller, required this.stage});

  final Phase0aBattleController controller;
  final Phase0aStage stage;

  @override
  Widget build(BuildContext context) {
    final entries = controller.feedback;
    final children = <Widget>[];
    var popupIndex = 0;
    for (final entry in entries) {
      switch (entry.kind) {
        case Phase0aVfxKind.damagePopup:
          children.add(_damagePopup(entry, popupIndex++));
        case Phase0aVfxKind.palmTrail:
          children.add(
            const Center(
              child: CustomPaint(
                key: ValueKey('phase0a_palm_trail'),
                size: Size.square(Phase0aPresentationTokens.vfxCenterSize),
                painter: _InkEffectPainter(_InkEffect.palm),
              ),
            ),
          );
        case Phase0aVfxKind.gatherVortex:
          children.add(
            const Center(
              child: CustomPaint(
                key: ValueKey('phase0a_gather_vortex'),
                size: Size.square(Phase0aPresentationTokens.vfxCenterSize),
                painter: _InkEffectPainter(_InkEffect.gather),
              ),
            ),
          );
        case Phase0aVfxKind.clearBurst:
          children.add(
            const Center(
              child: CustomPaint(
                key: ValueKey('phase0a_clear_burst'),
                size: Size.square(Phase0aPresentationTokens.vfxCenterSize),
                painter: _InkEffectPainter(_InkEffect.clear),
              ),
            ),
          );
        case Phase0aVfxKind.defeatInk:
          children.add(
            const Center(
              child: CustomPaint(
                size: Size.square(Phase0aPresentationTokens.vfxCenterSize),
                painter: _InkEffectPainter(_InkEffect.defeat),
              ),
            ),
          );
        case Phase0aVfxKind.waveBanner:
          children.add(_waveBanner(entry));
        case Phase0aVfxKind.outcomeSeal:
          break;
        case Phase0aVfxKind.gatherPull:
          break;
      }
    }
    if (controller.outcome != Phase0aBattleOutcome.ongoing) {
      children.add(_outcomeSeal(controller.outcome));
    }
    return Positioned.fill(
      child: IgnorePointer(child: Stack(children: children)),
    );
  }

  Widget _damagePopup(Phase0aVfxEntry entry, int index) {
    final actor = _actor(entry.targetId);
    final anchor = actor == null
        ? stage.safeRect.center
        : stage.worldToScreen(actor.position);
    return Positioned(
      key: ValueKey('phase0a_popup_$index'),
      left: anchor.dx,
      top:
          anchor.dy -
          Phase0aPresentationTokens.actorHeight -
          index * Phase0aPresentationTokens.vfxPopupGap,
      child: Transform.translate(
        offset: const Offset(-12, 0),
        child: Text(
          '${entry.damage}',
          style: TextStyle(
            color: entry.isCritical ? WuxiaUi.jiang : WuxiaUi.ink,
            fontSize: Phase0aPresentationTokens.vfxPopupFontSize,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: WuxiaUi.paper, blurRadius: 1),
              Shadow(color: WuxiaUi.paper, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Phase0aActor? _actor(String? id) {
    if (id == null) return null;
    if (controller.state.player.id == id) return controller.state.player;
    for (final enemy in controller.state.enemies) {
      if (enemy.id == id) return enemy;
    }
    return null;
  }

  Widget _waveBanner(Phase0aVfxEntry entry) => Positioned(
    key: const ValueKey('phase0a_wave_banner'),
    top: Phase0aPresentationTokens.vfxBannerTop,
    left: (stage.viewport.width - Phase0aPresentationTokens.vfxBannerWidth) / 2,
    width: Phase0aPresentationTokens.vfxBannerWidth,
    height: Phase0aPresentationTokens.vfxBannerHeight,
    child: CustomPaint(
      painter: const _PaperBannerPainter(),
      child: Center(
        child: Text(
          UiStrings.phase0aWaveBanner(entry.waveIndex!, entry.waveTotal!),
          style: const TextStyle(
            color: WuxiaUi.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    ),
  );

  Widget _outcomeSeal(Phase0aBattleOutcome outcome) => Center(
    child: CustomPaint(
      key: const ValueKey('phase0a_outcome_seal'),
      size: const Size.square(Phase0aPresentationTokens.vfxOutcomeSize),
      painter: const _OutcomeSealPainter(),
      child: SizedBox.square(
        dimension: Phase0aPresentationTokens.vfxOutcomeSize,
        child: Center(
          child: Text(
            outcome == Phase0aBattleOutcome.victory
                ? UiStrings.phase0aVictorySeal
                : UiStrings.phase0aDefeatSeal,
            style: const TextStyle(
              color: WuxiaUi.paper,
              fontSize: Phase0aPresentationTokens.vfxOutcomeFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

enum _InkEffect { palm, gather, clear, defeat }

class _InkEffectPainter extends CustomPainter {
  const _InkEffectPainter(this.effect);

  final _InkEffect effect;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ink = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth;
    final wash = Paint()
      ..color = WuxiaUi.jiang.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth;
    switch (effect) {
      case _InkEffect.palm:
        final path = Path()
          ..moveTo(size.width * 0.08, size.height * 0.62)
          ..quadraticBezierTo(
            size.width * 0.43,
            size.height * 0.18,
            size.width * 0.92,
            size.height * 0.42,
          )
          ..quadraticBezierTo(
            size.width * 0.55,
            size.height * 0.52,
            size.width * 0.16,
            size.height * 0.78,
          );
        canvas.drawPath(path, ink);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size.width * 0.24),
          -1.2,
          1.8,
          false,
          wash,
        );
      case _InkEffect.gather:
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: center,
              radius: size.width * (0.16 + i * 0.09),
            ),
            i * 0.8,
            4.7,
            false,
            i.isEven ? ink : wash,
          );
        }
      case _InkEffect.clear:
        for (var i = 0; i < Phase0aPresentationTokens.vfxSpokeCount; i++) {
          final angle =
              i * math.pi * 2 / Phase0aPresentationTokens.vfxSpokeCount;
          final start = Offset(
            center.dx + math.cos(angle) * size.width * 0.10,
            center.dy + math.sin(angle) * size.height * 0.10,
          );
          final end = Offset(
            center.dx + math.cos(angle) * size.width * 0.44,
            center.dy + math.sin(angle) * size.height * 0.44,
          );
          canvas.drawLine(start, end, i.isEven ? ink : wash);
        }
        canvas.drawCircle(center, size.width * 0.24, ink);
      case _InkEffect.defeat:
        for (var i = 0; i < Phase0aPresentationTokens.vfxSpokeCount; i++) {
          final angle =
              i * math.pi * 2 / Phase0aPresentationTokens.vfxSpokeCount;
          final point = Offset(
            center.dx + math.cos(angle) * size.width * 0.31,
            center.dy + math.sin(angle) * size.height * 0.22,
          );
          canvas.drawCircle(
            point,
            i.isEven ? 5 : 3,
            ink..style = PaintingStyle.fill,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _InkEffectPainter oldDelegate) =>
      oldDelegate.effect != effect;
}

class _StageWashPainter extends CustomPainter {
  const _StageWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          WuxiaUi.paper.withValues(alpha: 0.08),
          WuxiaUi.ink.withValues(
            alpha: Phase0aPresentationTokens.stageShadeOpacity,
          ),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _StageWashPainter oldDelegate) => false;
}

class _PaperBannerPainter extends CustomPainter {
  const _PaperBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.24)
      ..lineTo(size.width * 0.06, 0)
      ..lineTo(size.width * 0.94, size.height * 0.08)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width * 0.90, size.height)
      ..lineTo(size.width * 0.08, size.height * 0.90)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = WuxiaUi.paper.withValues(alpha: 0.92),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = WuxiaUi.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Phase0aPresentationTokens.hudBorderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperBannerPainter oldDelegate) => false;
}

class _OutcomeSealPainter extends CustomPainter {
  const _OutcomeSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.92),
    );
    canvas.drawRect(
      rect.deflate(8),
      Paint()
        ..color = WuxiaUi.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _OutcomeSealPainter oldDelegate) => false;
}
