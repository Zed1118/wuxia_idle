# 剧情阅读屏出版美术 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给主线剧情阅读屏 `NarrativeReaderScreen` 加专属水墨场景图背景 + scrim + 正文浮层装帧（接线基建 0 出图先行，30 张 MJ 图后补）。

**Architecture:** 接线方案 A——`stageNarrativePath(stageId)` helper 推路径 + `NarrativeReaderScreen` 加可选 `backgroundImagePath`（沿 `topBanner` 体例）+ `stage_entry_flow` 三处 wire。背景层 `NarrativeSceneBackground` 仿 `BattleSceneBackground`（图 + scrim + errorBuilder 兜底）。其余调用方不传 → 纯色底兜底。

**Tech Stack:** Flutter / Dart · flutter_test widget 测 · 既有体例 BattleSceneBackground + chapterCoverPath + VisualRoute。

**关键约束（开工必读）：**
- 改 `narrative_reader_screen.dart` / `battle` 共享色板后**必跑全量 `flutter test`**（T16 集成测在 root `test/widget_test.dart`，scoped 会漏，B1/B2 已踩）。
- widget 测不加载真 assets → `Image.asset` 必挂 `errorBuilder`（沿 BattleSceneBackground）。
- 不硬编码中文（走 UiStrings）/ 不破红线 / 保留 G4 轻点 + 跳过 + 占位 + topBanner + 进度 语义。

---

## File Structure

| 文件 | 动作 | 职责 |
|---|---|---|
| `lib/shared/theme/colors.dart` | 改 | 加 `narrativeSceneScrim` token（black 50%，比战斗略重） |
| `lib/features/mainline/domain/chapter_assets.dart` | 改 | 加 `stageNarrativePath(stageId)` 纯函数 |
| `lib/features/narrative/presentation/narrative_scene_background.dart` | 建 | 背景图 + scrim 层（仿 BattleSceneBackground） |
| `lib/features/narrative/presentation/narrative_reader_screen.dart` | 改 | 加 `backgroundImagePath` 参数 + 背景 Stack + 正文浮层 |
| `lib/features/mainline/presentation/stage_entry_flow.dart` | 改 | 三处调用传 `stageNarrativePath(stage.id)` |
| `lib/features/debug/application/visual_route.dart` | 改 | 加 `narrativeScene` 枚举 |
| `lib/features/debug/presentation/visual_route_host.dart` | 改 | 加 `narrativeScene` case |
| `docs/handoff/mj_prompts_narrative_scene_2026-06-01.md` | 建 | 30 条 MJ prompt（交付用户出图） |

---

## Task 1: scrim token + stageNarrativePath helper

**Files:**
- Modify: `lib/shared/theme/colors.dart:37`（在 battleSceneScrim 下加）
- Modify: `lib/features/mainline/domain/chapter_assets.dart`
- Test: `test/features/mainline/domain/chapter_assets_test.dart`（已存在，追加 group）

- [ ] **Step 1: 写失败测试**（追加到 chapter_assets_test.dart 末尾 main() 内）

```dart
  group('stageNarrativePath', () {
    test('stageId → assets/scenes/narrative_<id>.png', () {
      expect(stageNarrativePath('stage_01_01'),
          'assets/scenes/narrative_stage_01_01.png');
      expect(stageNarrativePath('stage_06_05'),
          'assets/scenes/narrative_stage_06_05.png');
    });
  });
```

- [ ] **Step 2: 跑测试验证失败**

Run: `flutter test test/features/mainline/domain/chapter_assets_test.dart`
Expected: FAIL（`stageNarrativePath` 未定义 / 编译错）

- [ ] **Step 3: 实装 helper**（追加到 chapter_assets.dart 末尾）

```dart
/// 主线 stage 剧情背景图路径(出版美术 · 剧情阅读屏)。
/// 约定 `assets/scenes/narrative_<stageId>.png`,无图走 NarrativeSceneBackground
/// errorBuilder 兜底。与 [chapterCoverPath] 同列(单一真相源,不写裸路径)。
String stageNarrativePath(String stageId) => 'assets/scenes/narrative_$stageId.png';
```

- [ ] **Step 4: 加 scrim token**（colors.dart 在 `battleSceneScrim` 行下）

```dart
  static const Color narrativeSceneScrim = Color(0x80000000); // black 50%(正文长文需更重压暗)
```

