import 'package:flutter/material.dart';

import '../../audio/sound_manager.dart';
import '../../audio/audio_assets.dart';
import '../../theme/wuxia_tokens.dart';
import 'paper_panel.dart';

/// 卷轴/册页弹窗（UI kit · demo `.report`）：替 Material AlertDialog。
///
/// 宣纸面板 + 墨边 + 可选朱印封 + 标题/正文/动作行（`PlaqueButton`）。
/// 配 [PaperDialog.show] 便捷入口弹出。
class PaperDialog extends StatelessWidget {
  const PaperDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.showSeal = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showSeal;

  /// 便捷弹出：`await PaperDialog.show<T>(context, ...)`。
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    required List<Widget> actions,
    bool showSeal = true,
    bool barrierDismissible = true,
  }) {
    SoundManager.instance.playSfx(SfxId.uiPaperOpen);
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => PaperDialog(
        title: title,
        body: body,
        actions: actions,
        showSeal: showSeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PaperPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: WuxiaUi.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  if (showSeal)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Image.asset(
                        WuxiaUi.sealRed,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DefaultTextStyle.merge(
                style: const TextStyle(color: WuxiaUi.ink, fontSize: 13),
                child: body,
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
