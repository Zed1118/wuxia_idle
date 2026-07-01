# 新手前 30 分钟体验打磨 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 打磨新手前 30 分钟体验的 4 处可读性缺口（祖师塑形决策可逆说明 / 首胜整备提示 / 普通关失败短诊断 / 选关页 replay 提示行门控），全部纯展示层。

**Architecture:** 新增文案全进 `UiStrings`；S1/S2/S3 加静态提示 Text（S3 抽公开 `StageRetryDialogBody` 便于单测）；S4 抽共享常量 + 照 goalGuidance 同链透传一个 `replayRewardUnlocked` bool，把 `_ReplayRewardRouteLine` 门控到「已通 stage_01_05」。零碰 numbers/结算/saveVer/schema/三系锁死/在线=离线。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar；测试 `flutter test --no-pub -j1`；lint `flutter analyze lib/ test/`。

**基线（本会话主 checkout 实测）：** `flutter test --no-pub -j1` 3526 passed/1 skip/0 fail；`analyze lib/ test/` 0。（注：本 worktree 需先预热 pub get + cp libisar.dylib + build_runner 才能跑测，见 memory `feedback_subagent_driven_fresh_worktree_env_prep`。）

**色板守则：** `founder_creation_screen`=深底 → `WuxiaColors.text*`；`stage_victory_dialog` / `PaperDialog`=浅纸底 → `WuxiaUi.ink/ink2/muted`。

---

### Task 1: S1 · 祖师塑形确认区补决策可逆说明

**Files:**
- Modify: `lib/shared/strings.dart`（`founderCreateConfirmLine` 附近，约 line 1901）
- Modify: `lib/features/onboarding/presentation/founder_creation_screen.dart:425-436`（确认区 Column）
- Test: `test/features/onboarding/founder_creation_screen_hint_test.dart`（新建）

- [ ] **Step 1: 加文案常量**

在 `lib/shared/strings.dart` 的 `founderCreateConfirmLine(...)` 定义（约 line 1901-1905）**上方**插入：

```dart
  static const String founderCreateReversibleHint =
      '起手选择只影响开局手感,日后可用装备、修炼补足,不必纠结。';
```

- [ ] **Step 2: 写失败测试**

新建 `test/features/onboarding/founder_creation_screen_hint_test.dart`。参照同目录 `founder_creation_onboarding_test.dart` 的 `setUpAll`（`Isar.initializeIsarCore` + `GameRepository.loadAllDefs`）装配 GameRepository，然后 pump 屏并断言提示串出现：

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  testWidgets('祖师塑形确认区显示决策可逆提示', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: FounderCreationScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.founderCreateReversibleHint),
      findsOneWidget,
      reason: '确认区应显示决策可逆说明',
    );
  });
}
```

> 注：若 `FounderCreationScreen` 构造需参数或预览区默认不渲染（需先选流派/出身/命盘），参照 `founder_creation_screen.dart` 的 state 初始默认选择 —— 该屏默认高亮首个选项即渲染预览卡，pumpAndSettle 后确认区可见。如构造签名不同，按屏实际签名传入。

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/onboarding/founder_creation_screen_hint_test.dart --no-pub`
Expected: FAIL —— `founderCreateReversibleHint` 未在屏渲染（findsNothing）。

- [ ] **Step 4: 实装 —— 确认区加提示 Text**

在 `founder_creation_screen.dart` 确认区 Column（现 line 426-436 是 `founderCreateConfirmLine` 的 Text，结束于 line 436 的 `),`）**之后、`],`（line 437）之前**插入：

```dart
          const SizedBox(height: 6),
          const Text(
            UiStrings.founderCreateReversibleHint,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
```

（`WuxiaColors` 已在该文件 import；深底次要色 `textMuted`。）

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/onboarding/founder_creation_screen_hint_test.dart --no-pub`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add lib/shared/strings.dart lib/features/onboarding/presentation/founder_creation_screen.dart test/features/onboarding/founder_creation_screen_hint_test.dart
git commit -m "feat: 祖师塑形确认区补决策可逆说明(S1)"
```

