import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';

/// 内息流轨进度条（UI kit · demo `.mbar`）：替 Material LinearProgressIndicator。
///
/// 墨边轨槽 + 青灰墨迹填充（[ratio] 钳到 [0,1]）。可选 [label] 在条上方。
class MeridianBar extends StatelessWidget {
  const MeridianBar({
    super.key,
    required this.ratio,
    this.label,
    this.height = 12,
  });

  final double ratio;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final f = ratio.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              label!,
              style: const TextStyle(color: WuxiaUi.ink, fontSize: 12),
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: WuxiaUi.paper2,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: WuxiaUi.ink, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: f,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [WuxiaUi.qing, Color(0xFF3F524B)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
