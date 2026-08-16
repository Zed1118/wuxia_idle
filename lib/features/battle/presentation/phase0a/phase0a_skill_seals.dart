import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_presentation_tokens.dart';

/// Phase 0A 技能印:Q 聚怪 / R 清场两枚等宽等高水墨印章。
///
/// 纯展示 + 输入转发,不做任何战斗结算;五态(ready / cooldown / qi /
/// casting / down)全部读 [Phase0aSkillSlot.availability],仅 ready 可激活:
/// - ready:亮印,鼠标 / Tab+Enter / Tab+Space 均可触发回调;
/// - cooldown:暗印 + 剩余秒数,禁用;
/// - qi:暗印 + 当前/所需真气,禁用;
/// - casting / down:暗印 + 明确禁用原因文案,禁用。
///
/// 布局尺寸一律取自 [Phase0aPresentationTokens],文案一律走 [UiStrings];
/// 色板用宣纸母题(WuxiaUi),禁 Material 默认饱和色。
final class Phase0aSkillSeals extends StatelessWidget {
  const Phase0aSkillSeals({
    super.key,
    required this.gatherSlot,
    required this.clearSlot,
    required this.qiCurrent,
    required this.onGather,
    required this.onClear,
  });

  /// Q 聚怪印运行态快照。
  final Phase0aSkillSlot gatherSlot;

  /// R 清场印运行态快照。
  final Phase0aSkillSlot clearSlot;

  /// 当前真气(qi 态状态行「当前/所需」的当前值)。
  final int qiCurrent;

  /// 聚怪印激活回调(仅 ready 态可达)。
  final VoidCallback onGather;

  /// 清场印激活回调(仅 ready 态可达)。
  final VoidCallback onClear;

  /// 聚怪印查找 key(测试与宿主共用)。
  static const ValueKey<String> gatherKey = ValueKey('phase0a_seal_gather');

  /// 清场印查找 key(测试与宿主共用)。
  static const ValueKey<String> clearKey = ValueKey('phase0a_seal_clear');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SkillSeal(
          key: gatherKey,
          slot: gatherSlot,
          glyph: UiStrings.phase0aSealGatherGlyph,
          keyCap: UiStrings.phase0aSealGatherKey,
          qiCurrent: qiCurrent,
          onPressed: onGather,
        ),
        const SizedBox(width: Phase0aPresentationTokens.skillSealSpacing),
        _SkillSeal(
          key: clearKey,
          slot: clearSlot,
          glyph: UiStrings.phase0aSealClearGlyph,
          keyCap: UiStrings.phase0aSealClearKey,
          qiCurrent: qiCurrent,
          onPressed: onClear,
        ),
      ],
    );
  }
}

/// 单枚技能印:固定边长的墨章,五态亮暗 + 状态行。
class _SkillSeal extends StatelessWidget {
  const _SkillSeal({
    super.key,
    required this.slot,
    required this.glyph,
    required this.keyCap,
    required this.qiCurrent,
    required this.onPressed,
  });

  final Phase0aSkillSlot slot;
  final String glyph;
  final String keyCap;
  final int qiCurrent;
  final VoidCallback onPressed;

  bool get _enabled => slot.availability == Phase0aSkillAvailability.ready;

  /// 状态行:ready 亮「可用」,其余四态给出明确禁用原因。
  String get _statusText => switch (slot.availability) {
    Phase0aSkillAvailability.ready => UiStrings.skillReady,
    Phase0aSkillAvailability.cooldown => UiStrings.phase0aSealCooldown(
      slot.cooldownRemaining,
    ),
    Phase0aSkillAvailability.qi => UiStrings.phase0aSealQiShort(
      qiCurrent,
      slot.qiCost,
    ),
    Phase0aSkillAvailability.casting => UiStrings.phase0aSealCasting,
    Phase0aSkillAvailability.down => UiStrings.phase0aSealDown,
  };

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final background = enabled
        ? WuxiaUi.battleSkillSeal
        : WuxiaUi.battleDeskBase;
    final foreground = enabled ? WuxiaUi.battleSkillSealInk : WuxiaUi.muted;
    final edge = enabled ? WuxiaUi.jiang : WuxiaUi.muted;
    return Semantics(
      button: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      child: Focus(
        canRequestFocus: enabled,
        onKeyEvent: _onKeyEvent,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onPressed : null,
            child: Container(
              width: Phase0aPresentationTokens.skillSealSize,
              height: Phase0aPresentationTokens.skillSealSize,
              padding: const EdgeInsets.all(
                Phase0aPresentationTokens.skillSealPadding,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(
                  Phase0aPresentationTokens.skillSealRadius,
                ),
                border: Border.all(
                  color: edge,
                  width: Phase0aPresentationTokens.skillSealBorderWidth,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    glyph,
                    style: TextStyle(
                      color: foreground,
                      fontSize:
                          Phase0aPresentationTokens.skillSealGlyphFontSize,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    keyCap,
                    style: TextStyle(
                      color: foreground,
                      fontSize: Phase0aPresentationTokens.skillSealKeyFontSize,
                      height: 1.2,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: foreground,
                        fontSize:
                            Phase0aPresentationTokens.skillSealStatusFontSize,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
