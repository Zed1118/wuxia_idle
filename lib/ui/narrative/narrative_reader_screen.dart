import 'package:flutter/material.dart';

import '../../data/narrative_loader.dart';
import '../theme/colors.dart';

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
  });

  /// 已加载的剧情内容（由调用方提前 `NarrativeLoader.load`）。
  final NarrativeContent content;

  /// content.title 为 null 时的兜底标题（一般传 stage.name）。
  final String fallbackTitle;

  final VoidCallback? onFinish;

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
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text(
              '跳过',
              style: TextStyle(color: WuxiaColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (c.isPlaceholder)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: WuxiaColors.hpMid.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⚠ 剧情占位（DeepSeek 待补）',
                    style: TextStyle(
                      color: WuxiaColors.hpMid,
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: Center(
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
                    child: Text(isLast ? '完成' : '继续'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
