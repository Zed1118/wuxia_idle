import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/glossary_tip.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../codex/application/codex_providers.dart';
import '../../codex/presentation/codex_entry_detail.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../domain/help_topic.dart';

/// 页面 / 区块级帮助入口：一个低调的 `?` 图标。
///
/// hover / 长按出短释义 tooltip；**三态全部可点**（2026-06-19 修：原无 codex /
/// 未解锁两态不可点，桌面端用户点了无反馈，体感「按钮坏了」）：
/// - 有 codex 且已解锁：跳「江湖见闻录」对应详情页（复用 [CodexEntryDetail]）。
/// - 有 codex 但未解锁（吃 `CodexIndex` step gating）：灰显 + 点击弹「阅历未至」
///   提示浮层（不剧透内容，只给反馈）。
/// - 无 codex 条目（codexEntryId == null，如属性 / 派生数值）：点击弹短释义浮层。
///
/// 点击热区放大到 [_hitSize]（原仅图标 ~18px 太难命中）。
class ContextHelpButton extends ConsumerWidget {
  const ContextHelpButton({super.key, required this.topic, this.size = 20});

  final HelpTopic topic;
  final double size;

  /// 点击热区最小边长（图标视觉仍 ~[size]，仅扩可点范围；不取 Material 48 免抢布局）。
  static const double _hitSize = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binding = HelpCatalog.of(topic);
    final codexId = binding.codexEntryId;

    // 无长说明：点击弹短释义浮层。
    if (codexId == null) {
      return _wrap(
        definition: binding.shortText,
        enabled: true,
        onTap: () => _showInfoPopup(context, binding.label, binding.shortText),
      );
    }

    final items = ref.watch(codexListItemsProvider);
    final currentStep = ref.watch(currentTutorialStepProvider).value ?? 0;

    CodexListItem? match;
    for (final it in items) {
      if (it.indexEntry.id == codexId) {
        match = it;
        break;
      }
    }

    final unlocked = helpEntryUnlocked(
      requiredStep: match?.indexEntry.step,
      isLoaded: match?.isLoaded ?? false,
      currentStep: currentStep,
    );

    // 未解锁：灰显，点击给「阅历未至」反馈（不剧透）。
    if (!unlocked) {
      return _wrap(
        definition: UiStrings.contextHelpLocked,
        enabled: false,
        onTap: () => _showInfoPopup(
          context,
          binding.label,
          UiStrings.contextHelpLocked,
        ),
      );
    }

    final entry = match!.entry!;
    return _wrap(
      definition: binding.shortText,
      enabled: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CodexEntryDetail(entry: entry),
        ),
      ),
    );
  }

  /// 统一外壳：hover tooltip + 放大点击热区 InkWell + `?` 图标。
  Widget _wrap({
    required String definition,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GlossaryTip(
      definition: definition,
      child: InkWell(
        borderRadius: BorderRadius.circular(_hitSize / 2),
        onTap: onTap,
        child: SizedBox(
          width: _hitSize,
          height: _hitSize,
          child: Center(child: _icon(enabled: enabled)),
        ),
      ),
    );
  }

  void _showInfoPopup(BuildContext context, String title, String body) {
    PaperDialog.show<void>(
      context,
      title: title,
      body: Text(body),
      actions: [
        PlaqueButton(
          label: UiStrings.skillInfoClose,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _icon({required bool enabled}) {
    return Icon(
      Icons.help_outline,
      size: size,
      color: enabled
          ? WuxiaUi.muted
          : WuxiaUi.muted.withValues(alpha: 0.4),
    );
  }
}
