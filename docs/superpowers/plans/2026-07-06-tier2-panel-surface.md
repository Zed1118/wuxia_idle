# Tier2 PanelSurface 背景自带文字色 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 让 wuxia_ui/ 共享组件按所在面板底色自动取正确文字色，消灭「浅底×同色文字低对比」整类 bug。

**Architecture:** 新增 `PanelSurface`(InheritedWidget) 暴露 primary/secondary/accent 三文字角色；两面板向下 provide 各自 surface；组件改读 `PanelSurface.of(context)` 替代硬编 bg-dependent 文字色；废掉 `StageProgressRow.nextEffectColor` 手传参数。结构/品牌色(tier 金框/按钮绛红/内息青)保留不动。

**Tech Stack:** Flutter · InheritedWidget · flutter_test widget 测。

**Spec:** `docs/superpowers/specs/2026-07-06-tier2-panel-surface-design.md`

**环境前置(worktree):** 执行前 worktree 必须 `flutter pub get` + 从主 checkout 拷 `.g.dart`(56 个) + 拷 `libisar.dylib`，否则 analyze/test 编译失败。基线全量 = 3692 pass/1 skip/0 fail。

**通用测试 helper(各组件测复用):**
```dart
Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;
```
**双底断言模板:** 同组件先包 `LightPaperPanel(child: ...)` pump 断言浅色、再包 `DarkParchmentPanel(child: ...)` pump 断言深色。两面板 import 路径:`package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart` 与 `package:wuxia_idle/shared/widgets/dark_parchment_panel.dart`。

---

### Task 1: PanelSurface InheritedWidget

**Files:**
- Create: `lib/shared/widgets/wuxia_ui/panel_surface.dart`
- Test: `test/shared/widgets/wuxia_ui/panel_surface_test.dart`

- [ ] **Step 1: 写失败测试**
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/panel_surface.dart';

void main() {
  testWidgets('light 工厂角色值', (t) async {
    late PanelSurface s;
    await t.pumpWidget(PanelSurface.light(
      child: Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); })));
    expect(s.primary, WuxiaUi.ink);
    expect(s.secondary, WuxiaUi.muted);
    expect(s.accent, WuxiaUi.jiang);
  });
  testWidgets('dark 工厂角色值', (t) async {
    late PanelSurface s;
    await t.pumpWidget(PanelSurface.dark(
      child: Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); })));
    expect(s.primary, WuxiaColors.textPrimary);
    expect(s.secondary, WuxiaColors.textSecondary);
    expect(s.accent, WuxiaUi.gold);
  });
  testWidgets('无 ancestor 兜底 light', (t) async {
    late PanelSurface s;
    await t.pumpWidget(Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); }));
    expect(s.primary, WuxiaUi.ink);
    expect(PanelSurface.maybeOf(t.element(find.byType(SizedBox))), isNull);
  });
}
```

- [ ] **Step 2: 跑测试确认失败** — Run: `flutter test --no-pub test/shared/widgets/wuxia_ui/panel_surface_test.dart` · Expected: FAIL(panel_surface.dart 不存在)

- [ ] **Step 3: 实现**
```dart
import 'package:flutter/widgets.dart';
import '../../theme/colors.dart';
import '../../theme/wuxia_tokens.dart';

/// 面板底色 → 文字色语义角色的向下供应。共享组件读 [of] 取正确文字色，
/// 深/浅由所在面板(DarkParchmentPanel/LightPaperPanel)自动决定，调用方无需传色。
class PanelSurface extends InheritedWidget {
  final Color primary;   // 标题/正文
  final Color secondary; // 次要/副描述/分隔线
  final Color accent;    // value 强调/下一阶

  const PanelSurface({
    super.key,
    required this.primary,
    required this.secondary,
    required this.accent,
    required super.child,
  });

  const PanelSurface.light({super.key, required super.child})
      : primary = WuxiaUi.ink,
        secondary = WuxiaUi.muted,
        accent = WuxiaUi.jiang;

  const PanelSurface.dark({super.key, required super.child})
      : primary = WuxiaColors.textPrimary,
        secondary = WuxiaColors.textSecondary,
        accent = WuxiaUi.gold;

  static const PanelSurface _fallback =
      PanelSurface.light(child: SizedBox.shrink());

  static PanelSurface of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelSurface>() ?? _fallback;

  static PanelSurface? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelSurface>();

