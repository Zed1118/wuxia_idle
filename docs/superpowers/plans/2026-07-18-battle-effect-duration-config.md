# 战斗贴片时长数据化计划

> 上游稳定点：`codex/battle-fast-forward-transition@e5719438`
> 分支：`codex/battle-effect-duration-config`

## 1. 目标

把战斗贴片基础寿命从播放控制器硬编码的 520ms 移入 `animation.battle_effect_ms`，维持当前观感与快进一拍 clamp，同时为后续特效调优提供单一数据入口。

## 2. 方案

- `AnimationNumbers` 新增 `battleEffectMs`，默认与生产 YAML 均为 520。
- `fromYaml` 解析新 key，旧测试 fixture 缺 key 时兼容默认。
- `_spawnEffect` 仅消费配置字段，不改变同组合流、快进 clamp 或退场释放。

## 3. 验收

- [x] YAML、默认值与解析值三者一致。
- [x] 常速 520ms 续播生命周期不回归。
- [x] 快进仍 clamp 到一拍，不被 520ms 配置覆盖。
- [x] 数据测试、战斗模块与 analyze 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：可冻结。
- **最后完成**：`animation.battle_effect_ms` 已成为 YAML→解析→播放控制器的单一真相源，旧 fixture 缺 key 兼容 520。
- **下一步**：提交 `[READY]` 稳定点，继续做战斗 UI/特效配置收口复核。
- **已跑验证**：AnimationNumbers 19/19；数据/仓库/播放定向 88/88；战斗+动画配置+仓库 806/806；`flutter analyze --no-pub` 零问题。现值和布局均未改变，继承双视口实机验收。
- **阻塞项**：无。
