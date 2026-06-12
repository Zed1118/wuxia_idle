import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';
import 'meridian_bar.dart';

/// 养成进度「五要素」标准化展示行（D · 2026-06-12）。
///
/// 纯表现层哑组件，**不认任何 domain 类型**：调用方传入已格式化好的字符串 +
/// 进度比率。统一熟练度 / 共鸣度 / 修炼度等多类养成进度的展示语言，
/// 沿用 [SkillProficiencyRow] 既有三行骨架（标题 / [MeridianBar] / 效果）。
///
/// 五要素：当前阶段 [stageName] + 进度 [ratio]/[progressText] +
/// 当前效果 [currentEffect] + 下一阶效果 [nextEffect] + 来源/标记 [tag]。
///
/// [stageName] == null 时退化为「标题 + 进度条 + 来源」两段式（承载残页式
/// 无阶段收集进度）。
///
/// [title] 可省略（在已显示实体名的卡片内作为子段使用，如角色卡主修 /
/// 装备详情共鸣段）：此时首行以 [stageName] 领头，不重复实体名。
class StageProgressRow extends StatelessWidget {
  /// 标题（招名 / 心法名 / 装备名）。null = 卡内子段用法，首行以阶段名领头。
  final String? title;

  /// 当前阶段名（青字）。null = 无阶段，标题行不渲染阶段名。
  final String? stageName;

  /// 进度比率 0~1，喂 [MeridianBar]。
  final double ratio;

  /// 中性进度文案（如「还需 120 次」「战斗 1840/2000」），柔灰小字，
  /// 显示在右下；与 [nextEffect] 同时存在时叠在其下一行。
  final String? progressText;

  /// 当前阶段效果（如「伤害 +30%」「伤害 ×1.75」），柔灰，显示在左下。
  final String? currentEffect;

  /// 下一阶段效果 / 最高阶标记（如「下一阶 ×2.00」「已至极境」），金字，
  /// 显示在右下。
  final String? nextEffect;

  /// 来源 / 标记文案（装配标 / 残页来源）。
  final String? tag;

  /// [tag] 是否高亮显示（true = 青底纸字徽标，如「已装配」；
  /// false = 柔灰来源文案）。
  final bool tagHighlighted;

  /// 点击整行回调。null = 纯展示。
  final VoidCallback? onTap;

  const StageProgressRow({
    super.key,
    required this.ratio,
    this.title,
    this.stageName,
    this.progressText,
    this.currentEffect,
    this.nextEffect,
    this.tag,
    this.tagHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBottom =
        currentEffect != null || nextEffect != null || progressText != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：标题/阶段名领头 + 阶段名（有标题时居右）+ 标记
            Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? stageName ?? '',
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (title != null && stageName != null)
                  Text(
                    stageName!,
                    style: const TextStyle(color: WuxiaUi.qing, fontSize: 12),
                  ),
                if (tag != null) ...[
                  const SizedBox(width: 6),
                  if (tagHighlighted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: WuxiaUi.qing,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tag!,
                        style: const TextStyle(
                          color: WuxiaUi.paper,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    Text(
                      tag!,
                      style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // 第二行：进度条
            MeridianBar(ratio: ratio),
            // 第三行：当前效果 ↔ 下一阶效果 / 进度
            if (hasBottom) ...[
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentEffect ?? '',
                      style: const TextStyle(
                        color: WuxiaUi.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (nextEffect != null || progressText != null) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nextEffect != null)
                          Text(
                            nextEffect!,
                            style: const TextStyle(
                              color: WuxiaUi.gold,
                              fontSize: 11,
                            ),
                          ),
                        if (progressText != null)
                          Text(
                            progressText!,
                            style: TextStyle(
                              color: WuxiaUi.ink.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