  @override
  bool updateShouldNotify(PanelSurface old) =>
      primary != old.primary ||
      secondary != old.secondary ||
      accent != old.accent;
}
```

- [ ] **Step 4: 跑测试确认通过** — Expected: PASS(3 测)
- [ ] **Step 5: 提交** — `git add -A && git commit -m "feat:PanelSurface 背景文字色供应 InheritedWidget"`

---

### Task 2: 两面板 provide surface

**Files:**
- Modify: `lib/shared/widgets/dark_parchment_panel.dart`(build 返回前包 `PanelSurface.dark`)
- Modify: `lib/shared/widgets/wuxia_ui/light_paper_panel.dart`(build 返回前包 `PanelSurface.light`)
- Test: `test/shared/widgets/panel_provides_surface_test.dart`

- [ ] **Step 1: 写失败测试**
```dart
// pump LightPaperPanel(child: Builder→读 of) 断言 primary==WuxiaUi.ink；
// pump DarkParchmentPanel(child: Builder→读 of) 断言 primary==WuxiaColors.textPrimary。
```
(完整体例照 Task1 的 Builder+PanelSurface.of 断言，两面板各一 case。)

- [ ] **Step 2: 跑确认失败**(当前面板未包 surface → 兜底 light → dark case 断言 textPrimary 失败)
- [ ] **Step 3: 实现** — 各 build 把现有 `return DecoratedBox(...)` 改为 `return PanelSurface.dark(child: DecoratedBox(...));`(light 面板用 `.light`)。import 加 `panel_surface.dart`(dark 面板路径 `wuxia_ui/panel_surface.dart`，light 面板同目录 `panel_surface.dart`)。
- [ ] **Step 4: 跑确认通过**
- [ ] **Step 5: 提交** — `git commit -m "feat:两面板向下 provide PanelSurface"`

---

### Task 3: 迁移 StageProgressRow + 废 nextEffectColor(样板证明点)

**Files:**
- Modify: `lib/shared/widgets/wuxia_ui/stage_progress_row.dart`(删 `nextEffectColor` 字段/参数/默认；build 读 surface)
- Modify: `lib/features/baike/presentation/skill_codex_detail_screen.dart`(删手传 `nextEffectColor: WuxiaUi.jiang,` + 注释)
- Modify: `lib/features/inventory/presentation/equipment_detail_screen.dart`(同上)
- Modify: `lib/features/cangjingge/presentation/skill_proficiency_row.dart`(同上 + 删多余 wuxia_tokens import 若无其它用)
- Test: `test/shared/widgets/wuxia_ui/stage_progress_row_surface_test.dart`

- [ ] **Step 1: 写失败测试**
```dart
testWidgets('nextEffect 浅底 jiang / 深底 gold', (t) async {
  Widget row() => const StageProgressRow(ratio: .5, stageName: '小成', nextEffect: '下一阶 ×2.0');
  await t.pumpWidget(MaterialApp(home: LightPaperPanel(child: row())));
  expect(_textColor(t, '下一阶 ×2.0'), WuxiaUi.jiang);
  await t.pumpWidget(MaterialApp(home: DarkParchmentPanel(child: row())));
  expect(_textColor(t, '下一阶 ×2.0'), WuxiaUi.gold);
});
```
- [ ] **Step 2: 跑确认失败**(编译失败:StageProgressRow 仍要 nextEffectColor / 或颜色仍固定 gold)
- [ ] **Step 3: 实现**
  - 删 `final Color nextEffectColor;` 字段、构造参数 `this.nextEffectColor = WuxiaUi.gold,`、docstring。
  - build 开头 `final surface = PanelSurface.of(context);`
  - 色映射:title(:96,:106)→`surface.primary`；currentEffect(:159)→`surface.secondary`；nextEffect(:174)→`surface.accent`；progressText(:182)→`surface.primary.withValues(alpha: 0.5)`。stageName(:115 qing)与 tag(:132/:140)不动。
  - 三调用点删 `nextEffectColor: WuxiaUi.jiang,`(+对应注释);skill_proficiency_row 若删后不再用 WuxiaUi 则删其 `wuxia_tokens.dart` import。
- [ ] **Step 4: 跑确认通过** — 另 Run 定向回归:`flutter test --no-pub test/features/baike test/features/cangjingge test/features/inventory`
- [ ] **Step 5: 提交** — `git commit -m "refactor:StageProgressRow 读 PanelSurface 废 nextEffectColor 参数"`

---

### Task 4: section_header

**Files:** Modify `lib/shared/widgets/wuxia_ui/section_header.dart` · Test `test/shared/widgets/wuxia_ui/section_header_surface_test.dart`
- 色映射:标题文字(:29)→`surface.primary`；分隔线描画(:62,:66)→`surface.secondary`。
- 双底测:pump 一个 `SectionHeader('测试标题')` 于两面板下，断言 `_textColor(t,'测试标题')` 浅=`WuxiaUi.ink`/深=`WuxiaColors.textPrimary`。
- TDD 5 步(失败测→确认失败→实现→通过→commit `refactor:section_header 读 PanelSurface`)。

### Task 5: glossary_tip
**Files:** Modify `.../wuxia_ui/glossary_tip.dart` · Test 同名 _surface_test
- 色映射:气泡正文文字(:47,:122)→`surface.primary`；标记/次要(:50,:57)→`surface.secondary`。**注**:若气泡浮层自有独立底色(popup 有自己的 fillColor)，其**浮层内部**文字按浮层底色定、非父面板——实装时读该组件 build 确认气泡底；拿不准渲染实拍(`bash tools/visual_capture/visual_capture.sh`)。仅迁「随父面板底色的行内标签」部分。
- 双底测:对行内标签文字断言两底色。commit `refactor:glossary_tip 读 PanelSurface`。

### Task 6: meridian_bar
**Files:** Modify `.../wuxia_ui/meridian_bar.dart` · Test _surface_test
- 色映射:标签文字(:32)→`surface.primary`；进度条轨/描边(:40)保留(结构色，不动)。
- 双底测:构造带 label 的 MeridianBar 断言标签两底色。commit `refactor:meridian_bar 标签读 PanelSurface`。

### Task 7: error_fallback
**Files:** Modify `.../wuxia_ui/error_fallback.dart` · Test _surface_test
- 色映射:提示文字(:47 ink2)→`surface.primary`；重试按钮走 PlaqueButton 不动。
- 双底测:pump ErrorFallback(error/onRetry stub) 断言提示文字两底色。commit `refactor:error_fallback 文字读 PanelSurface`。

### Task 8: ink_empty_state
**Files:** Modify `.../wuxia_ui/ink_empty_state.dart` · Test _surface_test
- 色映射:说明主文字(:94)→`surface.primary`；副描述(:117,:118 若为次要文字)→`surface.secondary`。图标(:69)/jiang 行动色/边框保留(结构)。
- 双底测:pump InkEmptyState(带文案) 断言主文字两底色。commit `refactor:ink_empty_state 文字读 PanelSurface`。

### Task 9: wuxia_title_bar
**Files:** Modify `.../wuxia_ui/wuxia_title_bar.dart` · Test _surface_test
- 色映射:返回箭头(:52 若 ink)/标题文字(:63,:74)→`surface.primary`；jiang 强调(:96)与分隔描边保留。
- 双底测:pump WuxiaTitleBar(title) 断言标题两底色。commit `refactor:wuxia_title_bar 读 PanelSurface`。

### Task 10: item_slot(仅文字标签)
**Files:** Modify `.../wuxia_ui/item_slot.dart` · Test _surface_test
- 色映射:**仅**物品名/标签文字(:143 若 ink)→`surface.primary`。**tier 金框 gold(:75,:85)/jiang 高亮(:91,:97)保留(结构·品牌·不动)**。
- 双底测:仅对文字标签断言两底色(不测金框)。commit `refactor:item_slot 文字标签读 PanelSurface`。

### Task 11: plaque_button(仅文字标签)
**Files:** Modify `.../wuxia_ui/plaque_button.dart` · Test _surface_test
- 色映射:**仅**按钮内**文字标签**若硬编 ink → `surface.primary`。**绛红渐变/边框(:64,:131,:184 jiang/gold)保留(品牌·不动)**。**注**:按钮标签底色是按钮自身 fill、非父面板——若标签在绛红 fill 上应保持其对比色，**不盲目迁**;实装先判标签坐落底色，仅当标签直接坐父面板底才迁。拿不准→保留原色 + 注释登记，不改。
- 双底测:仅当确迁时加;否则本任务记「核实后无需迁」并跳过代码改。commit `refactor:plaque_button 标签核实(迁/或登记不需迁)`。

### Task 12: paper_dialog(低优先)
**Files:** Modify `.../wuxia_ui/paper_dialog.dart` · Test _surface_test
- paper_dialog 恒浅底(内含 LightPaperPanel 已 provide light)，其硬编 ink/muted 已浅底正确。**改为读 surface 仅为一致性/未来防护**:标题(:91)/正文(:112)→`surface.primary`；表单 hint(:60-70)→按需 primary/secondary。jiang 行动色保留。
- 双底测:因恒浅底，最小断言 pump 于 LightPaperPanel(或 dialog 自身)标题=`WuxiaUi.ink` 即可(不强测深底，dialog 不会深底)。commit `refactor:paper_dialog 文字读 PanelSurface`。

---

### Task 13: 批末验证 gate

- [ ] `flutter analyze lib test` → **0 issues**
- [ ] 全量 `flutter test --no-pub` → **3692+ pass / 0 fail**(新增双底测使总数上升，无回归)
- [ ] `python3 tools/audit_paper_text_contrast.py --root .` → **0 finding**
- [ ] `flutter test --no-pub test/tools/audit_paper_text_contrast_test.dart` → 绿
- [ ] 提交任何收尾 + 更新计划恢复点

**视觉收口(非本批代码 gate)**:两面板下各迁移组件对比度起游戏实拍 → 归晚上目检工作流。

## 自审记录

- **Spec 覆盖**:① PanelSurface API=Task1；② 面板 provide=Task2；③ 逐组件迁移=Task3-12(spec 表 10 组件全覆盖)；④ 废 nextEffectColor=Task3；⑤ 测试=各 Task 双底测+Task13 gate。全覆盖。
- **风险对应**:角色不足→遇到扩(各 Task 实装判);裸用组件深底→双底测+兜底 light;plaque_button/glossary_tip 自有底→Task11/5 显式「先判底再迁、拿不准保留」防误迁。
- **类型一致**:三角色名 primary/secondary/accent 全 Task 统一;of/maybeOf 签名 Task1 定、后续引用一致。
