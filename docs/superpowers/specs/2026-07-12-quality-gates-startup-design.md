# 质量门禁与启动可靠性设计

> 上位方案：`/Users/a10506/Desktop/挂机武侠_最终优化方案_2026-07-12.md`
> 范围：第一阶段质量收益最高项；不改战斗数值、不改存档 schema、不改变生产流程

## 目标

把已有首通诊断中稳定成立的体验不变量升级为可解释的测试门禁，补齐 Splash 加载/跳过/导航防重测试，并完成两项低风险仓库卫生治理。

## 方案比较

### 方案 A：直接给所有诊断候选加硬断言

优点是简单；缺点是当前大量普通关和 Boss 仍低于理想动作目标，会迫使本批顺带调整数值，违反“不改 numbers”的范围。

### 方案 B：在现有真实模拟内建立渐进 ratchet（采用）

复用 `readable_first_clear_tempo_diagnostic_test.dart` 的 30 关 × 2 profile × 20 seed 结果，只门禁当前稳定成立且具有体验意义的不变量：章末 Boss floor 动作下界、floor 不短于 ceiling、已配置阶段的 Boss 机制可见。已知过短/高血量问题继续留在报告候选中，后续调参批再收紧。

### 方案 C：提交 CSV 基线并逐行比较

实现快，但会把随机模拟输出格式、浮点和字段顺序变成测试 Interface，维护成本高，不采用。

## 首通 ratchet

### 数据来源

只使用现有真实生产 YAML、`StageBattleSetup.debugApplyReadableFirstClearTuning`、`defaultGroundStrategy.runToEnd` 和固定 seed，不建立第二套战斗模型。

### 第一阶门禁

1. 六个章末关 `stage_01_05` 至 `stage_06_05` 的 floor profile 平均动作行不得低于 6。
2. 最终章 `stage_06_05` 的 floor profile 平均动作行不得低于 8。
3. 每个章末关的 floor 平均动作行不得短于 ceiling；欠配投入至少不能比较高投入更快结束。
4. 配置了 `bossPhases` 的 Boss，phase 和 charge 可见行都必须大于 0；沿用现有机制候选计算。

这些数值是对当前已达成行为的保守下界，不是新的理想目标，也不授权调整 `numbers.yaml`。

### 失败信息

每个断言必须带 stage/profile、实际平均值和门槛，避免只输出集合不知原因。

## Splash seam

### 现状

Splash 直接调用 `GameRepository.loadAllDefs()` 并直接构造 `SaveSelectScreen`，测试无法控制加载完成时机，也无法隔离真实存档选择页。

### 设计

给 `SplashScreen` 增加两个可选构造参数：

- `Future<void> Function()? loadDefinitions`：未提供时执行现有生产加载和 debug 日志；测试传入 `Completer<void>.future`。
- `WidgetBuilder? nextScreenBuilder`：未提供时构造现有 `SaveSelectScreen`；测试传入轻量目的页。

默认值保持生产行为逐字等价。该 seam 只改变可测试性，不改变玩家行为。

### 测试行为

1. 加载未完成时点击不导航。
2. 加载完成且最短展示结束后自动导航。
3. 加载完成后点击可跳过剩余展示时长。
4. 连续点击只产生一次导航。

加载失败的产品行为需要独立设计拍板，本批不吞异常、不新增重试或错误页。

## 卫生项

1. 将 `/Builds/` 加入共享 `.gitignore`；保留本机 `.git/info/exclude` 不动。
2. 删除全仓零引用的 `cupertino_icons` 直接依赖，由 `flutter pub remove` 同步 lockfile。
3. 将 pubspec 资产注释中的退役 DeepSeek 口径改为 Mac 单端维护；不修改 GDD、CLAUDE、numbers 或 schema。

## 测试与红线

- ratchet 只改测试，不改战斗 Implementation 和数据。
- Splash 生产默认路径不变。
- 不触及数值硬红线、三系锁死、在线=离线和反主流清单。
- 不新增 Dart 玩家文案或游戏数值。
- 验证：ratchet targeted、Splash targeted、`flutter analyze --no-pub`、批末全量 `flutter test --no-pub`。

## 非目标

- 不调整任何关卡数值。
- 不拆 `GameRepository/NumbersConfig`。
- 不修改存档迁移或战斗结算。
- 不增加 Windows CI。
- 不删除任何现有 worktree 或分支。
