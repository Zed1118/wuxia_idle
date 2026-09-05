import 'package:flutter/material.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../application/phase0a/phase0a_numeric_skill_binding.dart';
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

/// 数字 1–6 真实技能印。空槽保持原位置并禁用，不压缩后续键位。
final class Phase0aNumericSkillSeals extends StatelessWidget {
  const Phase0aNumericSkillSeals({
    super.key,
    required this.bindings,
    required this.slots,
    required this.qiCurrent,
    required this.onPressed,
  });

  final Phase0aNumericSkillBindings bindings;
  final Map<String, Phase0aSkillSlot> slots;
  final int qiCurrent;
  final ValueChanged<int> onPressed;

  static ValueKey<String> keyFor(int hotkey) =>
      ValueKey<String>('phase0a_seal_skill_$hotkey');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var hotkey = 1; hotkey <= 6; hotkey++) ...[
          if (hotkey > 1)
            const SizedBox(
              width: Phase0aPresentationTokens.numericSkillSealSpacing,
            ),
          _numericSeal(hotkey),
        ],
      ],
    );
  }

  Widget _numericSeal(int hotkey) {
    final binding = bindings.bindingFor(hotkey);
    final slot = binding == null
        ? const Phase0aSkillSlot(
            slot: 'empty',
            cooldownRemaining: 0,
            qiCost: 0,
            availability: Phase0aSkillAvailability.down,
          )
        : slots[binding.slotId] ??
              Phase0aSkillSlot(
                slot: binding.slotId,
                cooldownRemaining: 0,
                qiCost: binding.skill.qiCost,
                availability: Phase0aSkillAvailability.down,
              );
    return _SkillSeal(
      key: keyFor(hotkey),
      slot: slot,
      glyph: binding?.skill.name ?? UiStrings.slotEmpty,
      keyCap: '$hotkey',
      showStatus: binding != null,
      qiCurrent: qiCurrent,
      size: Phase0aPresentationTokens.numericSkillSealSize,
      onPressed: () => onPressed(hotkey),
    );
  }
}

/// 单枚技能印:固定边长的墨章,五态亮暗 + 状态行。
///
/// 键盘体例对齐 PlaqueButton:FocusableActionDetector 的
/// onShowFocusHighlight 驱动 `if (_focused)` 金边环,Tab 落点可见;
/// Enter/Space 走 ActivateIntent,其余键 ignored 冒泡给屏幕 handler。
class _SkillSeal extends StatefulWidget {
  const _SkillSeal({
    super.key,
    required this.slot,
    required this.glyph,
    required this.keyCap,
    required this.qiCurrent,
    required this.onPressed,
    this.size = Phase0aPresentationTokens.skillSealSize,
    this.showStatus = true,
  });

  final Phase0aSkillSlot slot;
  final String glyph;
  final String keyCap;
  final int qiCurrent;
  final VoidCallback onPressed;
  final double size;
  // Empty numeric slots have no actor state; the empty glyph is sufficient.
  // Keep the underlying disabled slot and all real skill states unchanged.
  final bool showStatus;

  @override
  State<_SkillSeal> createState() => _SkillSealState();
}

class _SkillSealState extends State<_SkillSeal> {
  bool _focused = false;

  bool get _enabled =>
      widget.slot.availability == Phase0aSkillAvailability.ready;

  /// 状态行:ready 亮「可用」,其余四态给出明确禁用原因。
  String get _statusText => switch (widget.slot.availability) {
    Phase0aSkillAvailability.ready => UiStrings.skillReady,
    Phase0aSkillAvailability.cooldown => UiStrings.phase0aSealCooldown(
      widget.slot.cooldownRemaining,
    ),
    Phase0aSkillAvailability.qi => UiStrings.phase0aSealQiShort(
      widget.qiCurrent,
      widget.slot.qiCost,
    ),
    Phase0aSkillAvailability.casting => UiStrings.phase0aSealCasting,
    Phase0aSkillAvailability.down => UiStrings.phase0aSealDown,
  };

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
      // label = 印字 + 键位 + 状态行;内容层的视觉文字对读屏静音,
      // 避免节点 label 与子 Text 拼出双份文案。
      label:
          '${widget.glyph} ${widget.keyCap}'
          '${widget.showStatus ? ' $_statusText' : ''}',
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed();
                return null;
              },
            ),
          },
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onPressed : null,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
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
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      widget.size ==
                              Phase0aPresentationTokens.numericSkillSealSize
                          ? Phase0aPresentationTokens.numericSkillSealPadding
                          : Phase0aPresentationTokens.skillSealPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.glyph,
                            maxLines: 1,
                            style: TextStyle(
                              color: foreground,
                              fontSize: Phase0aPresentationTokens
                                  .skillSealGlyphFontSize,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ),
                        Text(
                          widget.keyCap,
                          style: TextStyle(
                            color: foreground,
                            fontSize:
                                Phase0aPresentationTokens.skillSealKeyFontSize,
                            height: 1.2,
                          ),
                        ),
                        if (widget.showStatus)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _statusText,
                              style: TextStyle(
                                color: foreground,
                                fontSize: Phase0aPresentationTokens
                                    .skillSealStatusFontSize,
                                height: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 键盘 focus 高亮:金边环(PlaqueButton 同体例,9C)。
                  if (_focused)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              Phase0aPresentationTokens.skillSealRadius,
                            ),
                            border: Border.all(
                              color: WuxiaUi.gold,
                              width: Phase0aPresentationTokens.focusRingWidth,
                            ),
                          ),
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
