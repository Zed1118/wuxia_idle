part of 'battle_playback_controller.dart';

/// 播放模块拥有的命中特写与屏震变换。
class BattlePlaybackMotion extends StatelessWidget {
  const BattlePlaybackMotion({
    super.key,
    required this.controller,
    required this.child,
  });

  final BattlePlaybackController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller._closeupCtrl,
      builder: (context, child) {
        final scale =
            1.0 +
            (controller._animConfig.hitTier.closeupScale - 1.0) *
                controller._closeupCtrl.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedBuilder(
        animation: controller._shakeCtrl,
        builder: (context, child) {
          return Transform.translate(
            offset: screenShakeOffset(
              t: controller._shakeCtrl.value,
              amplitude: controller._impactShakeAmplitude,
            ),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

/// 播放模块拥有的战场动画资源与 VFX 层。
class BattlePlaybackField extends StatelessWidget {
  const BattlePlaybackField({
    super.key,
    required this.controller,
    required this.state,
    required this.chargeMaxTicks,
    required this.staggerWindowTicks,
    required this.onEnemyTap,
    required this.pendingActive,
    required this.hoveredEnemyId,
    required this.onEnemyHover,
  });

  final BattlePlaybackController controller;
  final BattleState state;
  final int chargeMaxTicks;
  final int staggerWindowTicks;
  final void Function(int enemyId) onEnemyTap;
  final bool pendingActive;
  final int? hoveredEnemyId;
  final void Function(int enemyId, bool hovering) onEnemyHover;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BattleField(
          state: state,
          attackControllers: controller._attackControllers,
          actionTemplates: controller._actionTemplates,
          popups: controller._popups,
          animConfig: controller._animConfig,
          chargeMaxTicks: chargeMaxTicks,
          beat: controller._beatCtrl,
          staggerWindowTicks: staggerWindowTicks,
          onPopupComplete: controller.removePopup,
          hitFlashControllers: controller._hitFlashControllers,
          hitFlashColors: controller._hitFlashColors,
          onEnemyTap: onEnemyTap,
          pendingActive: pendingActive,
          hoveredEnemyId: hoveredEnemyId,
          onEnemyHover: onEnemyHover,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ProjectileLayer(trails: controller._activeTrails),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: EffectLayer(effects: controller._activeEffects),
          ),
        ),
      ],
    );
  }
}

/// 播放模块拥有的命令式全屏 overlay 宿主。
class BattlePlaybackOverlays extends StatelessWidget {
  const BattlePlaybackOverlays({super.key, required this.controller});

  final BattlePlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ScreenFlashOverlay(key: controller._screenFlashKey),
        UltimateCaptionOverlay(key: controller._ultimateCaptionKey),
        ImpactGlyphOverlay(key: controller._impactGlyphKey),
      ],
    );
  }
}
