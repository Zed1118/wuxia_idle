import 'package:flutter/material.dart' show IconData, Icons;

import '../../../shared/strings.dart';

/// 新手引导 banner hint 表驱动定义(P1 #42 Phase 2 §10 P1.y)。
///
/// 每条对应一档「新系统解锁」提示(GDD §10.2 第 2 方式上下文气泡提示,红点 +
/// 50-100 字介绍)。**§5.7 纪律**:仅在系统首次点亮那一步提示一次,不为纯进度
/// 祝贺(step 1/2/4)立 banner。现 5 条:step 3 心法 / 5 Ch1 通关(闭关+江湖)/
/// 6 收徒 / 7 奇遇 / 8 开锋。后续扩表即可。
///
/// **设计纪律**:
/// - 文案走 [UiStrings](CLAUDE.md §5.6 不硬编码中文)
/// - const-canonical 单例,无 mutable state
/// - widget 端按 step 取 [byStep] 渲染,0 知识耦合
class TutorialHintDef {
  /// 对应 [SaveData.tutorialStep] 值(3/5/6/7/8)。
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

  /// step 3 · 心法面板解锁(§5.7 系统解锁锚点)。
  static const step3 = TutorialHintDef(
    step: 3,
    title: UiStrings.tutorialHintStep3Title,
    body: UiStrings.tutorialHintStep3Body,
    iconData: Icons.menu_book_outlined,
  );

  /// step 5 · Ch1 通关 → 闭关 + 江湖/门派/排行榜解锁(§5.7 系统解锁锚点)。
  static const step5 = TutorialHintDef(
    step: 5,
    title: UiStrings.tutorialHintStep5Title,
    body: UiStrings.tutorialHintStep5Body,
    iconData: Icons.explore_outlined,
  );

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

  /// 全部 hint def(顺序与 step 升序对齐 · _firstUnreadHint 取最低未读 step)。
  static const all = <TutorialHintDef>[step3, step5, step6, step7, step8];

  /// 按 step 查 def。step 无对应 def(1/2/4/9...)时返回 null(caller 端兜底跳过渲染)。
  static TutorialHintDef? byStep(int step) {
    for (final def in all) {
      if (def.step == step) return def;
    }
    return null;
  }
}
