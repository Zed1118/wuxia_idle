import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme/colors.dart';

/// 战斗交互重做 Phase 3:选关屏 per-stage「挂机自动 / 允许拖招」开关。
///
/// 三态映射 per-stage override(SharedPreferences,见 `stage_auto_play_pref.dart`):
/// - `null`  = 跟随全局设置(显示生效模式 +「随设置」弱标记)
/// - `true`  = 本关纯挂机自动
/// - `false` = 本关允许拖招干预
///
/// 生效模式 `effective = overrideMode ?? globalDefault`。点击弹三选项菜单回传
/// `null/true/false` 给 [onChanged](调用方落 `setOverride` + invalidate)。
///
/// 旧「无重放记录灰显不可切」语义随录制回放链废弃 —— 本偏好是纯设置,任何
/// 渲染处都可切(无 hasRecord 门控)。
class AutoPlayToggle extends StatelessWidget {
  const AutoPlayToggle({
    super.key,
    required this.overrideMode,
    required this.globalDefault,
    required this.onChanged,
  });

  /// 本关每关记忆。`null` 跟随全局。
  final bool? overrideMode;

  /// 全局默认(`GameplaySettings.autoPlayDefault`)。
  final bool globalDefault;

  /// 三态切换回调:`null`=跟随全局 / `true`=纯挂机自动 / `false`=允许拖招。
  final ValueChanged<bool?> onChanged;

  bool get _effectiveAuto => overrideMode ?? globalDefault;

  @override
  Widget build(BuildContext context) {
    final label = _effectiveAuto
        ? UiStrings.stageAutoPlayAuto
        : UiStrings.stageAutoPlayManual;
    final following = overrideMode == null;

    final display = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SealGlyph(
          char: _effectiveAuto
              ? UiStrings.stageAutoPlaySealAuto
              : UiStrings.stageAutoPlaySealManual,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (following) ...[
          const SizedBox(width: 4),
          const Text(
            UiStrings.stageAutoPlayFollowSuffix,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
        const SizedBox(width: 2),
        const Icon(
          Icons.arrow_drop_down,
          size: 16,
          color: WuxiaColors.textMuted,
        ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: display,
    );

    return PopupMenuButton<_AutoPlayChoice>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (c) => onChanged(c.value),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _AutoPlayChoice.follow,
          child: Text(UiStrings.stageAutoPlayMenuFollow),
        ),
        PopupMenuItem(
          value: _AutoPlayChoice.auto,
          child: Text(UiStrings.stageAutoPlayMenuAuto),
        ),
        PopupMenuItem(
          value: _AutoPlayChoice.manual,
          child: Text(UiStrings.stageAutoPlayMenuManual),
        ),
      ],
      child: padded,
    );
  }
}

/// 三选项内部枚举。用枚举而非 `bool?` 作 [PopupMenuItem] value,
/// 规避 PopupMenuButton 对 `null` value 视作「无选择」而丢 `onSelected` 的哨兵问题。
enum _AutoPlayChoice {
  follow(null),
  auto(true),
  manual(false);

  const _AutoPlayChoice(this.value);

  /// 映射回 [AutoPlayToggle.overrideMode] 的三态。
  final bool? value;
}

/// 绛红方印小字 glyph(「自」=纯挂机自动 /「拖」=允许拖招)。朱文风:红框 + 浅红底 + 红字。
/// 暂用现有字体单字,真小篆字形待后续补篆体字体(见 UiStrings 注)。
class _SealGlyph extends StatelessWidget {
  const _SealGlyph({required this.char});

  final String char;

  @override
  Widget build(BuildContext context) {
    const c = WuxiaColors.resultHighlight;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        border: Border.all(
          color: c.withValues(alpha: 0.9),
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        char,
        style: const TextStyle(
          color: c,
          fontSize: 10,
          height: 1.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
