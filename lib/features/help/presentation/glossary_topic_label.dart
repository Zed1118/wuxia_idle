import 'package:flutter/material.dart';

import '../../../shared/widgets/wuxia_ui/glossary_tip.dart';
import '../domain/help_topic.dart';

/// 术语级帮助标签：声明一个 [HelpTopic]，自动渲染「术语 + 柔灰 `?` 上标」并挂
/// 水墨 tooltip 短释义。是对 shared [GlossaryLabel] 的薄包装。
///
/// **分层**：[GlossaryLabel] 在 shared（叶子层）不可依赖 features，故 topic 解析
/// 留在本 features/help 层，委托 shared 渲染。纯 [StatelessWidget]，无 provider 依赖
/// （术语 tooltip 不做解锁 gating；页面级跳转 + gating 用 [ContextHelpButton]）。
class GlossaryTopicLabel extends StatelessWidget {
  const GlossaryTopicLabel({
    super.key,
    required this.topic,
    this.style,
    this.markerColor,
    this.preferBelow = true,
  });

  final HelpTopic topic;
  final TextStyle? style;
  final Color? markerColor;
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    final binding = HelpCatalog.of(topic);
    return GlossaryLabel(
      label: binding.label,
      definition: binding.shortText,
      style: style,
      markerColor: markerColor,
      preferBelow: preferBelow,
    );
  }
}
