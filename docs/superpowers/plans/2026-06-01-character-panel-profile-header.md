# 角色页档案化（半身像档案头）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把角色页头部从「窄色条+姓名+境界」+ 独立属性 section，合成一张「立绘+身份+4 属性」武侠档案卡。

**Architecture:** 单文件 widget 重组——新 `_ProfileHeaderCard` 替换 `_TopBar`，折并删除 `_AttributesSection`，复用既有 `PortraitFrame`/`_PanelCard`/`_LabeledValue`/`EnumL10n`，零新组件零新色板。

**Tech Stack:** Flutter + Riverpod（provider override 测试）+ 既有 `Character.portraitPath`（Isar 0.15）。

设计 spec：`docs/superpowers/specs/2026-06-01-character-panel-profile-header-design.md`

---

## File Structure

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/features/character_panel/presentation/character_panel_screen.dart` | 角色页 | 加 `PortraitFrame` import / 新 `_ProfileHeaderCard` 替 `_TopBar` / `_Body` 接线 / 删 `_AttributesSection` |
| `test/features/character_panel/presentation/character_panel_screen_test.dart` | 角色页 widget 测 | 加 `PortraitFrame` import + 1 档案头 testWidgets |

---

## Task 1: 档案头卡（立绘 + 身份 + 流派名 + 4 属性）

**Files:**
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`（import 段 / `_Body:228,231` / `_TopBar` 类 248-290 / `_AttributesSection` 类 364-410）
- Test: `test/features/character_panel/presentation/character_panel_screen_test.dart`（import 段 + 新 testWidgets）

- [ ] **Step 1: 写失败测试**

在 `character_panel_screen_test.dart` 顶部 import 段加（与既有 import 同组）：

```dart
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';
```

在用例 1（`testWidgets('3 装备槽全装备时...`，约 172 行）**之前**插入新用例：

```dart
  // ── 用例 0：档案头 ─────────────────────────────────────────────────────

  testWidgets('档案头:立绘 + 姓名 + 境界 + 流派名 + 4 属性聚成一卡',
      (tester) async {
    // mkCharacter 默认 school=gangMeng / attrs 全 5 / 无心法 → 「刚猛」仅出现在档案头
    final character = mkCharacter();
    await pumpPanel(tester, character: character);

    expect(find.byType(PortraitFrame), findsOneWidget);
    expect(find.text('测试者'), findsOneWidget); // 姓名
    expect(find.text('刚猛'), findsOneWidget); // EnumL10n.school(gangMeng)
    expect(find.text('根骨'), findsOneWidget);
    expect(find.text('悟性'), findsOneWidget);
    expect(find.text('身法'), findsOneWidget);
    expect(find.text('机缘'), findsOneWidget);
  });
```