- [ ] **Step 5: 跑测试验证通过**

Run: `flutter test test/features/mainline/domain/chapter_assets_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/shared/theme/colors.dart lib/features/mainline/domain/chapter_assets.dart test/features/mainline/domain/chapter_assets_test.dart
git commit -m "feat: 剧情背景 stageNarrativePath helper + narrativeSceneScrim token"
```

---

## Task 2: NarrativeSceneBackground widget

**Files:**
- Create: `lib/features/narrative/presentation/narrative_scene_background.dart`
- Test: `test/features/narrative/presentation/narrative_scene_background_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/narrative/presentation/narrative_scene_background.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

void main() {
  testWidgets('path 非空 → 有背景 Image + scrim 遮罩层', (tester) async {
    await tester.pumpWidget(_wrap(const NarrativeSceneBackground(
        path: 'assets/scenes/narrative_stage_01_01.png')));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.narrativeSceneScrim);
    expect(scrim, findsOneWidget);
  });

  testWidgets('path null → SizedBox.shrink(无 Image 无 scrim)', (tester) async {
    await tester.pumpWidget(_wrap(const NarrativeSceneBackground(path: null)));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.narrativeSceneScrim);
    expect(scrim, findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

Run: `flutter test test/features/narrative/presentation/narrative_scene_background_test.dart`
Expected: FAIL（NarrativeSceneBackground 未定义）

- [ ] **Step 3: 实装 widget**

```dart
import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';

/// 剧情阅读场景背景层(出版美术):背景图 + scrim 压暗遮罩。
/// path 空/缺图 → SizedBox.shrink(降级到 reader 纯色底兜底)。
/// Image.asset 挂 errorBuilder(widget 测不加载 assets,守测不破)。
class NarrativeSceneBackground extends StatelessWidget {
  final String? path;
  const NarrativeSceneBackground({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(p, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const ColoredBox(color: WuxiaColors.narrativeSceneScrim),
      ],
    );
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

Run: `flutter test test/features/narrative/presentation/narrative_scene_background_test.dart`
Expected: PASS（2 测）

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrative/presentation/narrative_scene_background.dart test/features/narrative/presentation/narrative_scene_background_test.dart
git commit -m "feat: NarrativeSceneBackground 剧情背景+scrim 层(仿 B1)"
```

---

## Task 3: NarrativeReaderScreen 加背景 + 正文浮层

**Files:**
- Modify: `lib/features/narrative/presentation/narrative_reader_screen.dart`
- Test: `test/features/narrative/presentation/narrative_reader_screen_test.dart`（追加 2 测）

- [ ] **Step 1: 写失败测试**（追加到 narrative_reader_screen_test.dart main() 末，文件顶部加 import）

文件顶加：
```dart
import 'package:wuxia_idle/features/narrative/presentation/narrative_scene_background.dart';
```

main() 内追加：
```dart
  testWidgets('传 backgroundImagePath → 渲染 NarrativeSceneBackground 背景层',
      (tester) async {
    const c = NarrativeContent(
      id: 'x', title: '风雨渡口',
      paragraphs: ['雨夜渡口，撑伞人独立。'], isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c, fallbackTitle: 'fb',
      backgroundImagePath: 'assets/scenes/narrative_stage_01_05.png',
    )));
    expect(find.byType(NarrativeSceneBackground), findsOneWidget);
    expect(find.text('雨夜渡口，撑伞人独立。'), findsOneWidget,
        reason: '正文仍在背景之上正常渲染');
  });

  testWidgets('不传 backgroundImagePath → 无背景层(回归纯色底)', (tester) async {
    const c = NarrativeContent(
      id: 'x', title: 't', paragraphs: ['段'], isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c, fallbackTitle: 'fb',
    )));
    expect(find.byType(NarrativeSceneBackground), findsNothing);
  });
```

- [ ] **Step 2: 跑测试验证失败**

Run: `flutter test test/features/narrative/presentation/narrative_reader_screen_test.dart`
Expected: FAIL（backgroundImagePath 参数不存在 / 编译错）

- [ ] **Step 3: 实装**（narrative_reader_screen.dart）

3a. 文件顶 import：
```dart
import 'narrative_scene_background.dart';
```

3b. widget 构造器加可选参数（在 `this.topBanner,` 后）：
```dart
    this.backgroundImagePath,
