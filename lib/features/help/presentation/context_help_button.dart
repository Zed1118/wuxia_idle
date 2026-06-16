import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/glossary_tip.dart';
import '../../codex/application/codex_providers.dart';
import '../../codex/presentation/codex_entry_detail.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../domain/help_topic.dart';

/// 页面 / 区块级帮助入口：一个低调的 `?` 图标。
///
/// - hover / 长按：短释义 tooltip。
/// - 点击（[HelpBinding.codexEntryId] 命中且已解锁）：跳「江湖见闻录」对应详情页
///   （复用既有 [CodexEntryDetail] + `codexListItemsProvider`）。
/// - 未解锁（吃 `CodexIndex` step gating）：灰显，tooltip 提示「阅历未至」，不剧透。
/// - 无 codex 条目（codexEntryId == null）：仅 tooltip，不可点。
class ContextHelpButton extends ConsumerWidget {
  const ContextHelpButton({super.key, required this.topic, this.size = 18});

  final HelpTopic topic;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binding = HelpCatalog.of(topic);
    final codexId = binding.codexEntryId;

    // 无长说明：纯 tooltip 锚点。
    if (codexId == null) {
      return GlossaryTip(
        definition: binding.shortText,
        child: _icon(enabled: true),
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

    if (!unlocked) {
      return GlossaryTip(
        definition: UiStrings.contextHelpLocked,
        child: _icon(enabled: false),
      );
    }

    final entry = match!.entry!;
    return GlossaryTip(
      definition: binding.shortText,
      child: InkWell(
        borderRadius: BorderRadius.circular(size),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CodexEntryDetail(entry: entry),
          ),
        ),
        child: _icon(enabled: true),
      ),
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
