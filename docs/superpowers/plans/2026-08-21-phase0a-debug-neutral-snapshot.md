# Phase 0A debug fixture 中立快照收口计划

> 日期：2026-08-21
> 分支：`codex/phase0a-debug-neutral-snapshot-0821`
> 状态：READY
> 上位：路线 C 旧 3v3 → Phase 0A 单角色 ARPG 替换收口

## 目标

移除 `Phase0aDebugBattleFixture` 对旧 `BattleCharacter` 与
`Legacy3v3CombatantAdapter` 的反向依赖，直接从既有 typed YAML 构造
engine-neutral `CombatantSnapshot`。本批不修改 YAML、伤害公式、战斗数值或
玩家可见行为。

## 验收标准

1. **生产接线证据**：debug 可玩路由继续通过同一
   `Phase0aProductionFlowAssembler`，fixture 仅替换开战前快照来源。
2. **targeted test**：debug fixture、Phase 0A 源码契约与视觉路由测试通过。
3. **红线影响**：零 YAML/公式/数值变化；三系锁、在线=离线和反主流边界不受影响。
4. **残留风险**：不迁远征/断魂庄/扫荡；不提前触发六人主观 Gate 或 Windows Gate。
5. **源码 Gate**：测试明确禁止 debug fixture 回引 `battle_state.dart`、legacy adapter 或
   `BattleCharacter`。
6. **交互/UI**：无交互与布局修改，不需新增视觉验收；沿用 2026-08-21 双视口基线。
7. **提交 Gate**：工作区干净；commit message 使用中文动宾；不提交截图、日志或生成物。

## 任务切片

1. [x] 用 `CombatantSnapshot` 替换 fixture 内旧角色构造与 legacy adapter。
2. [x] 扩展 Phase 0A 源码契约覆盖 debug fixture。
3. [x] 运行 format、targeted test 与 analyze。
4. [x] 更新本计划恢复点，提交稳定切片；PROGRESS/NEXT 随中立 seam 批末统一收账。

## 当前恢复点

- 状态：READY
- 最后完成：fixture 直接构造 `CombatantSnapshot`，源码 Gate 禁止回引旧角色与 legacy adapter。
- 下一步：主线审查并合并；PROGRESS/NEXT 随中立 seam 批末统一收账。
- 已跑验证：debug fixture 4/4、Phase 0A 源码契约 20/20、视觉路由 6/6、`flutter analyze` 0 issue。
- 阻塞项：无。