```
字段（在 `final Widget? topBanner;` 后）：
```dart
  /// 出版美术:主线 stage 专属背景图路径。null → 纯色底兜底。
  final String? backgroundImagePath;
```

3c. build() 内 `final isLast = ...;` 后加：
```dart
    final bg = widget.backgroundImagePath;
    final hasBg = bg != null && bg.isNotEmpty;
```

3d. Scaffold 的 `backgroundColor: WuxiaColors.background,` 改为：
```dart
      backgroundColor: hasBg ? Colors.transparent : WuxiaColors.background,
```

3e. Scaffold 的 `body: SafeArea(` 整块替换为 Stack 包裹（背景层 + 原 SafeArea）：
```dart
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBg) NarrativeSceneBackground(path: bg),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
```
（原 Column children 不动；注意收尾多补两层 `)` 关闭 Stack 的 SafeArea/Padding，见 3g）

3f. 正文浮层——原正文 `Center(child: SingleChildScrollView(...))` 的 Center child 包墨底容器：
原：
```dart
                  child: Center(
                    child: SingleChildScrollView(
                      child: FadeTransition(
```
改为：
```dart
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: hasBg
                            ? WuxiaColors.background.withValues(alpha: 0.55)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: FadeTransition(
```
（对应在 SingleChildScrollView 收尾多补一层 `)` 关闭 Container）

3g. 收尾括号：原 body 结构 `SafeArea→Padding→Column` 末尾是
```dart
            ],
          ),
        ),
      ),
```
现包进 Stack，改为：
```dart
                ],
              ),
            ),
          ),
        ],
      ),
```

- [ ] **Step 4: 跑全量测试验证通过**

Run: `flutter test`
Expected: PASS（现有 narrative reader 13 测回归全过 + 新 2 测 + 全量绿；改 reader 必跑全量，T16 在 root）

- [ ] **Step 5: analyze**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Commit**

```bash
git add lib/features/narrative/presentation/narrative_reader_screen.dart test/features/narrative/presentation/narrative_reader_screen_test.dart
git commit -m "feat: 剧情阅读屏加背景层+正文墨底浮层(出版美术)"
```

---

## Task 4: stage_entry_flow 三处 wire

**Files:**
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`（opening ~80 / defeat ~120 / victory ~179 三处 NarrativeReaderScreen 调用）

- [ ] **Step 1: 加 import**（stage_entry_flow.dart 顶，import 区）

```dart
import '../domain/chapter_assets.dart';
```

- [ ] **Step 2: 三处调用各加一行参数**

每处 `NarrativeReaderScreen(` 构造里（与 `content:` / `fallbackTitle:` 同级）加：
```dart
          backgroundImagePath: stageNarrativePath(stage.id),
```
（三处都在 `runStageFlow` 内，`stage` 在作用域内可直接用。defeat 处已有 `topBanner: lossBanner,`，并列加即可。）

- [ ] **Step 3: 跑全量测试**

Run: `flutter test`
Expected: PASS（stage flow widget 测不加载真图，背景层 errorBuilder shrink，不破）

- [ ] **Step 4: analyze**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/mainline/presentation/stage_entry_flow.dart
git commit -m "feat: 主线 stage_entry_flow 三处剧情接背景图"
```

---

## Task 5: 验收路由 narrativeScene

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`（加枚举）
- Modify: `lib/features/debug/presentation/visual_route_host.dart`（加 case + import）
- Test: `test/features/debug/visual_route_test.dart`（追加 parse 断言）

- [ ] **Step 1: 写失败测试**（visual_route_test.dart 的 'B2 新路由 parse' test 后追加）

```dart
    test('剧情背景路由 parse', () {
      expect(parseVisualRoute('narrative_scene'),
          VisualRoute.narrativeScene);
    });
```

- [ ] **Step 2: 跑测试验证失败**

Run: `flutter test test/features/debug/visual_route_test.dart`
Expected: FAIL（narrativeScene 未定义）

- [ ] **Step 3: 加枚举**（visual_route.dart，在 `battleBossFrame(...)` 后；注意把前一行结尾 `;` 移到本行）

将 `battleBossFrame('battle_boss_frame', '...');` 末尾 `;` 改为 `,`，其后加：
```dart
  narrativeScene('narrative_scene',
      '剧情阅读屏·专属背景图 + scrim + 正文浮层验收(stage_01_05 风雨渡口)');
```

