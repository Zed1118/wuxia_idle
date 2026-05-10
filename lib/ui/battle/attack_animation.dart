import 'package:flutter/material.dart';

/// 攻击三段式位移动画包装（phase1_tasks T15 §15.1）。
///
/// **无状态**：AnimationController 由外层 [_BattleScreenState] 创建和 dispose，
/// 本 widget 仅负责根据 [animation] 当前值计算偏移并应用 Transform.translate。
/// 这样 6 个角色槽的 controller 全部由 TickerProviderStateMixin 统一管理，
/// 不会出现泄漏。
///
/// 时序（对应 T15 §15.1）：
///   - [0, 0.375)  前冲  easeIn   （0 – 150 ms）
///   - [0.375, 0.625) 停顿        （150 – 250 ms）
///   - [0.625, 1.0]   后撤  easeOut（250 – 400 ms）
///
/// [isLeftTeam] = true 时向右冲（左队），false 时向左冲（右队）。
/// HP 条随 CharacterAvatar 一起在 child 树内，不分离——符合 T15 可能的坑说明。
class AttackAnimationWidget extends StatelessWidget {
  final Widget child;
  final bool isLeftTeam;
  final Animation<double> animation;
  final double rushOffsetPx;

  const AttackAnimationWidget({
    super.key,
    required this.child,
    required this.isLeftTeam,
    required this.animation,
    required this.rushOffsetPx,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final offset = _computeOffset(animation.value);
        return Transform.translate(
          offset: Offset(isLeftTeam ? offset : -offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// 三段式位移，严格按 T15 时序比例分段：
  ///   0–150ms / 150–250ms / 250–400ms → 0.375 / 0.625 / 1.0
  double _computeOffset(double t) {
    const phase1End = 150 / 400; // 0.375
    const phase2End = 250 / 400; // 0.625
    if (t < phase1End) {
      return Curves.easeIn.transform(t / phase1End) * rushOffsetPx;
    } else if (t < phase2End) {
      return rushOffsetPx;
    } else {
      final progress = (t - phase2End) / (1.0 - phase2End);
      return (1.0 - Curves.easeOut.transform(progress)) * rushOffsetPx;
    }
  }
}
