# 出版美术视觉验收基建 · 设计 spec

**日期**:2026-05-31
**作者**:Mac + Opus(xhigh)
**状态**:设计已拍板,待 writing-plans 转实装
**关联**:出版美术 Pass(`PUBLISHING_ART_PASS_1_0.md`)Phase A/B 已收口;本基建服务后续每屏切片的视觉验收提速 + 关闭 cover 多 tier 验收缺口。

---

## 1. 目标与动机

出版美术验收当前是纯手工:启动 app → 点 Phase2 调试菜单 → 点某 seed 按钮 → 肉眼看屏 → 派 Codex / 我读图。痛点两条:

1. **慢且易错**:每个验收点要人工导航,派单要逐点写路径,验收链路长。
2. **cover 多 tier 验收盲区**:技法面板按 `TechniqueTier` 分组,每 tier 显 1 张卷轴 cover(`assets/techniques/tier_*.png`,7 阶素纸→金框装帧梯度)。但现有 seed 只造单 tier 角色 → 一次只能看 1 张,7 阶梯度无法同屏验收。

**本基建目标**:让 app 能无人值守「直达」某个 (seed + screen) 验收点,脚本批量截图,产出可供 Codex / 我读图对照的 png 集 + manifest。同时新增「武圣满学 7 阶」seed 关闭 cover 多 tier 缺口。

**非目标(YAGNI)**:不做截图 diff 对比、不做 CI 集成、不自动判 PASS/FAIL(读图判断仍是 Codex / 我的职责)。

---

## 2. 关键决策(brainstorming 拍板)

| # | 决策 | 选定 | 理由 |
|---|------|------|------|
| Q1 | 截图目标平台 | **Mac 本地 app** | 出版美术是 Mac 单端验收,链路最短,无需 Pen 开机/SSH。Pen `pen_screen.sh` 仅服务 Windows 平台特定验收 |
| Q2 | app 直达机制 | **dart-define 启动直达** | Flutter 原生机制无新依赖,脚本可 `for route in ...; do flutter run --dart-define=VISUAL_ROUTE=$route; done` 批量 |
| Q3a | 第一批 route 范围 | **聚焦已收口屏** | 只覆盖 A/B 段已做的(主菜单 + 心法面板),先跑通基建;后续屏切片时增量加 route |
| Q3b | 多 tier cover 呈现 | **单角色满学 7 阶心法** | seed 造 1 个武圣满境界角色 + 7 条心法各占一 tier,技法面板自然显全 7 张卷轴一屏滚动看全(符 §5.3 锁死,最接近真实满配玩家面板) |
| Q4 | 截图机制 | **脚本侧 `screencapture`** | 真实窗口所见即所得(含字体/图片加载/阴影/平台层),最忠实于出版美术验收核心「真实渲染效果」;app 内 `toImage()` 恰可能漏图片异步加载与阴影 |

---

## 3. 架构总览

三层,各自单一职责、独立可测:

```
tools/visual_capture/visual_capture.sh   ──循环:启动 app + 等就绪 + 截窗口 + 退出──►
       │
       ▼  flutter run -d macos --dart-define=VISUAL_ROUTE=<id>
main.dart 启动分流(debug-only)
       │  if (kDebugMode && visualRouteFromEnv() != null) → VisualRouteApp
       ▼
lib/features/debug/presentation/visual_route_host.dart
   route id → (seed 调用 + 目标 screen)映射,首帧后 debugPrint('VISUAL_ROUTE_READY: <id>')
       │
       ▼
phase2_seed_service.dart 内 seed(复用现有 / 新增 seedVisualMasterAllTiers)
```

release build / 无 dart-define 参数 → 现有正常启动路径**零改动**。

---

## 4. 组件设计

### 4.1 VisualRoute 枚举 + dispatcher

新增 `lib/features/debug/application/visual_route.dart`:

