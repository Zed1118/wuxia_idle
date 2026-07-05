# BattleScreen C 批次 · BattlePlaybackController 抽离 — 设计

**日期：** 2026-07-05
**承接：** P2b 策略 B（`battle_screen.dart` 3312→1433 行，widget 已拆）之直接续作
**性质：** 重构（**非纯移动**——改 rebuild 接线，需真机目检兜底）

## 背景

B 批次把 26 个叶子 widget + 3 数据类拆出后，`_BattleScreenState` 仍 ~1433 行，剩下的是**动画/VFX 编排 + 拍钟调度**的 controller soup。C 批次把这块抽成一个 State 拥有、可独立单测的 `BattlePlaybackController`。

## 目标 / 非目标

**目标**：真隔离 + 可测——动画/VFX/拍钟子系统抽成单一 controller 对象，`battle_screen.dart` 降到 ~600–700 行；此前埋在 State 无法单测的 spawn/hit-stop/pause 逻辑获得单测。
**非目标**：不改 rebuild 粒度（不引 ChangeNotifier）、不改 strategy/battle provider/`advance()` 结算路径、不改任何视觉表现、不动 numbers/schema/saveVer。

## 现状（Phase 0 实测）

State 三块职责（缠绕）：
- **A｜拍钟调度**（最高耦合）：`_playTimer`/`_hitStopTimer`/`_beatCtrl`/`_startTimer`/`_togglePause`/`_toggleFastForward`/`_applyHitStop` + `_isPaused`/`_isFastForward`，驱动 `notifier.advance()`/`advanceOneAction()`。
- **B｜VFX 编排**（中耦合）：`_playAction`/`_playBossPhaseTransition`/`_playGuardianWardBreak`/`_spawnPopup`/`_spawnTrail`/`_spawnBattleEffects`/`_spawnEffect`/`_triggerHitFlash`/`_removePopup` + 三份 entry 队列（`_activeTrails`/`_activeEffects`/`_popups`）+ 4 组 AnimationController + 3 个 overlay GlobalKey，由 `ref.listen(battleProvider)` 的 actionLog/charge-sfx/ward-break 三条边沿驱动。
- **C｜交互选择态**（留 State）：`_pendingSkill`/`_pendingCharId`/`_focusSlotIndex`/`_logOpen`/`_hoveredPendingEnemyId`/`_skillTargetLink`/`_resultDialogShown` + `_onSkillTap`/`_onSkillCommand`/`_onEnemyTap`/`_onPendingEnemyHover`/`_onSelectFocus`/`_clearPending`/`_buildTargetChipOverlay`/`_showResultDialog`。

**两条硬约束**（决定方案）：
1. 所有 AnimationController 都 `vsync: this` → 抽出目标必须能拿 TickerProvider；而 `_BattleScreenState` 私有字段**跨库不可见**，mixin 抽到独立文件会逼迫去私有化 ~20 字段（远丑于 B 的 4 个）→ 干净路径是 **controller 对象**，非 mixin。
2. A 与 B **不能干净切开**：`_applyHitStop`(A) 从 `_playAction`(B) 里回手 cancel `_playTimer`；`_beatCtrl` 同时是动画又被 Timer 驱动 → **合成单 controller**，避免拆两对象的跨对象接线。

## 方案：`BattlePlaybackController`

文件：`lib/features/battle/presentation/battle_playback_controller.dart`（持 AnimationController/Color → presentation 层，同 B 架构规则）。

### 边界

| 区 | 归属 |
|---|---|
| A 拍钟 + B VFX（上列全部字段/方法） | **搬进 controller** |
| C 交互选择态 + `build()`（含 3 条 ref.listen）+ 结算弹窗守卫 | **留 State** |

