# Widget Test Pattern · NavigatorObserver Mock 套路（2026-05-17 沉淀）

> Nightshift T05 产出。W17 #31 销账（commit `4aa54fa`）的工程教训项目级沉淀。
> 适用场景：主菜单 / 通用 navigation 入口 push 按钮的 widget test，子屏内部 watch Isar 异步 provider 会触发 pumpAndSettle 死循环。
> 此模式 = Phase 5 #2 销账 #28（Consumer 化 + provider override 套路）的轻量化版本。

---

## 1. 问题陈述

### 根因

`tap 按钮 → Navigator.push 子屏 → 子屏内部 watch 异步 provider → CircularProgressIndicator 无限动画 → pumpAndSettle 永不完成`

具体路径（问鼎九霄为例）：

```
tap(mainMenuTower)
  └─ push TowerFloorListScreen
       └─ watch towerProgressProvider  ← FutureProvider / AsyncValue.loading
            └─ CircularProgressIndicator  ← 动画帧持续产生
                 └─ pumpAndSettle 等待所有帧静止 ← 永不满足 → 死循环
```

### 历史

W6 drift 5 轮探路均无解：

| 轮次 | 尝试方案 | 失败原因 |
|---|---|---|
| 1 | 直接 `pumpAndSettle()` | 超时，TowerFloorListScreen AsyncValue.loading 动画不停 |
| 2 | `pump(Duration(seconds: 5))` | 子屏异步 provider 仍未 resolve，CPI 继续转 |
| 3 | fake_async + `fakeAsync` 包裹 | native Isar zone 不可 fake，报 zone 边界错 |
| 4 | 在 test 内注入 Isar fixture | TowerFloorListScreen 有多个嵌套 provider，依赖链难以完整 override |
| 5 | 直接 skip 该测试 | 挂账 #31，留 W17 销账 |

**W17 销账路径**：换一个思路——不验证子屏内容，只验 `Navigator.push` 本身被触发，完全规避子屏 build 带来的异步问题。

---

## 2. 真解 · NavigatorObserver Mock + 单帧 pump

### 完整可运行代码（来自 `test/features/main_menu/presentation/main_menu_test.dart:112`）

```dart
// ── 测试用例 ─────────────────────────────────────────────────────────────────
testWidgets('tap 问鼎九霄 → Navigator.push 触发（不 settle 子屏，#31 销账）',
    (tester) async {
  final observer = _RecordingNavigatorObserver();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorObservers: [observer],
        home: const MainMenu(),
      ),
    ),
  );
  // 验证 initial push（MainMenu 自身）已记录
  expect(observer.pushedRoutes.length, 1);

  await tester.tap(find.text(UiStrings.mainMenuTower));
  await tester.pump(); // 单帧，不 settle：子屏 AsyncValue.loading 不阻塞断言

  // tap 后应有 1 次新 push（TowerFloorListScreen）
  expect(observer.pushedRoutes.length, 2);
  // 验证最新 push 是 MaterialPageRoute（_push 包装）
  expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
});

// ── Observer 类（文件末尾，供同文件所有 push 测试复用）───────────────────────
/// 记录 Navigator.push 调用的 observer（W17 #31 销账）：
/// 测试 tap 按钮触发 push 时使用，代替对子屏的真实 build/settle。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
```

### 关键点逐行解读

| 行为 | 说明 |
|---|---|
| `navigatorObservers: [observer]` | 把 observer 注入 MaterialApp，所有 push/pop 均经过它 |
| `expect(pushedRoutes.length, 1)` | tap 前：initial route（MainMenu 本身）已触发 didPush，断言基线 |
| `await tester.pump()` | **单帧**，不 `pumpAndSettle`——子屏可以处于 loading 状态，不影响断言 |
| `expect(pushedRoutes.length, 2)` | tap 后：新增 1 次 push，基线从 1 变 2 |
| `isA<MaterialPageRoute<void>>()` | 验证路由类型是 `_push` 包裹的 `MaterialPageRoute`，而非 Dialog / BottomSheet |

---

## 3. 套路核心

**三个设计决策，缺一不可：**

### 3.1 不验证子屏内容，只验 push 触发

降低验收范围 = 降低测试风险。入口按钮的职责是「触发正确的 push」，子屏内容的正确性属于子屏自己的测试域。强行在入口测试里 settle 子屏是越界验收，带来不必要的依赖。

### 3.2 单帧 `tester.pump()` 不 settle

`pumpAndSettle` 会等所有动画帧完成。子屏有 `CircularProgressIndicator`（或任何 `Animation`）时，`pumpAndSettle` 永远等不到静止。`tester.pump()` 只执行一帧，push 本身（同步操作）在这一帧内完成，`observer.pushedRoutes` 即已更新，断言可立即执行。

