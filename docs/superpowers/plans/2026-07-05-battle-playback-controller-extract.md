# BattleScreen C 批次 · BattlePlaybackController 抽离 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 把 `_BattleScreenState`（~1433 行）的动画/VFX/拍钟子系统抽成 State 拥有、可独立单测的 `BattlePlaybackController`，battle_screen.dart 降到 ~600–700 行。

**Architecture:** 单个 controller 对象，State 在 initState 构造（传 vsync=this、ConsumerState 的 ref、rebuild=setState、animConfig）、dispose 释放。rebuild 走注入 `setState`（非 ChangeNotifier）→ rebuild 粒度逐字节不变，近纯移动。State 保交互态 + build + 3 条 ref.listen 边沿（改为委托 controller）。**这是 move-refactor，不是 greenfield TDD**：验收 oracle = 既有 battle 测保持绿（每切片 gate）+ 末尾补 controller 单测。

**Tech Stack:** Flutter / Riverpod 3.x ConsumerState / AnimationController(TickerProviderStateMixin) / Isar 无关。

**Env prep（执行者开工前，fresh worktree 必做）：** `flutter pub get` → 从主仓拷 `libisar.dylib`（截断坑）→ `dart run build_runner build --delete-conflicting-outputs`（112 .g.dart）→ 冒烟 `flutter test test/features/battle/ -j1 | tail -3` 确认基线绿，再动手。参 memory `feedback_subagent_driven_fresh_worktree_env_prep`。

**Controller 最终 API 契约（各 Task 逐步填充，命名锁死一致）：**
文件 `lib/features/battle/presentation/battle_playback_controller.dart`
```dart
class BattlePlaybackController {
  BattlePlaybackController({
    required TickerProvider vsync,
    required WidgetRef ref,
    required void Function(VoidCallback fn) rebuild,
    required AnimationNumbers animConfig,
    bool startPaused = false,
    bool startFastForward = false,
  });
  // 拍钟（Task 2）
  void startTimer();
  void pause();
  void resume();            // 内部读 ref battleProvider.isFinished gate
  void toggleFastForward();
  void onGameplaySettingsChanged();
  void onBattleFinished();  // cancel timer + beat.stop()（结算 dialog 留 State）
  bool get isPaused; bool get isFastForward; bool get hasTimer;
  // VFX（Task 1/3/4）
  void playAction(BattleAction action, BattleState s);   // Task 4 才 public
  void playGuardianWardBreak(BattleCharacter boss);
  // getters（build 读作 props）
  List<AnimationController> get attackControllers;
  List<AnimationController> get hitFlashControllers;
  Map<int, Color> get hitFlashColors;
  AnimationController get beatCtrl, shakeCtrl, closeupCtrl;
  double get impactShakeAmplitude;
  List<TrailEntry> get activeTrails;
  List<EffectEntry> get activeEffects;
  Map<int, List<PopupEntry>> get popups;
  GlobalKey<UltimateCaptionOverlayState> get ultimateCaptionKey;
  GlobalKey<ImpactGlyphOverlayState> get impactGlyphKey;
  GlobalKey<ScreenFlashOverlayState> get screenFlashKey;
  void dispose();
}
```
内部私有（各方法从 State 逐字节搬入，仅两类改动：① `setState(...)`→`rebuild(...)`；② `_xxx` 自字段引用不变、`widget.animConfig`→`_animConfig`、裸 `mounted`→`!_disposed`、`_currentGameplaySettings` 私有 getter 一并搬）：`_spawnPopup/_spawnTrail/_spawnBattleEffects/_spawnEffect/_triggerHitFlash/_removePopup/_applyHitStop/_playBossPhaseTransition/_currentGameplaySettings/_hitStopTimer/_playTimer/_disposed`。

**每 Task gate（统一）：** `flutter analyze lib/ test/` = 0 → `flutter test test/features/battle/ -j1 | tail -5`（期望 pass 数 = 该 Task 前基线，零回归）→ commit。analyze 未 0 或测非绿 → 不 commit，`git reset` 回上一切片。

---

### Task 0: 提取共用纯几何 helper（DRY 前置）

