# P2 G2 D07：Production Encounter 装配入口

## 目标

在 `Phase0aProductionFlowAssembler`（`lib/features/battle/application/phase0a/phase0a_production_flow_assembler.dart`）新增显式 `assembleEncounter` 静态入口，把 Batch4 动态 runtime（`Phase0aEncounterFlow.runtime`）接入既有生产快照工厂、真实伤害 adapter 与单一 caller RNG 所有权。本切片只建装配入口，不切换主线宿主，不猜黑风岭 encounter 数据，不 token enforce。

## 分支

`codex/phase2-g2-d07-production-assembler-20260823`（当前 worktree，HEAD `d6d58073`）。

## 冻结契约（Batch5 协调计划 + 本切片）

- `assembleEncounter` 显式接收 `initialState` / `director` / `roster` / `combatants` / `moveBindings` / `numbers` / `rng` / player+enemy adapters，以及可选 observe-only enemy-intent observer。
- expected actor IDs = `initialState.player.id` + roster 全部 enemy IDs（`roster.bindings[*].actorId`）；missing/extra 稳定排序后 fail closed（消息格式与 legacy `_checkActorCoverage` 同体例）。
- player adapter ID 与 move binding 校验复用既有口径（同一消息、同一顺序），不复制伤害或数值逻辑。
- 只创建一个 `Phase0aDamageCalculatorAdapter` 和一个 `Phase0aCombatSession`；同一 caller RNG 跨所有敌人与拍连续消费；`enemySkillDamageResolver` 复用同一 adapter 实例。
- director/roster identity、tick、active arena、side/alive 的 fail-closed 校验继续由 `Phase0aEncounterFlow.runtime` 构造器负责，装配器不复制也不吞掉。
- legacy `assemble` 签名、返回类型、默认路径、两波 RNG 连续性与主线路由零改动。

## 验收 checklist（本切片）

- [ ] encounter 全 actor 真实快照覆盖；missing/extra/playerId/move-binding 异常在首拍前 fail-fast 且零 RNG 消费（`rng.nextDouble() == 同 seed 未消费对照`）。
- [ ] 真实 damage adapter 与 direct `calculateResolved` 同 seed 连续序列逐击同值；按拍/按敌重置 RNG 的反例可判别。
- [ ] warning/entry/grace/kill/reinforcement/terminal 全经 assembler 入口完成（不只手工 session fixture）。
- [ ] observe-only observer 连续多拍存活、只观察 grace gate 后 intents、不改 events/state/RNG（同 seed 对照）。
- [ ] existing assembler / wave / headless / retry / mainline 回归继续通过（targeted + scoped analyze）。
- [ ] 不改 mapper/stage data/host routing/tuning/UI/reward/injury/save；不猜黑风岭 encounter 数据。
- [ ] `dart format` 0 changed、`git diff --check` 净、scoped `flutter analyze` 0 issue。

## 任务切片

1. 计划文件落盘（本文件）。
2. 在 `test/features/battle/application/phase0a/phase0a_production_flow_assembler_test.dart` 补 D07 测试组（先红）。
3. 在 `lib/.../phase0a_production_flow_assembler.dart` 实现 `assembleEncounter`（复用 `_checkMoveBindings` / playerId 校验 / 快照工厂 / damage adapter）。
4. `dart format` 目标文件 → targeted `flutter test`（assembler + encounter + seams + observer）→ scoped `dart analyze` → `git diff --check`。
5. diff 复审 → 普通中文动宾 commit → 空 commit `[READY][PI][P2-G2-D07] 完成 Production Encounter 装配入口`。

## 当前恢复点

- 状态：**D07 已完成**（实现 + 测试 + 验证全绿，待合并评审）。
- 最后完成：`assembleEncounter` 显式入口 + `_checkEncounterActorCoverage`；测试补 12 项 D07 断言（missing/extra/playerId/binding/runtime 校验穿透零 RNG、同 seed direct 连续序列逐击同值、完整生命周期经 assembler 入口、observe-only observer 跨击杀/补员存活）。
- 已跑验证：targeted `phase0a_production_flow_assembler_test.dart` 23/23 PASS；回归（encounter compatibility / session seams / dynamic flow / headless / wave / observer / spawn_director / roster / mainline / tower）133/133 PASS；`dart format` 0 changed；`git diff --check` 净；scoped `dart analyze` 0 issue。
- 下一步：Codex 主控 diff 复审；D08 在公开入口冻结后补 runtime+observe-only 连续多拍组合回归。
- 阻塞项：无。
- 最后完成：Batch5 立项（`d6d58073`）；Batch4 READY `21e17ecc` 为起点。
- 下一步：先补测试再实现。
- 已跑验证：无（本切片未提交）。
- 阻塞项：无；content loader / 黑风岭 tuning 未进入本批。
