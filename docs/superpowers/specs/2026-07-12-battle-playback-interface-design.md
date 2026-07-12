# 战斗播放 Interface 最小深化设计

## 背景

`BattlePlaybackController` 已拥有 Timer、hit-stop、AnimationController 和 dispose，
但 `BattleScreen` 构建树仍直接读取：

- attack/hit-flash controller 列表；
- hit-flash 颜色、飘字、弹道和特效集合；
- shake/closeup controller 与屏震幅度；
- ScreenFlash、UltimateCaption、ImpactGlyph 三个 GlobalKey。

页面因此必须理解播放模块的资源拓扑和组合顺序。最终优化方案要求页面主要消费播放
状态和用户意图，把动画资源、时序与 dispose 规则留在 Module 内。

## 方案比较

### A. 巨型 `BattlePlaybackViewState`（不采用）

把所有 controller/list/key 装入一个 DTO 只改变包装形态，知识泄漏仍然存在。

### B. Controller 直接构建整个 BattleScreen（不采用）

可以隐藏资源，但会把 Header、BottomBar、待发态和日志等业务交互吞入播放控制器，
边界反而过深。

### C. 同库播放视图组件（采用）

在 `battle_playback_controller.dart` 的同一 Dart library 中增加 part 文件，提供三个
职责单一的组件：

- `BattlePlaybackMotion`：closeup + shake 包装；
- `BattlePlaybackField`：BattleField + projectile/effect layers；
- `BattlePlaybackOverlays`：三个命令式 overlay key 的宿主。

组件能读取 Controller 私有资源，`BattleScreen` 只传业务状态、交互回调和 child。

## Interface 变化

删除 Controller 的公共资源 getter：controllers、颜色 Map、VFX/Popup 集合、shake/
closeup controllers、三个 GlobalKey。`impactShakeAmplitude` 改为私有。

保留：

- `isPaused`、`isFastForward`、`hasTimer` 等可展示播放状态；
- pause/resume/start/toggle/playAction 等用户意图和播放命令；
- `beat`，但类型只暴露为 `Animation<double>`，供 BottomBar 的读秒环消费；
- 明确标注 `@visibleForTesting` 的最小 debug 查询，不把 AnimationController/GlobalKey
  重新暴露给测试。

## 行为与布局

- AnimatedBuilder 嵌套、Transform.scale/translate 公式和原 child 顺序完全保持。
- BattleField、ProjectileLayer、EffectLayer 的 Stack 顺序不变。
- overlay 仍按 ScreenFlash → UltimateCaption → ImpactGlyph 顺序覆盖全屏。
- 不改时长、颜色、动画曲线、命中判断、Timer、pause/fast-forward 或 dispose 顺序。
- BattleScreen 的 Header/BottomBar/待发态/日志/暂停遮罩仍由页面拥有。

## 测试

1. RED 架构守卫：`battle_screen.dart` 不得再出现资源 getter 名称。
2. Controller 原测试迁移到 test-only debug 查询，继续验证 popup、trail/effect 和 beat。
3. BattleScreen 在 1280×720 与 1440×900 渲染，确认无异常/overflow。
4. 运行 pause/start-paused/log/target-chip/command-console 等相关 widget tests。
5. `flutter analyze --no-pub`、格式、diff 和全量测试。

## 红线与残留风险

- 纯表现层重构，不改 BattleState、数值、在线/离线、存档、结算、文案或资产。
- 不按文件行数拆页面，不增加状态管理或依赖。
- 自动化可以证明结构、布局与行为；最终动画细腻度仍需 Mac 真实窗口目检，Windows
  性能/音频仍属于外部发布验证。