**Files:**
- Modify: `lib/features/battle/domain/battle_skill_utils.dart`（加顶层公有纯函数）
- Modify: `lib/features/battle/presentation/battle_screen.dart`（删私有版，改调公有版）

- [ ] **Step 1:** grep 现状确认这 4 个 helper 的私有定义与全部调用点：`grep -nE '_slotKey|_slotFrac|_teamSizeOf|_findCharacter' lib/features/battle/presentation/battle_screen.dart`
- [ ] **Step 2:** 把 `_slotKey`/`_slotFrac`/`_teamSizeOf`/`_findCharacter` 的**函数体逐字节**搬到 `battle_skill_utils.dart` 顶层，去下划线成公有 `slotKey`/`slotFrac`/`teamSizeOf`/`findCharacter`（保持 battle_skill_utils 无 Flutter import：这 4 个都是纯 Dart 计算，若 `slotFrac` 需 Offset/Size 则改留 State——先 grep 确认签名再决定，含 `dart:ui` 类型的留 State 不搬）。
- [ ] **Step 3:** battle_screen.dart 删这些私有定义，全部调用点改公有名（controller Task 里也将 import 同一处）。
- [ ] **Step 4:** gate（analyze 0 + battle 绿）。
- [ ] **Step 5:** `git add -A && git commit -m "refactor(battle): 提取共用几何 helper 到 battle_skill_utils"`

---

### Task 1: Scaffold controller + 搬 VFX 反应原语（队列 + spawn 叶方法 + attack/hitFlash 控制器）

**Files:**
- Create: `lib/features/battle/presentation/battle_playback_controller.dart`
- Modify: `battle_screen.dart`（删字段/方法，构造+委托）

- [ ] **Step 1:** 新建 controller 文件：构造 `{vsync, ref, rebuild, animConfig, startPaused, startFastForward}`，成员搬入：`_attackControllers`(6)、`_hitFlashControllers`(6)、`_hitFlashColors`、`_activeTrails`/`_nextTrailId`、`_activeEffects`/`_nextEffectId`、`_popups`/`_nextPopupId`，在构造体内以 `vsync`/`_animConfig` 初始化（原 initState 264–288 行逻辑逐字节搬，`vsync: this`→`vsync: vsync`、`widget.animConfig`→`_animConfig`）。加 `bool _disposed=false`。方法搬入：`_spawnPopup/_spawnTrail/_spawnBattleEffects/_spawnEffect/_triggerHitFlash/_removePopup`（`setState`→`rebuild`；listener 里 `if(!mounted)`→`if(_disposed)`）。加 public getters：`attackControllers/hitFlashControllers/hitFlashColors/activeTrails/activeEffects/popups`。
- [ ] **Step 2:** controller `dispose()`：搬 State dispose 里对应释放（attack/hitFlash 遍历 dispose + activeTrails/activeEffects 未 disposed 的 `.ctrl.dispose()`），置 `_disposed=true`。
- [ ] **Step 3:** State：删上述字段/方法/initState 初始化段；`late final BattlePlaybackController _playback;` 在 initState `super.initState()` 后构造：`_playback = BattlePlaybackController(vsync: this, ref: ref, rebuild: setState, animConfig: widget.animConfig, startPaused: widget.startPaused, startFastForward: widget.startFastForward);`。State.dispose 改 `_playback.dispose()`（保留 `_playTimer`/beat 相关到 Task 2）。
- [ ] **Step 4:** State 内原调 `_spawnX/_triggerHitFlash/_removePopup` 处（在仍留 State 的 `_playAction`）改 `_playback.spawnX(...)`——**为此这些方法本 Task 需 public**（去下划线：`spawnPopup/spawnTrail/spawnBattleEffects/spawnEffect/triggerHitFlash/removePopup`）；build 里读 `_attackControllers`/`_popups`/`_hitFlashControllers`/`_hitFlashColors`/`_activeTrails`/`_activeEffects` 改 `_playback.xxx`。
- [ ] **Step 5:** gate → commit `refactor(battle): 抽 VFX 反应原语到 BattlePlaybackController`

---

### Task 2: 搬拍钟调度（beat/timer/hit-stop/pause/fast-forward）

