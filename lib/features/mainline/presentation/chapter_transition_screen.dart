import 'package:flutter/material.dart';

import '../../../data/narrative_loader.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import 'stage_list_screen.dart';

/// 章节翻篇过场（H2 小套餐 C1）。
///
/// 把 `data/narratives/chapters/<id>.yaml` 的 prologue/epilogue 接进可达 UI —
/// 此前是 dead content（lib/ 0 引用）。从章节卡「卷」入口打开:
///   - 卷首(prologue)始终展示
///   - 卷尾(epilogue)仅 [showEpilogue]=true(章节已通关)时解锁,否则弱提示
///
/// 不动战斗 victory 流(Boss 通关自动触发的一次性仪式需 seen-flag 持久化,
/// 留后续)。本屏纯阅读 + 可选「入关」按钮,可重入回顾。
class ChapterTransitionScreen extends StatelessWidget {
  const ChapterTransitionScreen({
    super.key,
    required this.chapterIndex,
    required this.showEpilogue,
    this.loadOverride,
  });

  final int chapterIndex;

  /// 章节是否已通关 → 决定卷尾是否解锁。
  final bool showEpilogue;

  /// 测试注入;生产走 [NarrativeLoader.loadChapter]。
  final Future<ChapterNarrative> Function(int chapterIndex)? loadOverride;

  String get _chapterId =>
      'chapter_${chapterIndex.toString().padLeft(2, '0')}';

  Future<ChapterNarrative> _load() =>
      (loadOverride ?? (_) => NarrativeLoader.loadChapter(_chapterId))(
          chapterIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(UiStrings.chapterTitle(chapterIndex)),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: FutureBuilder<ChapterNarrative>(
          future: _load(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final c = snap.data!;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ScrollSection(
                          label: UiStrings.chapterProloguelabel,
                          body: c.isPlaceholder ? null : c.prologue,
                        ),
                        const SizedBox(height: 28),
                        if (showEpilogue)
                          _ScrollSection(
                            label: UiStrings.chapterEpiloguelabel,
                            body: c.isPlaceholder ? null : c.epilogue,
                          )
                        else
                          const _LockedHint(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              StageListScreen(chapterIndex: chapterIndex),
                        ),
                      ),
                      child: const Text(UiStrings.chapterScrollEnter),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 单段卷语(卷首 / 卷尾)。label 上方小标 + 正文宋体竖排感留白。
class _ScrollSection extends StatelessWidget {
  const _ScrollSection({required this.label, required this.body});

  final String label;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: WuxiaColors.resultHighlight,
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          (body == null || body!.isEmpty)
              ? UiStrings.chapterScrollPlaceholder
              : body!,
          style: TextStyle(
            color: (body == null || body!.isEmpty)
                ? WuxiaColors.textMuted
                : WuxiaColors.textPrimary,
            fontSize: 16,
            height: 1.9,
          ),
        ),
      ],
    );
  }
}

/// 卷尾未解锁(章节进行中)的弱提示。
class _LockedHint extends StatelessWidget {
  const _LockedHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        UiStrings.chapterEpilogueLocked,
        style: TextStyle(
          color: WuxiaColors.textMuted,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