### 3.3 NavigatorObserver 是 Flutter 标准 API

`NavigatorObserver` 是 `package:flutter/material.dart` 内置接口，无需引入任何 mock 库（`mocktail`、`mockito` 等）。`_RecordingNavigatorObserver` 只需约 10 行，纯 Dart 类，零额外依赖成本。

---

## 4. 适用场景判断

| 场景 | 用本套路？ | 理由 |
|---|---|---|
| 主菜单 push 按钮，子屏 watch 异步 Isar provider | **用** | 子屏 loading 不阻断，只验 push 触发 |
| 任何 navigation 入口按钮，子屏有 CPI 或无限动画 | **用** | 同上 |
| 子屏内部全流程验收（列表→详情→确认 dialog） | **不用** | 需要真实 settle，走 #28 Consumer 化 + fake service override |
| Phase1/Phase2 测试菜单 push（子屏无异步 provider） | **不用** | 直接 `pumpAndSettle` 即可，子屏纯同步不卡 |
| push 后需断言子屏某元素存在 | **不用** | 子屏 build 不保证在单帧内完成，observer 套路不适合跨屏内容断言 |

---

## 5. 与 Phase 5 #2 销账 #28 套路对比

#28（`PROGRESS.md` 第 30 条销账）用 Consumer 化 + fake service `overrideWithValue` 绕过 native Isar zone，覆盖子屏完整流程。本套路是其轻量化版本，专注入口层。

| 维度 | 本套路（NavigatorObserver Mock） | #28 Consumer 化 + provider override |
|---|---|---|
| 改 `lib/` | **0 行**（纯 test 侧） | 需将 service caller 改为 `Consumer` / `ConsumerWidget` |
| 改 `test/` | +8～12 行（observer 类 + 测试用例） | +N 行（fake service 实现 + override setup） |
| 验收范围 | 仅验 push 触发（路由类型） | 子屏完整内容（列表渲染 / dialog / 导航链路） |
| 适用层 | 入口按钮（主菜单 / 任何 nav 触发点） | 子屏内部全流程 e2e widget test |
| 解决的核心问题 | `pumpAndSettle` 死循环（子屏异步 loading） | `fake_async` vs native Isar zone 边界错误 |
| 代码侵入性 | 无（不动生产代码） | 有（需 Consumer 化，改动 lib/） |

**选型原则**：只验「导航触发」→ 本套路；需验「子屏内容」→ #28 套路。两者不冲突，可共存于同一测试文件（`main_menu_test.dart` 中 Phase1/Phase2 tap 用 `pumpAndSettle`，问鼎九霄 tap 用本套路）。

---

## 6. 后续复用清单

以下 `MainMenu` push 按钮目前通过 `InkWell` 计数 + label 断言覆盖可点性，尚未做 push 触发验收。若后续需要加强验收，直接套用本套路：

| 按钮 | 目标屏 | 子屏异步 provider | 优先级 |
|---|---|---|---|
| 主线关卡 | MainlineScreen | 可能有关卡进度 provider | 中 |
| 角色面板 | CharacterPanelScreen | `activeCharacterProvider` Isar | 中 |
| 师徒名单 | LineagePanelScreen | `lineageInfoProvider` Isar | 中 |
| 装备 | InventoryScreen | `inventoryProvider` Isar | 低 |
| 心法 | TechniquesScreen | `techniquesProvider` Isar | 低 |

**套用步骤**（每个按钮约 10 分钟）：

1. 在文件末尾复用已有的 `_RecordingNavigatorObserver` 类（已存在，无需重复定义）
2. 新增一个 `testWidgets` 用例，`navigatorObservers: [observer]` 注入
3. `tap(find.text(对应 UiStrings 常量))`
4. `await tester.pump()` （单帧）
5. `expect(observer.pushedRoutes.length, 2)` + `isA<MaterialPageRoute<void>>()`

> 注：`_RecordingNavigatorObserver` 已定义在 `main_menu_test.dart` 末尾，同文件内所有 push 测试直接复用，无需重复定义。

---

## 参考

- 源测试文件：`test/features/main_menu/presentation/main_menu_test.dart:100-134`（W17 #31 销账段）
- `_RecordingNavigatorObserver` 类定义：`main_menu_test.dart:337-345`
- Phase 5 #2 销账 #28 套路：`PROGRESS.md` 第 30 条销账（`_FakeSeclusionService implements SeclusionService`）
- PROGRESS.md #31 销账记录：W17 长期挂账冲刺，commit `4aa54fa`