---

### Task 2: S3 · 普通关失败弹框补非教学化短诊断

**Files:**
- Modify: `lib/shared/strings.dart`（`stageRetryPrompt` 附近，line 50-51）
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart:427-448`（抽 `StageRetryDialogBody` + 用它）
- Test: `test/features/mainline/presentation/stage_retry_dialog_body_test.dart`（新建）

- [ ] **Step 1: 加文案常量**

在 `lib/shared/strings.dart` line 51（`stageRetryPrompt` 定义）**下方**插入：

```dart
  static const String stageRetryHintLine = '可回行囊换装备,或先去别处历练再来。';
```

- [ ] **Step 2: 写失败测试**

新建 `test/features/mainline/presentation/stage_retry_dialog_body_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('StageRetryDialogBody 同时显示提示与短诊断', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StageRetryDialogBody())),
    );

    expect(find.text(UiStrings.stageRetryPrompt), findsOneWidget);
    expect(find.text(UiStrings.stageRetryHintLine), findsOneWidget);
  });
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/mainline/presentation/stage_retry_dialog_body_test.dart --no-pub`
Expected: FAIL —— `StageRetryDialogBody` 类不存在（编译错误）。

- [ ] **Step 4: 实装 —— 抽公开 body widget + 用它**

在 `stage_entry_flow.dart` 中，把 `_showStageRetryDialog`（line 427-448）的 `body:` 从 `const Text(UiStrings.stageRetryPrompt)` 改为 `const StageRetryDialogBody()`：

```dart
  final retry = await PaperDialog.show<bool>(
    context,
    title: UiStrings.stageRetryTitle,
    body: const StageRetryDialogBody(),
    actions: [
```

并在该文件末尾（`_showStageRetryDialog` 函数之后）新增公开 widget：

```dart
/// 普通关战败弹框正文：提示 + 非教学化补强短诊断（S3 新手打磨）。
/// 抽成公开 widget 便于单测（对话框本体私有、测试 harness 注入替换）。
class StageRetryDialogBody extends StatelessWidget {
  const StageRetryDialogBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(UiStrings.stageRetryPrompt),
        SizedBox(height: 8),
        Text(
          UiStrings.stageRetryHintLine,
          style: TextStyle(color: WuxiaUi.muted, fontSize: 13),
        ),
      ],
    );
  }
}
```

确认 `stage_entry_flow.dart` 顶部已 import `WuxiaUi`（`import '../../../shared/theme/wuxia_tokens.dart';`）；若无则加。

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/mainline/presentation/stage_retry_dialog_body_test.dart --no-pub`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add lib/shared/strings.dart lib/features/mainline/presentation/stage_entry_flow.dart test/features/mainline/presentation/stage_retry_dialog_body_test.dart
git commit -m "feat: 普通关失败弹框补非教学化短诊断(S3)"
```

---

### Task 3: S2 · 首胜装备掉落后整备轻提示

**Files:**
- Modify: `lib/shared/strings.dart`（`stageVictoryEquipmentSection` 附近，约 line 1378）
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart:254-263`（装备段末尾）
- Test: `test/features/mainline/presentation/stage_victory_dialog_test.dart`（追加 case，复用现有 `setUpAll` + pump helper）

- [ ] **Step 1: 加文案常量**

在 `lib/shared/strings.dart` line 1378（`stageVictoryEquipmentSection` 定义）**下方**插入：

```dart
  static const String stageVictoryEquipmentHint = '可回行囊查看 / 整备新装备。';
```

- [ ] **Step 2: 写失败测试**

在 `test/features/mainline/presentation/stage_victory_dialog_test.dart` 追加一个 `testWidgets`。复用文件顶部既有 helper：`_stage()`、pump 方式（现有测试在约 line 144 用 `tester.pumpWidget(MaterialApp(home: Scaffold(body: StageVictoryContent(...))))`）。参照现有「掉装备」用例构造带 `drops.equipments` 非空的 `StageVictoryContent`，断言提示串出现；再构造空装备断言不出现。用文件已有的装备掉落构造模式（现有测试已有 resonance/equipment 段用例，约 line 258-262，复用其 `DropResult(equipments: [...])` 造法）：

