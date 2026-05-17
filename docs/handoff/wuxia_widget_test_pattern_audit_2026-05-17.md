# Widget Test Pattern 审计 · pumpAndSettle 死循环风险扫描(2026-05-17)

> Nightshift T02 产出。挂账 #31 销账后 NavigatorObserver mock 套路总结 + 全仓 pumpAndSettle 风险扫描 + 推荐替换清单。

---

## 1. NavigatorObserver Mock 套路(W17 #31 销账 commit `4aa54fa`)

### 根因回顾

`test/features/main_menu/presentation/main_menu_test.dart` 中，tap「问鼎九霄」后会 push `TowerFloorListScreen`。该屏内部 `watch towerProgressProvider`（Isar 异步 future）+ `CircularProgressIndicator`（无限动画），`pumpAndSettle` 永不完成。

W6 drift 5 轮探路无解后，W17 用更轻量的套路解决：**不 settle 子屏 build，只验 Navigator.push 触发**。

### _RecordingNavigatorObserver 源码

```dart
/// 记录 Navigator.push 调用的 observer(W17 #31 销账):
/// 测试 tap 按钮触发 push 时使用,代替对子屏的真实 build/settle。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
```

### 用法示例

```dart
testWidgets('tap 问鼎九霄 → Navigator.push 触发(不 settle 子屏,#31 销账)',
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
  // 验证 initial push(MainMenu 自身)已记录
  expect(observer.pushedRoutes.length, 1);

  await tester.tap(find.text(UiStrings.mainMenuTower));
  await tester.pump(); // 单帧,不 settle:子屏 TowerFloorListScreen 内部
                      // towerProgressProvider AsyncValue.loading 不阻塞断言

  // tap 后应有 1 次新 push(TowerFloorListScreen)
  expect(observer.pushedRoutes.length, 2);
  // 验证最新 push 是 MaterialPageRoute(_push 包装)
  expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
});
```

### 适用场景

| 条件 | 是否适用 |
|---|---|
| tap 按钮后 push 新 screen，子屏 watch 未 override 的 Isar provider | ✅ 必须用 |
| 子屏含 `CircularProgressIndicator`（AnimationController 无限循环）| ✅ 必须用 |
| 只需验证"导航是否触发"，不需验证子屏内容 | ✅ 轻量方案 |
| 子屏内容本身需要断言（provider 已 override 或无 Isar 依赖）| ❌ 继续用 pumpAndSettle |

---

## 2. 全仓 pumpAndSettle 用法扫描

```
grep -rn "pumpAndSettle" test/ --include="*.dart"
```

共命中 **51 行**（含注释），其中：
- **代码调用**：45 处（实际 await pumpAndSettle() 调用）
- **注释说明**：6 处（含"不要 pumpAndSettle"的警告注释，说明该模式已被正确规避）

按风险分：
- **低风险 A**：34 处
- **中风险 B**：11 处
- **高风险候选 C**：**0 处**（正面结论：当前全仓无同型 #31 漏网点）

---

### 2.1 低风险（A 类，34 处）

| 文件 | 行号 | 用法摘录 | 理由 |
|---|---|---|---|
| main_menu_test.dart | 80 | tap Phase1 → BattleTestMenu | 目标屏无 Isar 依赖，纯菜单渲染 |
| main_menu_test.dart | 90 | tap Phase2 → Phase2TestMenu | 同上 |
| tower_entry_flow_test.dart | 80,83,88 | 普通层胜利流程 dialog settle | 全程 DI 注入 battleRunner/clearRecorder，无 Isar |
| tower_entry_flow_test.dart | 109,112 | 普通层失败流程 | 同上 |
| tower_entry_flow_test.dart | 127,130,134 | 首通（isFirstClear: true）| 同上 |
| tower_entry_flow_test.dart | 149,152,156 | 重打（isFirstClear: false）| 同上 |
| tower_entry_flow_test.dart | 175,178,182 | Boss 层（无 narrative）胜利 | 同上 |
| narrative_reader_screen_test.dart | 57,65 | push NarrativeReaderScreen，pop 后断言 | 内容作构造参数传入，无 Isar provider |
| narrative_reader_screen_test.dart | 131,135 | 「跳过」按钮直接 pop | 同上 |
| stage_victory_dialog_test.dart | 136,141 | showStageVictoryDialog 弹起/关闭 | 静态数据 dialog，无 Isar |
| inventory_screen_test.dart | 168,197,239,286 | Tab 切换动画（装备 ↔ 物料）| Tab 动画有限，且 allEquipmentsProvider / allInventoryItemsProvider 均 override |
| equipment_detail_screen_test.dart | 82,118,146,186,223,249,279,302 | 初始 settle（lore FutureBuilder 完成）| loreLoader 为 DI 注入 fake 函数，即时返回，无 Isar provider watch |

### 2.2 中风险（B 类，11 处）

已有 fake provider override 兜底，当前能 settle，但未来若子屏新增 Isar-backed provider 则自动升 C。