- [ ] **Step 4: 加 host case**（visual_route_host.dart）

import 区加：
```dart
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../data/narrative_loader.dart';
import '../../mainline/domain/chapter_assets.dart';
```
（`narrative_loader` 提供 `NarrativeContent`；若已 import 则跳过重复）

switch 内 `case VisualRoute.battleBossFrame:` 块后加：
```dart
        case VisualRoute.narrativeScene:
          target = NarrativeReaderScreen(
            content: const NarrativeContent(
              id: 'visual_narrative',
              title: '风雨渡口',
              paragraphs: [
                '雨脚如麻,渡口的灯笼在风里摇得不成样子。你立在栈桥尽头,'
                    '看那撑伞的人一步一停,伞沿压得极低,看不清脸。\n\n'
                    '江水拍着木桩,一下,又一下。你握紧了腰间的剑——'
                    '这一程的恩怨,该在今夜了结了。',
              ],
              isPlaceholder: false,
            ),
            fallbackTitle: '风雨渡口',
            backgroundImagePath: stageNarrativePath('stage_01_05'),
          );
```

- [ ] **Step 5: 跑测试验证通过**

Run: `flutter test test/features/debug/visual_route_test.dart`
Expected: PASS（含新 parse + '每个枚举 id 往返一致' 自动覆盖新枚举）

- [ ] **Step 6: 全量 + analyze**

Run: `flutter test && flutter analyze`
Expected: 全量 PASS / 0 issues

- [ ] **Step 7: Commit**

```bash
git add lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart test/features/debug/visual_route_test.dart
git commit -m "feat: 剧情背景验收路由 narrative_scene"
```

---

## Task 6: 30 条 MJ prompt 文档（交付用户出图）

**Files:**
- Create: `docs/handoff/mj_prompts_narrative_scene_2026-06-01.md`

- [ ] **Step 1: 产 30 条 prompt**

按 spec 出图清单 30 stage（id / biome / 场景），逐条产 MJ prompt：
- 沿 `feedback_mj_wuxia_prompt_pitfalls`：水墨厚涂 ink-wash painting / **16:9 横构图作背景** `--ar 16:9` / **中间留暗区/留白给正文浮层** / 低饱和青墨宣纸调 / **无人物主体**（场景为主）/ 与 biome + 剧情题材对位（如 dock 风雨渡口=雨夜栈桥灯笼、desert 昆仑山外=雪山大漠）。
- **输出格式**（memory `feedback_mj_prompt_batch_output_format`）：文档正文里 30 条 prompt **不加标题/序号**，空一行后连续输出，prompt 之间空行分隔，便于整段复制。文件头部可写一行用途说明 + 文件名→stage 对照表，但 prompt 区块本身纯文本空行分隔。
- 文件名约定写清：每条 prompt 对应 `assets/scenes/narrative_<stageId>.png`。

- [ ] **Step 2: Commit**

```bash
git add docs/handoff/mj_prompts_narrative_scene_2026-06-01.md
git commit -m "docs: 剧情背景 30 条 MJ prompt(交付出图)"
```

---

## 验收（基建合并后）

- 全量 `flutter test` 绿 + `flutter analyze` 0。
- Codex 视觉验收（沿 `feedback_codex_visual_acceptance_mac` + B2 派单体例）：`flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene`，验 scrim 深浅 / 正文墨底浮层可读性 / 缺图兜底纯色底不破。**图未到位也先验装帧**；用户出图归位后复验背景题材对位。
- scrim 50% / 浮层 alpha 0.55 **先看效果再调**（Codex 反馈后微调 token）。

## Self-Review 记录

- **Spec coverage**：接线 A（T1+T3+T4）/ 装帧背景层（T2+T3）/ 正文浮层（T3）/ 兜底（T2+T3 errorBuilder+条件）/ 验收路由（T5）/ 30 MJ prompt（T6）/ 测试计划（各 task TDD）——全覆盖。
- **范围**：只主线 wire（T4），支线不传走兜底，符 spec。
- **类型一致**：`stageNarrativePath` / `NarrativeSceneBackground(path:)` / `backgroundImagePath` / `narrativeSceneScrim` 跨 task 命名一致。
