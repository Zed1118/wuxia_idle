import 'package:flutter/material.dart';

import '../../data/numbers_config.dart';
import '../strings.dart';
import '../theme/colors.dart';

/// 伤害飘字类型（phase1_tasks T15 §15.2）。
enum PopupType { normal, critical, dodge }

/// 单次伤害飘字的数据载体。
///
/// [id] 用于 Map key + widget key，保证同一角色多个飘字不混淆。
class DamagePopupData {
  final int id;
  final String text;
  final PopupType type;
  final bool hasCounterUp;
  final bool hasCounterDown;

  const DamagePopupData({
    required this.id,
    required this.text,
    required this.type,
    this.hasCounterUp = false,
    this.hasCounterDown = false,
  });
}

/// 伤害飘字动画 Widget（phase1_tasks T15 §15.2）。
///
/// 向上漂浮 + 后半段淡出，共 [config.damagePopupMs] ms。
/// 动画完成后调用 [onComplete]，由父层移除该 widget。
///
/// 使用 [SingleTickerProviderStateMixin] 管理 AnimationController，
/// [dispose] 时自动释放——不会泄漏 ticker。
class DamagePopup extends StatefulWidget {
  final DamagePopupData data;
  final AnimationNumbers config;
  final VoidCallback onComplete;

  const DamagePopup({
    super.key,
    required this.data,
    required this.config,
    required this.onComplete,
  });

  @override
  State<DamagePopup> createState() => _DamagePopupState();
}

class _DamagePopupState extends State<DamagePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _yOffset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.config.damagePopupMs),
    );
    _yOffset = Tween<double>(
      begin: 0,
      end: -widget.config.damagePopupFloatPx,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // 后半段才开始淡出，前半段保持不透明
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yOffset.value),
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        );
      },
      child: _PopupContent(
        data: widget.data,
        criticalFontScale: widget.config.criticalFontScale,
      ),
    );
  }
}

/// 飘字内容（文字 + 克制标记）。独立为 StatelessWidget 作为 AnimatedBuilder child
/// 避免每帧重建 Row/Text 树。
class _PopupContent extends StatelessWidget {
  final DamagePopupData data;
  final double criticalFontScale;
  const _PopupContent({
    required this.data,
    required this.criticalFontScale,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color(data.type);
    const baseFontSize = 18.0;
    final fontSize =
        data.type == PopupType.critical ? baseFontSize * criticalFontScale : baseFontSize;
    final hasCounter = data.hasCounterUp || data.hasCounterDown;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                blurRadius: 2,
                color: Color(0xCC000000),
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        if (hasCounter) ...[
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              data.hasCounterUp ? UiStrings.counterUp : UiStrings.counterDown,
              style: TextStyle(
                fontSize: fontSize * 0.65,
                color: data.hasCounterUp
                    ? WuxiaColors.popupCritical
                    : WuxiaColors.popupDodge,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Color _color(PopupType type) => switch (type) {
        PopupType.normal => WuxiaColors.popupNormal,
        PopupType.critical => WuxiaColors.popupCritical,
        PopupType.dodge => WuxiaColors.popupDodge,
      };
}
