import 'package:flutter/material.dart';

import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/theme/colors.dart';

/// 出版美术 B2:出招是否该弹大招题字(ultimate 或人剑合一)。纯函数便于单测。
bool isUltimateCaptionSkill(SkillDef? skill) =>
    skill != null &&
    (skill.type == SkillType.ultimate || skill.type == SkillType.jointSkill);

/// 大招题字视觉(纯展示,无动画)。供动画 overlay 与视觉验收路由复用。
/// 玩家方暖金、敌方绛红，水墨大字 + 墨色描边。
class UltimateCaptionContent extends StatelessWidget {
  final String name;
  final bool isEnemy;

  const UltimateCaptionContent({
    super.key,
    required this.name,
    required this.isEnemy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isEnemy ? WuxiaColors.gangMeng : WuxiaColors.resultHighlight;
    return Align(
      alignment: const Alignment(0, -0.45), // 中部偏上
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0x99000000), // 淡墨团衬底
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: accent,
            fontSize: 56,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            shadows: const [
              Shadow(blurRadius: 14, color: Color(0xCC000000), offset: Offset(2, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 非阻塞大招题字 overlay:Stack 顶层,[show] 触发淡入→停留→淡出,自管生命周期。
/// 1.2s 内再 show 覆盖前者(单实例,latest wins)。idle 时渲染 SizedBox.shrink。
class UltimateCaptionOverlay extends StatefulWidget {
  const UltimateCaptionOverlay({super.key});

  @override
  State<UltimateCaptionOverlay> createState() => UltimateCaptionOverlayState();
}

class UltimateCaptionOverlayState extends State<UltimateCaptionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _name;
  bool _isEnemy = false;

  // 250ms 淡入 + 1200ms 停留 + 350ms 淡出 = 1800ms 总时长
  static const _total = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _name = null);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 触发题字。覆盖语义:重置动画 + 换文字。
  void show(String name, {required bool isEnemy}) {
    setState(() {
      _name = name;
      _isEnemy = isEnemy;
    });
    _ctrl.forward(from: 0.0);
  }

  // 0→0.14 淡入(opacity 0→1) / 0.14→0.80 停留(1) / 0.80→1 淡出(1→0)
  double get _opacity {
    final t = _ctrl.value;
    if (t < 0.14) return t / 0.14;
    if (t > 0.80) return (1.0 - t) / 0.20;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_name == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: UltimateCaptionContent(name: _name!, isEnemy: _isEnemy),
        ),
      ),
    );
  }
}
