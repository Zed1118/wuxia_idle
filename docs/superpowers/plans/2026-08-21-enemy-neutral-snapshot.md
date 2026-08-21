# 敌方装配器中立快照收口计划

> 日期：2026-08-21
> 分支：`codex/enemy-neutral-snapshot-0821`
> 状态：READY
> 上位：路线 C 旧 3v3 → Phase 0A 单角色 ARPG 替换收口

## 目标

让 `EnemyCombatantSnapshotAssembler` 直接构造 engine-neutral
`CombatantSnapshot`，移除其内部 `BattleCharacter → legacy adapter → snapshot`
中转。旧主线/塔等接口仍由外部 legacy adapter 消费中立快照，本批不拆旧入口、
不改 YAML、公式、数值或装配语义。

## 验收标准

1. **生产接线证据**：Phase 0A mapper、远征/断魂庄敌方装配继续消费同一 assembler；
   旧 `StageBattleSetup` 继续经 legacy adapter 获得旧角色，接口不变。
2. **targeted test**：敌方装配器逐字段旧路径对照、Phase 0A mapper/flow、主线接线通过。
3. **红线影响**：周目缩放、境界推进、Boss phase、guardian/vulnerability、真气与
   首通可读调节逐字段守恒；零 YAML/公式/数值变化。
4. **残留风险**：玩家装配器复杂派生仍单独保留；不迁远征/断魂庄结算，不触六人或
   Windows Gate。
5. **源码 Gate**：assembler 禁止回引 `battle_state.dart`、legacy adapter 与
   `BattleCharacter`。
6. **UI**：无表现与交互修改，不新增视觉验收。
7. **提交 Gate**：工作区干净；中文动宾 commit；无生成物/日志/截图误提交。

## 任务切片

1. [x] 直接构造 `CombatantSnapshot`，保持字段与默认值逐项同值。
2. [x] 补 assembler 源码契约并运行逐字段回归。
3. [x] 运行 format、targeted tests、analyze 与批末全量。
4. [x] 更新 PROGRESS/NEXT 与恢复点，提交稳定切片。

## 当前恢复点

- 状态：READY
- 最后完成：assembler 直构 `CombatantSnapshot`，源码 Gate 禁旧角色中转；PROGRESS/NEXT 已收账。
- 下一步：主线审查并合并；低消后续优先 D5 全内容 headless 画像 harness。
- 已跑验证：敌方逐字段对照 3/3、Ch1 mapper/headless 12/12、production flow 10/10、主线接线 15/15；`flutter analyze` 0 issue；全量 **5257 pass / 0 fail**。
- 阻塞项：无。
