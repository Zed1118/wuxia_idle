# P2-M2-R11：组合迁移遭遇运行计划

## 目标与边界

在 typed migrated route、R04 runtime contract mapper、R07 roster mapper 与现有
`Phase0aEncounterMapping` 之上新增一个纯组合 builder。builder 只按固定顺序创建
runtime bundle → 用同一 `SpawnDirector` 创建 roster → 创建 mapping，不接
production host，不复制任何 assembler/runtime 校验。

- 分支：`codex/phase2-m2-r11-migrated-encounter-plan-builder-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r11-migrated-encounter-plan-builder`
- 精确基线：Batch13 READY `77c5520e04355e041a5db6b40dde05b169874117`
- 白名单：builder、对应测试、本计划共 3 文件。
- 禁止：`main`、registry、audit、其他 lib/test/docs、host/repository/IO/YAML/UI/save/reward/
  injury/tuning/candidate/default。

## 冻结合同

- `Phase0aMigratedEncounterPlan` 持有 exact typed
  `MigratedCombatStageEncounterRoute route`、fresh
  `CombatEncounterRuntimeContractBundle runtimeContracts`与 fresh
  `Phase0aEncounterMapping mapping`；`stageId` / `encounter` / `roster` 只是便捷 getter。
- `buildPhase0aMigratedEncounterPlan` 只接受 `route`、`tickDuration`、
  `resolveEnemyId`、`playerId`、`createActor`、`initialState`、`combatants`、
  `moveBindings`、`playerAdapter`、`enemyAiAdapter`。
- 顺序严格为：`mapCombatEncounterRuntimeContract(route.encounter)` →
  `mapCombatEncounterRoster(route.encounter, runtimeContracts.spawnDirector)` →
  `Phase0aEncounterMapping`。bundle / mapping / roster 必须共享同一 director identity。
- typed migrated route 从签名层排除 legacy；不使用 `switch`、`catch`、fallback、
  legacy 参数或 stage/content 二次解析。
- resolver 与 actor factory 依现有 mapper 合同按 content order 每项精确一次；
  resolver 抛错时 factory 零调用，factory 异常原样传播。
- 每次 build 必须返回 fresh plan / bundle / director / controller / roster / mapping；
  不宣称 caller 所有的 arena/adapters/actors 被深冻结。
- caller `combatants` / `moveBindings` 后续突变不回渗，由 mapping 既有
  防御性副本合同保证。
- builder 不接 `Random`、`NumbersConfig`、IO、repository、host、candidate、default、
  tuning；不复制 actor coverage、playerAdapter、move binding、tick、active-enemy
  或 director/roster 底层校验。

## 验收 checklist（CLAUDE §8.2）

- [ ] TDD 红测由目标 builder/API 缺失触发，后续转绿。
- [ ] exact stage/encounter identity；resolver/factory content order exact once。
- [ ] resolver throw 时 factory 零调用；factory throw 原样透传。
- [ ] bundle/mapping/roster director identity 同一；重复 build 的 builder-owned
  director/controller/roster/mapping 均 fresh。
- [ ] caller combatants/moveBindings 后续突变不回渗。
- [ ] 将 `plan.mapping` 交给既有 assembler/runtime，证明 coverage/playerAdapter/
  move/tick/active-enemy fail-close 继续委托。
- [ ] source guard 禁止 legacy 参数、`Random`、`NumbersConfig`、IO、repository、
  host、candidate/default/tuning，且无 `switch`/`catch`/fallback。
- [ ] 生产接线证据：这一切片交付 typed migrated plan 组合 seam；依授权
  不改 production host，不冒充已上线。
- [ ] 红线说明：0 production 数值/公式/玩家文案，0 三系/在线离线/
  反主流/奖励/伤势/save/UI 触点。
- [ ] targeted builder + 既有 mapper/mapping/assembler/runtime 回归通过；scoped
  analyze 0 issue；format、`git diff --check`、严格白名单通过；不跑 full。
- [ ] Qoder CLI 1.1.x 精确 `Qwen3.8-Max` / reasoning `high` 编码前设计
  审查与最终 diff 审查均留存真实证据。
- [ ] 小切片中文动宾 commit；最后追加精确
  `[READY][QODER][P2-M2-R11] 组合迁移遭遇运行计划` 空提交。

## 任务切片

1. 读取红线/恢复/提交规范、已否清单与 route/runtime/roster/mapping/
   assembler 合同，提交本计划恢复点。
2. 实际用 Qoder/Qwen3.8-Max/high 完成编码前只读设计审查。
3. 新增 builder 测试并跑出有效红灯；用 `apply_patch` 实现薄组合。
4. 运行 targeted 与 scoped analyze；用同一 Qoder 配置审查最终 diff，
   由 Codex 复核 findings。
5. 更新计划证据，提交实现，完成 format/diff/path 审计后打 READY。

## Qoder 审查

- CLI/version：待实测。
- 设计审查：待执行（必须 `Qwen3.8-Max` + `high`）。
- 最终 diff 审查：待执行（必须 `Qwen3.8-Max` + `high`）。
- 不记录或输出 token/key。

## 当前恢复点

- 状态：计划已写，待提交恢复点与 Qoder 编码前设计审查。
- 最后完成：核对 worktree 干净且 `HEAD=77c5520e`；完整读取 CLAUDE
  红线/§8/§11、已否清单、migrated route、runtime/roster mapper 与
  mapping/assembler 委托边界。
- 下一步：提交计划；用 Qoder/Qwen3.8-Max/high 只读审查冻结合同和
  测试矩阵。
- 已跑验证：`git status` 干净，`git diff --check` 通过，三个目标文件
  起始均不存在。
- 阻塞项：无。
- 生产接线：按授权仅交付后续 host 消费的 pure composition seam；不改 host。
- 残留风险：本切片不承担 production repository/host 选择、数值与 RNG 所有权；
  这些继续由后续接线与既有 assembler 负责。
