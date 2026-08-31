# Phase 2 M5/U14 轻功与守城持久差遣收口计划

## 目标与基线

- branch: `codex/p2-m5-u14-durable-automation-20260831`
- worktree: `/Users/a10506/.codex/worktrees/p2-m5-u14-durable-automation-20260831`
- base: `1800c9f666aba995788b930ea1ee206b24ca3e88`
- 单一目标：以一次加法迁移接通轻功、守城的 durable automation 生产闭环，并与既有四模式真实准入合并关闭 U14 六模式允许矩阵。
- 固定分母：轻功 `0/1 → 1/1`、守城 `0/1 → 1/1`、U14 `0/1 → 1/1`；不据此晋升 M5、M6 或顶层 M0–M9。

## 已授权边界

- 允许扩展非持久化 combat catalog/runtime schema，为守阵实体增加位置、耐久、选敌与受击合同，并允许 `stage_02_01` 守阵 TUNING 候选；该前置 M4 已在本批开始时单独合入。
- 允许一次加法 Isar 迁移，扩展 `schemaVersion/saveVersion`、`ActivityKind` 与 `CharacterOccupancyService`，增加轻功/守城 durable run、实际参与者与装配占用、守城阵型快照、离线游标和幂等 settlement receipt。
- 复用既有 Phase 0A reducer、内容 mapper、headless runner 与共享 settlement。
- 不改玩家数值、技能、奖励金额、经济、战斗规则、YAML TUNING、Isar 历史数据含义或旧档推导；不启动 M3/M4 新任务。
- 真人试玩、常规桌面视觉与手感验收全部挂账，不用自动化代签。

## §8.2 验收清单

1. 生产接线：首通后的轻功/守城列表出现差遣入口；typed request 经 durable admission、exact snapshot、统一占用、既有 mapper/headless 与共享胜败 settlement 落 receipt；守城只消费持久阵型。
2. targeted：policy、service、occupancy、runner、coordinator、迁移、两模式 UI 与六模式矩阵全部通过。
3. 红线：纯加法迁移；旧档不伪造 active run/receipt；不改数值、技能、奖励、经济、解锁、战斗公式或 reducer。
4. 残留风险：真人对差遣入口、报告可读性及守城阵型选择的目检挂账；最低档 Windows 与正式发布 Gate 不在本单。
5. 破坏证红：至少“移除实现”和“强制退化值”双向各证红一次，精确还原。
6. 批末：`dart format .`、整仓 analyze、风险匹配 targeted、建锁全量、独立 Gate、clean READY、受控合并与 push。

## 任务切片

- [x] M4 七模板候选受控合入、全量并 push。
- [x] 新增 `DurableActivityCombatRun` 与 `0.41.0` 纯加法迁移。
- [x] 扩展五类统一占用并锁定轻功/守城实际参与者及装配。
- [x] 接通轻功、守城 typed policy/service、生产入口和恢复报告。
- [x] 复用同一 mapper/headless/settlement；守城阵型快照进入真实 mapper。
- [x] 六特殊模式真实 production owner 矩阵闭合。
- [x] 双向破坏证红。
- [x] 整仓验证。
- [ ] 独立 Gate。
- [ ] READY、合并 main、push 与最终挂账。

## 当前恢复点

- 状态：候选已具备 READY 条件；独立 Gate、合并与 push 尚未执行。
- 最后完成：最终 targeted `70/70 PASS`；带锁全量退出码 0、`5774/5774 PASS`、末行 `All tests passed!`、`[E]` 0，锁已精确释放；工作树 clean。
- 下一步：打 `[READY]` tip，生成 receipt，执行测试契约迁移门和独立 Gate；通过后受控合并 main、复验并 push。
- 已跑验证：activity/light-foot/mass-battle/地点详情/sweep/migration 组合 `70/70 PASS`；整仓 analyze 0 issue；整仓 format `1674 files / 0 changed`；双向破坏证红 `2 FAIL / 1 FAIL` 后精确还原；带锁全量 `5774/5774 PASS`。
- 阻塞项：无外部阻塞；真人目检为明确挂账，不阻止当前工程候选进入 main。
