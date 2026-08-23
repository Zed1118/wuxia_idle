# 主线群怪波次独立切片

## 目标

为 Phase 0A 主线生产路径增加 YAML 驱动的普通关连续小怪波次；Boss 关先清理小怪波次，再由唯一主敌人收尾。复用 `Phase0aWaveBattleFlow` 与同核 headless，不恢复旧 3v3，不修改叙事或 Boss/玩家/招式数值。

## 分支与工作区

- 分支：`codex/mainline-mob-waves`
- 唯一工作区：`/Users/a10506/Desktop/Projects/挂机武侠-wt-mainline-mobs`

## 验收标准

1. `data/numbers.yaml` 提供普通关/Boss 关波次数、每波敌人数、派生 HP/攻击/速度比例及波间规则；Dart 不硬编码这些玩法参数。
2. `NumbersConfig` 有强类型配置解析；配置缺失时 fixture 保持旧单波兼容，生产配置启用主线群怪。
3. schema/validator 拒绝空波、非法人数/比例、Boss 非唯一主敌、普通关误配 Boss 收尾等死配置。
4. 真实 `Phase0aMainlineBattleHost` 只对 `StageType.mainline` 使用多波；Boss 机制快照只在最后收尾波，前置小怪不带 phase/charge/vulnerability/guardian。
5. actor id 全局唯一；live/headless 共用同一 mapping；奖励结算仍只走一次。
6. `lightFoot`/`innerDemon`/`massBattle`、`mapTower`/`mapExpedition` 不受影响；不恢复旧 3v3，不改叙事，不突破红线。
7. targeted tests、`flutter analyze` 通过；逐切片 commit；最终 tip 前缀 `[READY]`，工作区 clean。

## 任务切片

- [x] A. 配置模型与 numbers YAML：新增主线波次 profile、解析和字段校验。
- [x] B. mapper 生产接线：派生小怪快照，Boss 最后一波保留唯一主敌人，并复用现有 transition policy。
- [x] C. validator 与回归测试：配置红线、映射 actor 唯一、普通/Boss 结构、隔离非主线映射及奖励一次性。
- [x] D. targeted tests + analyze，检查 diff 与红线后提交 `[READY]`。

## 当前恢复点

- 状态：已完成，worktree 将在 `[READY]` 提交后冻结。
- 最后完成：mapper 24/24、主线 wiring 17/17、schema 3/3、repository 77/77、全内容 preflight 1/1。
- 下一步：由主线程审查三枚实现提交与本恢复点；不要把 89/447 胜率当作平衡通过。
- 已跑验证：scoped `flutter analyze` 0 issue；全仓 analyze 受仓库既有 `tools/phase0minus_probe` 缺失依赖阻断。
- 阻塞项：平衡未验收（全内容 diagnostic 358 defeat），需后续独立平衡/试玩批，不在本切片擅自调参。