**Files:** Modify `battle_playback_controller.dart` + `battle_screen.dart`

- [ ] **Step 1:** controller 搬入：`_beatCtrl`（构造初始化，291 行逻辑）、`_playTimer`/`_hitStopTimer`、`_isPaused`(初值=startPaused)/`_isFastForward`(初值=startFastForward)、`_impactShakeAmplitude`。方法搬入并 public：`startTimer`（349–381 逐字节，`widget.animConfig`→`_animConfig`、`mounted`→`!_disposed`、`_currentGameplaySettings` getter 一并搬）、`pause`（= 原 `_togglePause` 的 `_isPaused=true` 分支体：cancel timer + beat.stop，走 `rebuild`）、`resume`（= false 分支：`if(!ref.read(battleProvider).isFinished) startTimer()`，走 `rebuild`）、`toggleFastForward`（383–386，`rebuild`）、`_applyHitStop`(public `applyHitStop`)、`onGameplaySettingsChanged`（= build 里 gameplaySettings listen 体：`if(hasTimer && !finished) startTimer()`）、`onBattleFinished`（cancel timer + beat.stop）。getters：`beatCtrl/shakeCtrl?`(shake 留 Task3)/`isPaused/isFastForward/hasTimer(=_playTimer!=null)/impactShakeAmplitude`。
- [ ] **Step 2:** controller dispose 补 `_playTimer?.cancel()`/`_hitStopTimer?.cancel()`/`_beatCtrl.dispose()`。State dispose 删这几行。
- [ ] **Step 3:** State：`_togglePause` 保留（含 `_pendingSkill!=null → _clearPending()` 的 C 分支），改为 `if(_pendingSkill!=null){_clearPending();return;} if(_playback.isPaused) _playback.resume(); else _playback.pause();`。`_startTimer/_toggleFastForward/_applyHitStop` 调用点 → `_playback.startTimer()/toggleFastForward()/applyHitStop(ms)`。initState autoStartOnMount postframe 里 `_playTimer!=null`→`_playback.hasTimer`、`_startTimer()`→`_playback.startTimer()`。build 里 `_beatCtrl` prop→`_playback.beatCtrl`、`_isPaused`→`_playback.isPaused`、`_isFastForward`→`_playback.isFastForward`。build 内两条 ref.listen（battleProvider 结束边沿 / gameplaySettings）改调 `_playback.onBattleFinished()` / `_playback.onGameplaySettingsChanged()`。
- [ ] **Step 4:** gate → commit `refactor(battle): 抽拍钟调度到 BattlePlaybackController`

---

### Task 3: 搬 overlay-key 编排 + shake/closeup + boss-phase/ward-break

**Files:** Modify controller + battle_screen.dart

- [ ] **Step 1:** controller 搬入 `_shakeCtrl`/`_closeupCtrl`（构造初始化 271–280 行）+ 3 个 overlay GlobalKey（`_ultimateCaptionKey/_impactGlyphKey/_screenFlashKey`，controller 内 `final` 新建）+ 方法 `_playBossPhaseTransition`(private，playAction 内部调) + public `playGuardianWardBreak`。getters：`shakeCtrl/closeupCtrl/ultimateCaptionKey/impactGlyphKey/screenFlashKey`。dispose 补 shake/closeup。
- [ ] **Step 2:** State 删 `_shakeCtrl/_closeupCtrl/_ultimateCaptionKey/_impactGlyphKey/_screenFlashKey/_playBossPhaseTransition/_playGuardianWardBreak`。build 里实例化 overlay 处 `key: _xxxKey`→`key: _playback.xxxKey`；AnimatedBuilder 的 `_closeupCtrl`/`_shakeCtrl`→`_playback.closeupCtrl`/`_playback.shakeCtrl`；`_impactShakeAmplitude`→`_playback.impactShakeAmplitude`。ref.listen ward-break 边沿 `_playGuardianWardBreak(c)`→`_playback.playGuardianWardBreak(c)`。State 内 `_playAction` 里对 overlay-key/shake/closeup/`_playBossPhaseTransition` 的引用改 `_playback.xxx`（keys/ctrl 走 getter；`_playBossPhaseTransition` 暂经临时 public delegate 或直接内联——Task 4 会连同 `_playAction` 整体搬走，此处最小改动即可）。
- [ ] **Step 3:** gate → commit `refactor(battle): 抽 overlay 编排/屏震到 BattlePlaybackController`