```dart
    testWidgets('掉装备时显示整备提示 / 无装备时不显示', (tester) async {
      // 掉装备 → 提示出现（equipments 构造复用本文件既有装备掉落用例的 DropResult 造法）
      await pumpVictory(tester, drops: dropsWithEquipment());
      expect(
        find.text(UiStrings.stageVictoryEquipmentHint),
        findsOneWidget,
      );

      // 无装备 → 提示不出现
      await pumpVictory(tester, drops: _emptyDrops());
      expect(
        find.text(UiStrings.stageVictoryEquipmentHint),
        findsNothing,
      );
    });
```

> 注：`pumpVictory` / `dropsWithEquipment` 用本文件既有 pump 与掉装备构造模式命名（现文件在装备段用例已构造过 equipment DropResult，直接复用其造法与 pump 调用；`_emptyDrops()` 已存在于文件顶部）。

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart --no-pub`
Expected: FAIL —— 掉装备用例找不到 `stageVictoryEquipmentHint`。

- [ ] **Step 4: 实装 —— 装备段末尾加提示**

在 `stage_victory_dialog.dart` 的装备段 Column（line 245-261）内，装备 `for` 循环（line 254-260）**之后**插入：

```dart
                      if (drops.equipments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _VictoryMutedLine(UiStrings.stageVictoryEquipmentHint),
                      ],
```

（复用文件内既有 `_VictoryMutedLine`（line 360-375），浅纸底 `WuxiaUi.muted`，与卷宗其他 muted 行一致。）

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart --no-pub`
Expected: PASS（含既有全部用例）

- [ ] **Step 6: 提交**

```bash
git add lib/shared/strings.dart lib/features/mainline/presentation/stage_victory_dialog.dart test/features/mainline/presentation/stage_victory_dialog_test.dart
git commit -m "feat: 首胜掉装备后补回行囊整备轻提示(S2)"
```

---

### Task 4: S4 · 选关页 replay 提示行门控（通 stage_01_05 前隐藏）

**Files:**
- Create: `lib/features/mainline/domain/onboarding_gate.dart`（共享常量）
- Modify: `lib/features/mainline/presentation/stage_list_screen.dart`（透传 `replayRewardUnlocked` bool + 门控 line 991）
- Test: `test/features/mainline/presentation/stage_list_screen_test.dart`（翻转现有 line 117 用例 replay 断言 + 新增门槛用例）

- [ ] **Step 1: 建共享常量**

新建 `lib/features/mainline/domain/onboarding_gate.dart`：

```dart
/// 新手内容门槛：通关第一章末 Boss（stage_01_05）后才展现复刷类辅助信息，
/// 避免新档前几关被 replay/扫荡工具稀释「先把主线往前推」的清晰度。
/// 与主菜单社交系统解锁同一关（main_menu `_socialUnlockStage`）。
const String kFirstChapterFinalStageId = 'stage_01_05';
```

- [ ] **Step 2: 写失败测试（翻转 line 117 + 新增门槛用例）**

在 `test/features/mainline/presentation/stage_list_screen_test.dart`：

(a) 现有用例 `'Ch1 通过 01 → 01 cleared + 02 available + 03-05 锁'`（line 117-138）只通 `stage_01_01`，其 replay 断言（line 135-137）需**翻转为不显示**（S4 后未通 stage_01_05 → replay 隐藏）：

```dart
    // S4：仅通 stage_01_01（未通章末 stage_01_05）→ replay 提示行隐藏（新手门槛）。
    expect(find.text(UiStrings.stageReplayRouteTitle), findsNothing);
    expect(find.text(UiStrings.stageReplayRouteEquipment), findsNothing);
    expect(find.text(UiStrings.stageReplayRouteMaterial), findsNothing);
```

(b) 追加一个门槛用例（通 stage_01_05 后 replay 恢复显示）：