- `enum VisualRoute { mainMenu, techniquePanelTierAll, techniquePanelHero }`,每个带 `id`(dart-define 字符串,如 `main_menu` / `technique_panel_tier_all` / `technique_panel_hero`)+ `label`(人读说明,进 manifest)。
- 纯函数 `VisualRoute? parseVisualRoute(String raw)`:id 匹配 → 枚举值,未知/空 → null。**便于单测**。
- `VisualRoute? visualRouteFromEnv()`:读 `const String.fromEnvironment('VISUAL_ROUTE')`,委派 `parseVisualRoute`。

### 4.2 main.dart 启动分流

在现有 `runApp` 前加 debug-only 分支:

```
if (kDebugMode) {
  final route = visualRouteFromEnv();
  if (route != null) {
    runApp(VisualRouteApp(route: route));  // 独立 app 入口,跳过主菜单
    return;
  }
}
// ↓ 现有正常启动路径,零改动
```

- `kDebugMode` 守卫确保 release 永不进此路径。
- 无 `VISUAL_ROUTE` 参数时 `visualRouteFromEnv()` 返回 null,正常启动,对日常开发零影响。

### 4.3 VisualRouteHost / VisualRouteApp

`lib/features/debug/presentation/visual_route_host.dart`:

- `VisualRouteApp`:`MaterialApp` 外壳(复用现有 theme),home 为 `VisualRouteHost`。
- `VisualRouteHost`:`StatefulWidget`,`initState`/post-frame 中:
  1. 按 route 调对应 seed(集中映射表,一处)。
  2. seed 后 `Navigator.pushReplacement` 到目标 screen(或直接当 home 渲染,见下表)。
  3. 目标屏首帧渲染完成后(`WidgetsBinding.addPostFrameCallback`)`debugPrint('VISUAL_ROUTE_READY: <id>')` —— 脚本的就绪信号。

**route → (seed + screen)映射表**:

| VisualRoute | seed | 目标 screen |
|---|---|---|
| `mainMenu` | clean / 现有 onboarding production seed | `MainMenu`(直接当 home,不 push) |
| `techniquePanelTierAll` | **新 `seedVisualMasterAllTiers()`** | `TechniquePanelScreen(characterId)` |
| `techniquePanelHero` | 复用 `seedRefineInsight()`(已有主修 hero 态) | `TechniquePanelScreen(characterId)` |

### 4.4 新 seed:seedVisualMasterAllTiers

加在 `lib/features/debug/application/phase2_seed_service.dart`,沿现有 13 个 seed 体例:

- 造 1 个**武圣满境界**角色(满足 §5.3 三系锁死,合法持有最高阶心法)。
- **运行时遍历** `TechniqueTier.values`,对每个 tier 从已加载的 `techniques.yaml` 取该 tier 第 1 条心法 id 学上(**不硬编码 id**,yaml 增删条目自动适应)。techniques.yaml 现状 = 7 tier × 7 本(共 49),各 tier 首本均 gangMeng 流派,取首本即可。
- 主修设其一(让 `technique_panel_hero` 也复用得上有内容的主修态),其余辅修。
- seed 后沿 `_seedAndPush` 体例 invalidate 相关 provider。
- 返回 `characterId` 供 host push。

**红线守卫**:角色满境界故走合法路径,不绕 `canPractice` 锁死;若某 tier 在 techniques.yaml 无可用条目 → **fail-fast 抛错**(不静默跳过,符 §8.1 联结强校验基调)。

### 4.5 visual_capture.sh 脚本

放 `tools/visual_capture/visual_capture.sh`(沿 `tools/pen_screen/` 体例,自带目录 + README)。

**参数**:
- 无参 → 截全部 route。
- `visual_capture.sh main_menu technique_panel_tier_all` → 只截指定 route。
- `--dry-run` → 仅打印将执行的 route 清单 + 输出目录,不启 app(脚本自检)。