---

### Task 4: 搬 `_playAction` 本体 + 接线 listen + 补单测 + 全量/目检

**Files:** Modify controller + battle_screen.dart；Create `test/features/battle/battle_playback_controller_test.dart`

- [ ] **Step 1:** 把 `_playAction` 整体从 State 搬入 controller 成 public `playAction(BattleAction, BattleState)`（此时它所有依赖——spawn/beat/hitstop/overlay/shake/`_playBossPhaseTransition`——都已在 controller，内部改回私有直调；把 Task1/Task3 临时 public 化的内部 spawn/delegate 收回 private，只保留契约列的 public API）。State build 内 ref.listen actionLog 增长边沿：`_playAction(a, next)`→`_playback.playAction(a, next)`。
- [ ] **Step 2:** 全仓核对残留：`grep -nE '_attackControllers|_beatCtrl|_shakeCtrl|_closeupCtrl|_hitFlash|_activeTrails|_activeEffects|_popups|_playTimer|_hitStopTimer|_playAction|_spawn|_startTimer' lib/features/battle/presentation/battle_screen.dart` 应仅剩 `_playback.` 委托与 C 交互态；`wc -l battle_screen.dart` 期望 ~600–700。
- [ ] **Step 3: 写 controller 单测**（新文件）：构造一个 controller（vsync 用 `TestVSync()`（`package:flutter/scheduling.dart`）；ref 用最小 ProviderContainer 包一个 fake WidgetRef——若 WidgetRef 难造，改用 `ProviderScope` + `Consumer` 在 `testWidgets` 内拿真 ref；rebuild 传记录用 `int rebuilds=0; (fn){fn(); rebuilds++;}`）。断言：① `spawnPopup` 后 `popups[key]` 长度+1、id 递增 ② `applyHitStop(50)` 后 `hasTimer` 变化并在 fake async 推进后复播 ③ `pause()` 后 `isPaused==true` 且 `hasTimer==false`、`resume()` 恢复 ④ `toggleFastForward()` 翻转 `isFastForward`。用 `test/features/battle/` 既有 harness 体例（参邻近 `battle_screen_target_chip_test.dart`）。**注意**：确定性/async 用 `fakeAsync` 或 `tester.pump(Duration)`，别真 sleep（memory `feedback_widget_test_pump_until_found_settle`）。
- [ ] **Step 4:** gate（analyze 0 + `flutter test test/features/battle/ -j1` 全绿含新单测）。
- [ ] **Step 5: 全量**：`flutter test --no-pub | tail -5`（默认并发，期望 pass ≥ 3682 + 新单测数、0 fail、无 `-1`）。
- [ ] **Step 6: 真机目检兜底**（关键·防静默视觉回归）：`VISUAL_ROUTE=battle_charge_break bash tool/visual_capture.sh`（或既有验收脚本）跑一帧，肉眼确认弹道/飘字/受击闪/大招题字/破界闪白/屏震/读秒环与现状等价。异常则回退查 rebuild 接线。
- [ ] **Step 7:** commit `refactor(battle): 抽 playAction 本体完成 controller 抽离 + 单测` → 更新 PROGRESS 顶段（四态）+ session doc。

---

## 自审（spec 覆盖 / 无 placeholder / 类型一致）
- spec「边界表/rebuild 机制/vsync-ref 安全/4 切片/验收 oracle」逐条对应 Task 0–4 ✓
- 无 TBD/TODO；每 Task gate 命令具体、期望明确 ✓
- API 命名跨 Task 一致（`_playback`/`playAction`/`startTimer`/`pause`/`resume`/`applyHitStop`/getters）；Task1/3 临时 public 的内部方法在 Task4 Step1 显式收回 private ✓
- 已知残余风险：controller 单测的 WidgetRef 构造方式（Step3 给了两条退路）；`slotFrac` 若含 `dart:ui` 类型则 Task0 Step2 留 State（已注明）。