- [ ] **Step 2: 跑测试确认 RED**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart --plain-name '档案头'`
Expected: FAIL —— 现 `_TopBar` 无 `PortraitFrame`（`find.byType(PortraitFrame)` findsNothing）且只显流派色条不显「刚猛」文字（`find.text('刚猛')` findsNothing）。属性 4 label 现由 `_AttributesSection` 渲染会通过，但整体用例因前两条 fail。

- [ ] **Step 3: 实装 —— import + 新 `_ProfileHeaderCard`**

在 `character_panel_screen.dart` import 段加（按字母序，`shared/theme/...` 之后、`shared/strings` 附近，沿现有相对路径体例）：

```dart
import '../../../shared/widgets/portrait_frame.dart';
```

把 `_TopBar` 类（约 248-290 行）**整体替换**为：

```dart
/// 角色档案头:立绘 + 姓名 + 境界·层 + 流派名 + 4 基础属性,聚成一张武侠档案卡。
/// 立绘走 [PortraitFrame](portraitPath 为 null 时优雅退占位)。
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(character.school!);
    final a = character.attributes;
    return _PanelCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortraitFrame(
            portraitPath: character.portraitPath,
            size: 110,
            borderColor: schoolColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      EnumL10n.realm(
                        character.realmTier,
                        character.realmLayer,
                      ),
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (character.school != null) ...[
                      const SizedBox(width: 10),
                      Container(width: 3, height: 12, color: schoolColor),
                      const SizedBox(width: 6),
                      Text(
                        EnumL10n.school(character.school!),
                        style: TextStyle(color: schoolColor, fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: WuxiaColors.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledValue(
                        label: UiStrings.attrConstitution,
                        value: '${a.constitution}',
                      ),
                    ),
                    Expanded(
                      child: _LabeledValue(
                        label: UiStrings.attrEnlightenment,
                        value: '${a.enlightenment}',
                      ),
                    ),
                    Expanded(
                      child: _LabeledValue(
                        label: UiStrings.attrAgility,
                        value: '${a.agility}',
                      ),
                    ),
                    Expanded(
                      child: _LabeledValue(
                        label: UiStrings.attrFortune,
                        value: '${a.fortune}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 实装 —— `_Body` 接线 + 删 `_AttributesSection`**

在 `_Body.build`（约 222-244 行）改两处：

把 `_TopBar(character: character),`（228 行）改为：

```dart
          _ProfileHeaderCard(character: character),
```

把下面这三行（230-232 行,`_BreakthroughBlockerSection` 之后到 `_DerivedStatsSection` 之前）：

```dart
          const SizedBox(height: 16),
          _AttributesSection(character: character),
          const SizedBox(height: 16),
```

替换为（去掉属性 section + 去重一个 SizedBox，保留 blocker 与 derived 之间单间距）：

```dart
          const SizedBox(height: 16),
```

删除 `_AttributesSection` 整个类（约 364-410 行，`class _AttributesSection extends StatelessWidget { ... }` 连同其上方注释，到 `_DerivedStatsSection` 之前）。`_LabeledValue` / `_SectionTitle` / `_PanelCard` 是共用 helper **保留不删**。

- [ ] **Step 5: 跑档案头测试确认 GREEN**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart --plain-name '档案头'`
Expected: PASS

- [ ] **Step 6: 跑角色页全测试文件回归 + analyze**

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart`
Expected: 全过（16 存量 + 1 新 = 17 测）—— 存量测无一断言属性 label / `基础属性` 标题，删 section 不影响。

Run: `flutter analyze lib/features/character_panel/presentation/character_panel_screen.dart`
Expected: No issues found（`_AttributesSection` 删后无残留引用；`_TopBar` 已无引用）。

- [ ] **Step 7: Commit**

```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart test/features/character_panel/presentation/character_panel_screen_test.dart
git commit -m "feat: 角色页档案头(立绘+身份+流派名+4属性聚成档案卡)"
```

---

## Task 2: 全量验证 + 视觉验收基建

**Files:** 无代码改动（验证 + 可选 VISUAL_ROUTE 核对）

- [ ] **Step 1: 全量测试 + analyze**

Run: `flutter analyze`
Expected: No issues found
Run: `flutter test`
Expected: 全绿（baseline 1627 + 1 新档案头 = 1628 测 / 1 skip）

- [ ] **Step 2: 视觉验收 route 核对（不改代码，确认可直达角色页）**

Run: `grep -rn "VISUAL_ROUTE" lib/ | grep -i "character\|panel"`
- 若已有直达角色页的 route id：记录 id，供 Codex 验收派单用。
- 若无：本切片**不新增** route（角色页可经主菜单→角色正常进入），视觉验收走正常导航截图。记录此结论即可，不扩范围。

- [ ] **Step 3: 视觉验收派单（人工/Codex · 非 CLI 步骤）**

构建：`flutter build macos --debug`（如有角色页 VISUAL_ROUTE 则带 `--dart-define=VISUAL_ROUTE=<id>`）。
Codex（Mac 本地）截角色页，判验收门：立绘 + 姓名题字 + 境界/流派 + 4 属性聚成一张「档案卡」观感，不再表格堆叠；无图角色（如有）不空框破布局。

---

## Self-Review

**1. Spec coverage：**
- 新 `_ProfileHeaderCard`（立绘+身份+流派名+4 属性）→ Task 1 Step 3 ✓
- 删 `_AttributesSection` 折进档案头 → Task 1 Step 4 ✓
- 复用 `PortraitFrame`/`_PanelCard`/`_LabeledValue`，不新组件不新色板 → Step 3 代码 ✓
- 流派名 `EnumL10n.school`（补现状缺）→ Step 3 ✓
- 无图优雅退化 → `PortraitFrame` 既有行为（spec OUT 已覆盖测）✓
- 测试纪律（断言按 label 文本 / 守 analyze 0 + 全量绿）→ Task 1 Step 5-6 + Task 2 ✓
- OUT 项（装备槽/派生/心法/师承/装备列表详情/其余养成屏 不动）→ plan 仅改 `_TopBar`+`_AttributesSection`+`_Body` 三处 ✓
- 视觉验收 → Task 2 Step 3 ✓

**2. Placeholder scan：** 无 TBD/TODO；所有代码步骤含完整 Dart。✓

**3. Type consistency：**
- `_ProfileHeaderCard({required Character character})` 与 `_Body` 调用一致 ✓
- `EnumL10n.realm(RealmTier, RealmLayer)` / `EnumL10n.school(TechniqueSchool)` 签名与既有 `_TopBar` 用法 + `enum_localizations.dart:20` 一致 ✓
- `Character.school: TechniqueSchool?`（`character.dart:41`）→ `character.school!` 传 `EnumL10n.school` 类型匹配 ✓
- `_LabeledValue({required String label, required String value})` 与既有 `_AttributesSection` 用法一致 ✓
- `WuxiaColors.{textPrimary,textSecondary,textMuted,border,schoolColor}` 均现有（`_TopBar` 已用）✓
- `PortraitFrame({required String? portraitPath, required double size, required Color borderColor})` 与 `portrait_frame.dart` 签名一致 ✓
