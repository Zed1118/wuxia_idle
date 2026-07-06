import 'package:flutter/material.dart';

import '../../strings.dart';
import '../../theme/colors.dart';
import 'light_paper_panel.dart';
import 'panel_surface.dart';
import 'plaque_button.dart';

/// 统一错误兜底 UI（P0-4 2026-06-29 审查修复 · 水墨风格）。
///
/// 替换各 `AsyncValue.when` error 分支里直接渲染 `'load error: $e'` 的写法——
/// 原始异常类名/堆栈对玩家无意义且出戏。本组件:
/// - 显示友好中文文案（[message]，默认 [UiStrings.errorFallbackMessage]）;
/// - [onRetry] 非空时显示「重试」[PlaqueButton]（通常 `ref.invalidate(provider)`）;
/// - [error] 仅 `debugPrint` 记录,**不上屏**（避免暴露 `StateError:...` 等内部细节）。
///
/// 用 [WuxiaColors] / [LightPaperPanel] / [PlaqueButton],不硬编码颜色。空态请保持
/// 各自的 `_EmptyHint`,本组件只负责「真出错」分支。
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key, this.message, this.onRetry, this.error});

  /// 自定义提示文案;null 用 [UiStrings.errorFallbackMessage]。
  final String? message;

  /// 重试回调;null 则不显示重试按钮。
  final VoidCallback? onRetry;

  /// 原始异常,仅 debugPrint 记录,不渲染到屏幕。
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      debugPrint('ErrorFallback: $error');
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: LightPaperPanel(
          // 文字色读自身 LightPaperPanel 提供的 surface（恒浅底），用内层
          // Builder 拿到 PanelSurface.light 的 context——本组件总渲染在自带的
          // 浅宣纸面板上，即便被放进深色面板也须保持深墨字，不随外层翻白。
          child: Builder(
            builder: (context) {
              final surface = PanelSurface.of(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message ?? UiStrings.errorFallbackMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: surface.primary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 14),
                    PlaqueButton(label: UiStrings.errorRetry, onTap: onRetry),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
