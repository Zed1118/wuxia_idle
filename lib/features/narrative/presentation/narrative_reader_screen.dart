import 'package:flutter/material.dart';

import '../../../data/narrative_loader.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import 'narrative_scene_background.dart';

/// 主线剧情阅读屏（Phase 3 T36）。
///
/// 一页展示当前段落，下方「继续」推进到下一段；最后一段后调 [onFinish]。
/// 「跳过」按钮直接 finish。占位文案（[NarrativeContent.isPlaceholder]）顶部
/// 显示弱提示便于 Pen 端验收 NarrativeLoader 容错路径。
class NarrativeReaderScreen extends StatefulWidget {
  const NarrativeReaderScreen({
    super.key,
    required this.content,
    required this.fallbackTitle,
    this.onFinish,
    this.topBanner,
    this.backgroundImagePath,
  });

  /// 已加载的剧情内容（由调用方提前 `NarrativeLoader.load`）。
  final NarrativeContent content;

  /// content.title 为 null 时的兜底标题（一般传 stage.name）。
  final String fallbackTitle;

  final VoidCallback? onFinish;

  /// Phase 4 W10：占位提示下方的可选 banner，用于 Boss 战败损失摘要等。
  /// null 时不展示。
  final Widget? topBanner;

  /// 出版美术:主线 stage 专属背景图路径。null → 纯色底兜底。
  final String? backgroundImagePath;

  @override
  State<NarrativeReaderScreen> createState() => _NarrativeReaderScreenState();
}

class _NarrativeReaderScreenState extends State<NarrativeReaderScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _next() {
    final paragraphs = widget.content.paragraphs;
    if (_currentIndex < paragraphs.length - 1) {
      setState(() => _currentIndex++);
      _fade
        ..reset()
        ..forward();
    } else {
      _finish();
    }
  }

  void _finish() {
    widget.onFinish?.call();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    final title = c.title ?? widget.fallbackTitle;
    final paragraphs =
        c.paragraphs.isEmpty ? <String>[''] : c.paragraphs;
    final current = paragraphs[_currentIndex];
    final isLast = _currentIndex >= paragraphs.length - 1;
    final bg = widget.backgroundImagePath;
    final hasBg = bg != null && bg.isNotEmpty;
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        // P1 #42 Phase 2 §10 P1.x:mandatory=true(yaml 标注)隐藏跳过按钮。
        actions: c.mandatory
            ? const <Widget>[]
            : [
                TextButton(
                  onPressed: _finish,
                  child: const Text(
                    UiStrings.narrativeSkip,
                    style: TextStyle(color: WuxiaColors.textSecondary),
                  ),
                ),
              ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBg) NarrativeSceneBackground(path: bg),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (c.isPlaceholder)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: WuxiaColors.hpMid.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        UiStrings.narrativePlaceholderHint,
                        style: TextStyle(
                          color: WuxiaColors.hpMid,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (widget.topBanner != null) widget.topBanner!,
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _next,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: hasBg
                                ? WuxiaColors.background.withValues(alpha: 0.55)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: FadeTransition(
                              opacity: _fade,
                              child: Text(
                                current,
                                style: const TextStyle(
                                  color: WuxiaColors.textPrimary,
                                  fontSize: 16,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // G4 · 首段轻点提示(§5.7 仅首段显一次,引导玩家轻点画面/按钮推进)。
                  if (_currentIndex == 0) ...[
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        UiStrings.narrativeReaderTapHint,
                        style: TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentIndex + 1} / ${paragraphs.length}',
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WuxiaColors.resultHighlight,
                          foregroundColor: WuxiaColors.background,
                        ),
                        child: Text(
                          isLast
                              ? UiStrings.narrativeReaderFinish
                              : UiStrings.narrativeReaderContinue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