**seam（单向委托，无回环）**：
- 交互方法调 `controller.pause()/resume()/startTimer()/toggleFastForward()`。
- `ref.listen` 边沿调 `controller.playAction(a, next)`/`playGuardianWardBreak(c)`/`onBattleFinished()`（停 timer+停 beat）。
- build 子 widget 读 `controller.activeTrails/activeEffects/popups/attackControllers/hitFlashControllers/hitFlashColors/beatCtrl/shakeCtrl/closeupCtrl/impactShakeAmplitude/ultimateCaptionKey/impactGlyphKey/screenFlashKey/isPaused/isFastForward` 当 props。
- controller **不反向持** State 私有交互态。

### rebuild 机制：注入 setState（保真·近纯移动）

- controller 构造收 `required void Function(VoidCallback) rebuild`（= State 的 `setState`）。原 `setState(() => _activeTrails.add(...))` → `rebuild(() => _activeTrails.add(...))`；原裸 `setState((){})` → `rebuild((){})`。
- **rebuild 粒度逐字节不变**（仍整 State rebuild）→ 画面数据流与现状等价，把「非纯移动」风险压到最低。
- **不采用 ChangeNotifier + ListenableBuilder**：性能更好但改 rebuild 粒度、引真视觉回归面；性能非本批目标。
- 可测性照样兑现：单测传记录用 `rebuild` 回调，断言 controller 正确 mutate 队列 / forward 对应 AnimationController。

### vsync / ref 安全性

- vsync：State 保留 `with TickerProviderStateMixin`；`initState` 里 `controller = BattlePlaybackController(vsync: this, ref: ref, rebuild: setState, animConfig: widget.animConfig, ...)`；`dispose` 里 `controller.dispose()`（迁移全部 AnimationController + Timer 释放）。
- ref：传 **ConsumerState 的 `ref`**（State 生命周期内稳定，非 provider Ref）——现状 `_startTimer` 本就在 Timer 回调里 `ref.read(...)`，搬进 controller 持同一 ref 行为逐字节等价，不踩 Riverpod 闭包 ref-disposed 坑。`notifier.advance()`/`gameplaySettings`/`numbersConfig`/`impactFeedback` 全走 controller 持的 ref，同源。

## 验收 oracle（非纯移动，比 B 加码）

- `flutter analyze lib/ test/` = **0**（去私有化的 public 符号补 `super.key` 不适用——controller 非 widget；public API 命名遵项目规范）。
- `test/features/battle/` **569 全绿** + 批末全量零回归（基线 3682 pass/1 skip/0 fail）。
- **新增 `test/features/battle/battle_playback_controller_test.dart`**：单测 spawn（popup/trail/effect 入队 + id 分配）、hit-stop（cancel+复播）、pause/resume、fast-forward 间隔切换、beat 对齐——兑现「可测」。
- **真机目检兜底**（关键·防静默视觉回归·B 批次不需要）：`VISUAL_ROUTE=battle_charge_break` 等既有路由跑一帧，确认弹道/飘字/受击闪/大招题字/破界闪白/屏震/读秒环表现与现状等价。

## 落地节奏（plan 细化 · 小切片可回退）

1. 建 controller 骨架，搬**纯 VFX spawn + 队列 + entry 生命周期**（trail/effect/popup），State 委托。
2. 搬 **beat/timer/hit-stop/pause/fast-forward** 拍钟调度。
3. 搬 **overlay-key 命令式编排**（ultimate caption / impact glyph / screen flash / boss phase / ward break）。
4. 收尾：清 State 残留 import，补 controller 单测，全量 + 真机目检。

每步 `analyze` + battle targeted 绿方进下一步；任一步红即回退该切片。

## 风险 & 回退

- **风险**：非纯移动，rebuild 接线/dispose 归属/ref 线程迁移出错会导致画面不更新或 controller 泄漏 → 靠 targeted 绿 + 真机目检 + 单测三道兜。
- **回退**：切片 commit，任一步失败 `git reset` 回上一稳定切片；controller 是新增文件，最坏整体 revert 不影响 B 批次成果。
- **零碰红线**：不动 numbers/结算/schema/saveVer/三系锁死/在线=离线/§5.4；纯 presentation 层重构。