```dart
  testWidgets('S4：通关 stage_01_05 后已通关行恢复显示 replay 提示行', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(
        cleared: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
        ],
      ),
    );

    expect(find.text(UiStrings.stageReplayRouteTitle), findsWidgets);
  });
```

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/features/mainline/presentation/stage_list_screen_test.dart --no-pub`
Expected: FAIL —— (a) 翻转后的用例当前仍显示 replay（findsNothing 失败），证明改动前行为是「过早显示」。

- [ ] **Step 4: 实装 —— 透传 bool + 门控**

4a. `stage_list_screen.dart` 顶部 import 常量：

```dart
import '../domain/onboarding_gate.dart';
```

4b. 在计算 `sweepEligible`/`everCleared` 的同一 builder 作用域（约 line 145 之后、`return LayoutBuilder` 之前）加：

```dart
            final replayRewardUnlocked =
                progress != null &&
                progress.clearedStageIds.contains(kFirstChapterFinalStageId);
```

4c. `_ChapterStageTimeline` 调用处（line 175-181，现传 `goalGuidance: currentGoal`）加参：

```dart
                          replayRewardUnlocked: replayRewardUnlocked,
```

4d. `_ChapterStageTimeline` 类（line 390-407）加字段 + 构造参数（照 `goalGuidance` 同款）：

```dart
    this.replayRewardUnlocked = false,
```
```dart
  final bool replayRewardUnlocked;
```

并在其内部 `_TimelineStageStop` 调用处（约 line 425-436）透传：

```dart
                replayRewardUnlocked: replayRewardUnlocked,
```

4e. `_TimelineStageStop` 类（line 488-511）加字段 + 构造参数：

```dart
    this.replayRewardUnlocked = false,
```
```dart
  final bool replayRewardUnlocked;
```

并在其内部 `_StageRow` 调用处（line 539 附近）透传：

```dart
              replayRewardUnlocked: replayRewardUnlocked,
```

4f. `_StageRow` 类（line 817-838）加字段 + 构造参数：

```dart
    this.replayRewardUnlocked = false,
```
```dart
  final bool replayRewardUnlocked;
```

4g. 门控 replay 行：`_StageRow.build` 内 line 991 `if (cleared)` 改为：

```dart
                    if (cleared && replayRewardUnlocked)
                      _ReplayRewardRouteLine(
                        route: MainlineReplayRewardRoute.fromStage(def),
                      ),
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/features/mainline/presentation/stage_list_screen_test.dart --no-pub`
Expected: PASS（含翻转用例 + 新门槛用例 + 现有 194/216/235 通 stage_01_05 的用例仍绿）。

- [ ] **Step 6: 提交**

```bash
git add lib/features/mainline/domain/onboarding_gate.dart lib/features/mainline/presentation/stage_list_screen.dart test/features/mainline/presentation/stage_list_screen_test.dart
git commit -m "feat: 选关页replay提示行门控通stage_01_05前隐藏(S4)"
```

---

### Task 5: 批末收口验证

- [ ] **Step 1: 全仓 analyze**

Run: `flutter analyze lib/ test/`
Expected: `No issues found!`

- [ ] **Step 2: 全量测试**

Run: `flutter test --no-pub -j1`
Expected: All tests passed（基线 3526 → 净增 4 新测 = ~3530 passed/1 skip/0 fail）。

- [ ] **Step 3: 常规视口 smoke（可选，UI 改动目检交主窗口/真机）**

S1/S2/S3/S4 均纯静态展示，widget 测已覆盖渲染；真机手感目检（1280×720 / 1440×900）随合并前 `flutter run -d macos` 批做，非本 plan 阻塞项。

---

## 验收对齐 spec

- S1 ✅ Task 1 / S3 ✅ Task 2 / S2 ✅ Task 3 / S4 ✅ Task 4；S5 已在 spec 证伪删除，无对应 task。
- 红线：全程零碰 numbers/结算/saveVer/schema/三系锁死/在线=离线；新增中文全进 `UiStrings`；色板深/浅底不混（S1 `WuxiaColors.textMuted` / S2·S3 `WuxiaUi.muted`）。
