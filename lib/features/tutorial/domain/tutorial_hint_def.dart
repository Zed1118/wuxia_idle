import 'package:flutter/material.dart' show IconData, Icons;

import '../../../shared/strings.dart';

/// 新手引导 banner hint 表驱动定义(P1 #42 Phase 2 §10 P1.y)。
///
/// 每条对应 [tutorialStep] 6/7/8 一档高阶系统解锁提示(GDD §10.2 第 2 方式
/// 上下文气泡提示,红点 + 50-100 字介绍)。本批 3 条,后续 step 9+ 扩表即可。
///
/// **设计纪律**:
/// - 文案走 [UiStrings](CLAUDE.md §5.6 不硬编码中文)
/// - const-canonical 单例,无 mutable state
/// - widget 端按 step 取 [byStep] 渲染,0 知识耦合
class TutorialHintDef {
  /// 对应 [SaveData.tutorialStep] 值(6/7/8)。
  final int step;

  /// banner 标题(< 20 字)。
  final String title;

  /// banner 正文(50-100 字)。
  final String body;

  /// banner 左侧 leading icon。
  final IconData iconData;

  const TutorialHintDef({
    required this.step,
    required this.title,
    required this.body,
    required this.iconData,
  });

  /// step 6 · 收徒(GDD §7.1)。
  static const step6 = TutorialHintDef(
    step: 6,
    title: UiStrings.tutorialHintStep6Title,
    body: UiStrings.tutorialHintStep6Body,
    iconData: Icons.people_outline,
  );

  /// step 7 · 奇遇(GDD §7.2 武学领悟)。
  static const step7 = TutorialHintDef(
    step: 7,
    title: UiStrings.tutorialHintStep7Title,
    body: UiStrings.tutorialHintStep7Body,
    iconData: Icons.auto_awesome,
  );

  /// step 8 · 装备开锋(GDD §6.5)。
  static const step8 = TutorialHintDef(
    step: 8,
    title: UiStrings.tutorialHintStep8Title,
    body: UiStrings.tutorialHintStep8Body,
    iconData: Icons.flash_on_outlined,
  );

  /// 全部 hint def(顺序与 step 升序对齐)。
  static const all = <TutorialHintDef>[step6, step7, step8];

  /// 按 step 查 def。step 不在 {6,7,8} 时返回 null(caller 端兜底跳过渲染)。
  static TutorialHintDef? byStep(int step) {
    for (final def in all) {
      if (def.step == step) return def;
    }
    return null;
  }
}
