import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme/colors.dart';

/// 半手动战斗 P0 步骤5-G3:选关屏 per-stage 自动/手动开关。
///
/// 三态映射 [BattleReplayRecord.autoPlayOverride]:
/// - `null`  = 跟随全局设置(显示生效模式 +「随设置」弱标记)
/// - `true`  = 本关强制自动重演
/// - `false` = 本关强制手动
///
/// 生效模式 `effective = overrideMode ?? globalDefault`。点击弹三选项菜单回传
/// `null/true/false` 给 [onChanged](调用方落 `setAutoPlayOverride` + invalidate)。
///
/// **仅对已通关且有重放记录的关有意义**:迁移豁免关(已通关无 record,
/// autoFallback)无从写 overrideMode,[hasRecord] 为 false 时灰显不可切。
class AutoPlayToggle extends StatelessWidget {
  const AutoPlayToggle({
    super.key,
    required this.overrideMode,
    required this.globalDefault,
    required this.hasRecord,
    required this.onChanged,
  });

  /// 本关每关记忆。`null` 跟随全局。
  final bool? overrideMode;

  /// 全局默认(`GameplaySettings.autoPlayDefault`)。
  final bool globalDefault;

  /// 该关是否有重放记录(无 = 迁移豁免,不可切)。
  final bool hasRecord;

  /// 三态切换回调:`null`=跟随全局 / `true`=自动 / `false`=手动。
  final ValueChanged<bool?> onChanged;

  bool get _effectiveAuto => overrideMode ?? globalDefault;

  @override
  Widget build(BuildContext context) {
    final label = _effectiveAuto
        ? UiStrings.stageAutoPlayAuto
        : UiStrings.stageAutoPlayManual;
    final following = overrideMode == null;
    final enabled = hasRecord;

    final display = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _effectiveAuto ? Icons.smart_toy_outlined : Icons.touch_app_outlined,
          size: 14,
          color: enabled ? WuxiaColors.textPrimary : WuxiaColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: enabled ? WuxiaColors.textPrimary : WuxiaColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (following && enabled) ...[
          const SizedBox(width: 4),
          const Text(
            UiStrings.stageAutoPlayFollowSuffix,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
        if (enabled) ...[
          const SizedBox(width: 2),
          const Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: WuxiaColors.textMuted,
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: display,
    );

    // 迁移豁免关(无重放记录)无从写 override → 灰显不可切,tooltip 解释。
    if (!enabled) {
      return Tooltip(
        message: UiStrings.stageAutoPlayLockedHint,
        child: padded,
      );
    }

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
