import 'package:flutter/material.dart';

import '../../data/numbers_config.dart';

/// 攻击三段式位移动画包装（phase1_tasks T15 §15.1）。
///
/// **无状态**：AnimationController 由外层 [_BattleScreenState] 创建和 dispose，
/// 本 widget 仅负责根据 [animation] 当前值计算偏移并应用 Transform.translate。
/// 这样 6 个角色槽的 controller 全部由 TickerProviderStateMixin 统一管理，
/// 不会出现泄漏。
///
/// 时序按 [config] 三段时长比例分段（不写死，调 yaml 即可调整）：
///   - [0, rushMs/total)              前冲 easeIn
///   - [rushMs/total, (rush+hold)/total) 停顿
///   - [(rush+hold)/total, 1.0]       后撤 easeOut
///
/// [isLeftTeam] = true 时向右冲（左队），false 时向左冲（右队）。
/// HP 条随 CharacterAvatar 一起在 child 树内，不分离——符合 T15 可能的坑说明。
class AttackAnimationWidget extends StatelessWidget {
  final Widget child;
  final bool isLeftTeam;
  final Animation<double> animation;
  final AnimationNumbers config;

  const AttackAnimationWidget({
    super.key,
    required this.child,
    required this.isLeftTeam,
    required this.animation,
    required this.config,
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

  double _computeOffset(double t) {
    final total = config.attackTotalMs;
    final phase1End = config.attackRushMs / total;
    final phase2End = (config.attackRushMs + config.attackHoldMs) / total;
    final rushPx = config.attackRushOffsetPx;
    if (t < phase1End) {
      return Curves.easeIn.transform(t / phase1End) * rushPx;
    } else if (t < phase2End) {
      return rushPx;
    } else {
      final progress = (t - phase2End) / (1.0 - phase2End);
      return (1.0 - Curves.easeOut.transform(progress)) * rushPx;
    }
  }
}
