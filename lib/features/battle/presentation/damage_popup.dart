import 'package:flutter/material.dart';

import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 伤害飘字类型（phase1_tasks T15 §15.2）。
enum PopupType { normal, critical, dodge }

/// 单次伤害飘字的数据载体。
///
/// [id] 用于 Map key + widget key，保证同一角色多个飘字不混淆。
/// [hasSwordSong] = P1.1 候选 3-c,attacker 武器达 xinJianTongLing 共鸣 +
/// 本次暴击时为 true → 浮字旁追加「✦剑鸣」红字。
class DamagePopupData {
  final int id;
  final String text;
  final PopupType type;
  final bool hasCounterUp;
  final bool hasCounterDown;
  final bool hasSwordSong;

  const DamagePopupData({
    required this.id,
    required this.text,
    required this.type,
    this.hasCounterUp = false,
    this.hasCounterDown = false,
    this.hasSwordSong = false,
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

  /// 飘字时长覆写(ms):非空时替代 [config.damagePopupMs],用于快档按拍间隔
  /// clamp 防跨拍重叠(见 [AnimationNumbers.effectivePopupMs])。null 走配置默认。
  final int? durationMsOverride;

  const DamagePopup({
    super.key,
    required this.data,
    required this.config,
    required this.onComplete,
    this.durationMsOverride,
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
      duration: Duration(
        milliseconds: widget.durationMsOverride ?? widget.config.damagePopupMs,
      ),
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
          child: Opacity(opacity: _opacity.value, child: child),
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
  const _PopupContent({required this.data, required this.criticalFontScale});

  @override
  Widget build(BuildContext context) {
    const baseFontSize = 30.0;
    final fontSize = data.type == PopupType.critical
        ? baseFontSize * criticalFontScale
        : baseFontSize;
    final hasSideMark = data.hasSwordSong;
    final damageText = data.type == PopupType.critical
        ? _CriticalDamageText(text: data.text, fontSize: fontSize)
        : Text(
            data.text,
            style: TextStyle(
              color: _color(data.type),
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  blurRadius: 0,
                  color: Color(0xFFF8E7C3),
                  offset: Offset(1.6, 0),
                ),
                Shadow(
                  blurRadius: 0,
                  color: Color(0xFFF8E7C3),
                  offset: Offset(-1.6, 0),
                ),
                Shadow(
                  blurRadius: 0,
                  color: Color(0xFFF8E7C3),
                  offset: Offset(0, 1.6),
                ),
                Shadow(
                  blurRadius: 0,
                  color: Color(0xFFF8E7C3),
                  offset: Offset(0, -1.6),
                ),
                Shadow(
                  blurRadius: 2,
                  color: Color(0xAA2A1C12),
                  offset: Offset(1, 1),
                ),
              ],
            ),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.type == PopupType.critical)
          SizedBox(
            width: hasSideMark ? 160 : 218,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: CustomPaint(
                painter: const _CriticalBrushPainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
                  child: damageText,
                ),
              ),
            ),
          )
        else
          damageText,
        // P1.1 候选 3-c:暴击 + 主修武器 xinJianTongLing → 「✦剑鸣」浮字。
        if (data.hasSwordSong) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              UiStrings.swordSongHint,
              style: TextStyle(
                fontSize: fontSize * 0.65,
                color: WuxiaColors.popupCritical,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Color _color(PopupType type) => switch (type) {
    PopupType.normal => const Color(0xFF211A13),
    PopupType.critical => const Color(0xFFB72218),
    PopupType.dodge => WuxiaColors.popupDodge,
  };
}

class _CriticalDamageText extends StatelessWidget {
  const _CriticalDamageText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseCriticalDamage(text);
    if (parsed == null) {
      return Text(text, style: _numberStyle(fontSize));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 3),
          child: Text(
            UiStrings.criticalLabel,
            style: TextStyle(
              color: const Color(0xFF7E1610),
              fontSize: fontSize * 0.43,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  blurRadius: 0,
                  color: Color(0xFFFFE4C6),
                  offset: Offset(1, 0),
                ),
                Shadow(
                  blurRadius: 1,
                  color: Color(0x77300000),
                  offset: Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
        ),
        Text(parsed.damage, style: _numberStyle(fontSize)),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            UiStrings.damageSuffix,
            style: TextStyle(
              color: const Color(0xFF37241A),
              fontSize: fontSize * 0.36,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  blurRadius: 0,
                  color: Color(0xFFFFE4C6),
                  offset: Offset(1, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static TextStyle _numberStyle(double fontSize) => TextStyle(
    color: const Color(0xFFC21F17),
    fontSize: fontSize * 1.1,
    fontWeight: FontWeight.w900,
    height: 0.92,
    letterSpacing: 0,
    shadows: const [
      Shadow(blurRadius: 0, color: Color(0xFFFFE4C6), offset: Offset(1.8, 0)),
      Shadow(blurRadius: 0, color: Color(0xFFFFE4C6), offset: Offset(-1.8, 0)),
      Shadow(blurRadius: 0, color: Color(0xFFFFE4C6), offset: Offset(0, 1.8)),
      Shadow(blurRadius: 0, color: Color(0xFFFFE4C6), offset: Offset(0, -1.8)),
      Shadow(blurRadius: 5, color: Color(0xAA3B0602), offset: Offset(1, 1)),
    ],
  );

  static _CriticalDamageParts? _parseCriticalDamage(String text) {
    final match = RegExp(r'^暴击 (\d+) 伤害$').firstMatch(text);
    if (match == null) return null;
    return _CriticalDamageParts(match.group(1)!);
  }
}

class _CriticalDamageParts {
  const _CriticalDamageParts(this.damage);

  final String damage;
}

class _CriticalBrushPainter extends CustomPainter {
  const _CriticalBrushPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paper = Paint()
      ..color = const Color(0xFFFFE8BF).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    final paperEdge = Paint()
      ..color = const Color(0xFF7B2B17).withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final brush = Paint()
      ..color = const Color(0xFFC12D22).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.34
      ..strokeCap = StrokeCap.round;
    final slash = Paint()
      ..color = const Color(0xFF7E1610).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.13
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..moveTo(rect.left + 3, rect.top + size.height * 0.28)
      ..quadraticBezierTo(
        rect.left + size.width * 0.25,
        rect.top + 1,
        rect.left + size.width * 0.62,
        rect.top + 3,
      )
      ..quadraticBezierTo(
        rect.right - 4,
        rect.top + 4,
        rect.right - 1,
        rect.top + size.height * 0.34,
      )
      ..quadraticBezierTo(
        rect.right - 4,
        rect.bottom - 3,
        rect.left + size.width * 0.36,
        rect.bottom - 1,
      )
      ..quadraticBezierTo(
        rect.left + 1,
        rect.bottom - 4,
        rect.left + 3,
        rect.top + size.height * 0.28,
      )
      ..close();

    canvas.drawPath(path, paper);
    canvas.drawLine(
      Offset(rect.left + 16, rect.top + size.height * 0.58),
      Offset(rect.right - 14, rect.top + size.height * 0.45),
      brush,
    );
    canvas.drawLine(
      Offset(rect.left + size.width * 0.12, rect.bottom - 7),
      Offset(rect.right - size.width * 0.12, rect.bottom - 4),
      slash,
    );
    canvas.drawPath(path, paperEdge);
  }

  @override
  bool shouldRepaint(covariant _CriticalBrushPainter oldDelegate) => false;
}