**每个 route 流程**:
1. `flutter run -d macos --dart-define=VISUAL_ROUTE=$route` 后台启动,stdout/stderr 重定向到日志文件。
2. 轮询日志直到出现 `VISUAL_ROUTE_READY: $route`(超时上限,如 120s,超时 → 记 FAIL 继续下一个,不卡死)。
3. 固定 settle delay(~1.5s)让 `Image.asset` cover 加载完。
4. 取 Flutter app 窗口 ID(`osascript` 查窗口),`screencapture -l<windowID> -o <out>.png` 截窗口;窗口 ID 取失败 → 兜底 `screencapture -o`(交互)+ 提示。
5. `pkill` 关 app(精确匹配本次 pid,避免误杀),等进程退出再下一个。

**输出**:
- `docs/handoff/visual_capture_<sha>_<timestamp>/<route>.png`
- 同目录 `manifest.txt`:每行 `route → 文件名 → label(路由说明)`,供 Codex / 我读图对照。

**覆盖性(Monitor 原则)**:就绪轮询同时匹配失败签名(编译 error / exception / 进程早退),不只等成功标志,避免崩溃时静默空等到超时。

---

## 5. 测试边界

| 单元 | 测法 | 覆盖 |
|------|------|------|
| `parseVisualRoute` / `visualRouteFromEnv` | 纯函数 `test()` | 已知 id → 枚举 / 未知 id → null / 空串 → null / 每个枚举 id 往返一致 |
| `seedVisualMasterAllTiers` | `test()`(非 `testWidgets`,避 Isar 死锁,见 memory `feedback_isar_widget_test_deadlock`) | 造出武圣满境界 + 7 tier 各 ≥1 心法 + 全部合法(canPractice 通过)+ 某 tier 空时 fail-fast |
| `visual_capture.sh` | 不单测(shell) | 靠 `--dry-run` 自检 + 实跑验收 |

**verify**:全量 flutter test 维持 baseline(当前 1612)+ delta(新增单测条数),0 analyze。

---

## 6. 风险与缓解

| 风险 | 缓解 |
|------|------|
| `screencapture` 窗口 ID 取不到(多窗口/焦点) | `osascript` 查 Flutter app 窗口;失败兜底 `-o` 交互 + 明确提示 |
| 截到编译中/空 cover 图 | `VISUAL_ROUTE_READY` 就绪信号 + settle delay 双保险;轮询也匹配失败签名防静默空等 |
| `flutter run` 启动慢/卡 | 轮询超时上限(120s),超时记 FAIL 继续,不卡死整批 |
| `pkill` 误杀其他 flutter 进程 | 记录本次启动 pid,精确 kill(而非宽匹配 `flutter`) |
| main.dart 分流污染 release | `kDebugMode` 守卫 + 无参数 null 短路,release/日常零影响 |
| seed 绕过境界锁死红线 | 角色满境界走合法 `canPractice`;tier 空 fail-fast |

---

## 7. 交付物清单

1. `lib/features/debug/application/visual_route.dart`(枚举 + parse + env)
2. `main.dart` debug-only 启动分流(~6 行)
3. `lib/features/debug/presentation/visual_route_host.dart`(VisualRouteApp + Host + 映射表)
4. `phase2_seed_service.dart` 新增 `seedVisualMasterAllTiers()`
5. `tools/visual_capture/visual_capture.sh` + `tools/visual_capture/README.md`
6. 单测:`visual_route` 纯函数测 + `seedVisualMasterAllTiers` seed 测

---

## 8. 硬约束沿用

- 改代码:Bash python / 带引号 heredoc 直写 main(Edit/Write 被 bg isolation guard 拦);assert count + git diff + flutter test 核验,git add 显式文件不用 -A。
- 不硬编码数值/文案(seed 走真实 yaml id;日志标志 `VISUAL_ROUTE_READY` 是开发期英文标识非玩家可见文案,可接受)。
- 不动 GDD.md / CLAUDE.md / numbers.yaml(本基建纯 debug 工具层,0 规则层改动)。
- §5.3 三系锁死:seed 走满境界合法路径,不开后门。