| 文件 | 行号 | 用法摘录 | override 情况 | 风险点 |
|---|---|---|---|---|
| tower_floor_list_screen_test.dart | 65 | pumpScreen 内初始 settle | towerProgressProvider + towerFloorListProvider 均 override | fake future 即时返回，settle 快；若 override 被移除则升 C |
| tower_floor_list_screen_test.dart | 115 | tap available 层 → 战斗准备失败 | 同上（列表屏已 override）| 子屏依赖 Isar，目前因未初始化快速同步报错能 settle；若子屏加 loading 状态则升 C |
| tower_floor_list_screen_test.dart | 149 | tap 重打确认 → 战斗准备失败 | 同上 | 同 :115 |
| seclusion_e2e_test.dart | 137 | tap '山林' → push SetupScreen | seclusionServiceProvider override | SetupScreen 接构造参数（charRealmTier/characterId），目前无额外 Isar watch；若新增 characterByIdProvider watch 则升 C |
| seclusion_e2e_test.dart | 154 | 再次 tap '山林'（第二个测试） | 同上 | 同 :137 |
| seclusion_e2e_test.dart | 159 | tap 开始闭关 → pushReplacement ActiveScreen | 同上 | ActiveRetreatScreen 同样接构造参数，同样潜在风险 |
| seclusion_e2e_test.dart | 207 | tap 收功 → pushReplacement ResultScreen | 同上 | RetreatResultScreen 静态数据渲染，当前安全 |
| seclusion_e2e_test.dart | 256,265 | 提前收功 dialog 弹起/取消 | 同上 | Dialog 动画有限，当前安全 |
| seclusion_e2e_test.dart | 271,273 | 再次提前收功 dialog 确认 → push Result | 同上 | 同 :207 |

### 2.3 高风险候选（C 类，推荐改写）

**0 处。** 全仓当前无"tap 后 push 新 screen 且子屏 watch 未 override Isar provider"的漏网点。

#31 销账 commit `4aa54fa` 已覆盖唯一已知 C 类风险（主菜单「问鼎九霄」按钮），其余 Isar 依赖按钮（主线/角色/装备/心法/师徒名单）在 main_menu_test 中仅通过 InkWell 计数 + label 断言覆盖可点性，不 tap 进入子屏，规避了死循环风险。

---

## 3. 推荐替换清单

当前 **0 个 C 类候选**，无需立即改写。

以下 2 处 B 类（tower_floor_list_screen_test.dart:115 / :149）有**最高的升 C 潜力**，建议在战斗准备子屏逻辑迭代时同步评估：

### 候选 1：tower_floor_list_screen_test.dart:115

**现状：**
```dart
await tester.tap(find.text(UiStrings.towerFloorLabel(1)));
await tester.pumpAndSettle();
expect(find.textContaining('战斗准备失败'), findsOneWidget);
```

**触发条件升 C：** 若战斗准备子屏在展示错误前新增 `AsyncValue.loading` 状态（如"正在加载角色数据…"的 CircularProgressIndicator），pumpAndSettle 将死循环。

**改写方案 sketch（下次 sprint 实装）：**
```dart
final observer = _RecordingNavigatorObserver();
// pumpScreen helper 需扩展以接受 navigatorObservers 参数
await pumpScreenWithObserver(tester, progress: progress, observer: observer);

await tester.tap(find.text(UiStrings.towerFloorLabel(1)));
await tester.pump(); // 单帧，不 settle

// 只验 push 触发（不进入子屏 build）
expect(observer.pushedRoutes.length, greaterThan(1));
```

### 候选 2：tower_floor_list_screen_test.dart:149

同候选 1，出现在「重打确认 → 战斗准备失败」路径，改写方案相同。

---

## 4. 后续 follow-up

**当前结论：全仓 pumpAndSettle 无 C 类漏网点。** #31 销账的 NavigatorObserver mock 套路已在主菜单问鼎九霄入口正确落地，其他菜单入口的 Isar 依赖屏一律不在 test 中 tap-settle，整体风险可控。

**建议跟踪事项：**

1. **tower_floor_list_screen_test.dart:115/:149** — 战斗准备子屏若未来增加 loading 状态，需改为 NavigatorObserver mock 单帧 pump 套路（改写 sketch 见 §3）。

2. **seclusion_e2e_test.dart push 导航处（:137/:154/:159）** — 若 SetupScreen / ActiveRetreatScreen 后续新增 `watch characterByIdProvider`（Isar-backed，未 override），对应 pumpAndSettle 需改写。建议每次新增 provider watch 时 checklist：是否在 e2e test 的 ProviderScope.overrides 中补上 fake。

3. **注释警告已正确落位**：`character_panel_screen_test.dart:156`、`enhance_dialog_test.dart:23`、`phase2_test_menu_test.dart:112` 三处注释已明确说明"不用 pumpAndSettle"的原因，是良好的文档实践，无需更改。

---

*Nightshift T02 · 2026-05-17 · branch `nightshift/T02`*
