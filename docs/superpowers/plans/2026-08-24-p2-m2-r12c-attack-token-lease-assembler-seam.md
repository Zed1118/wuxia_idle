# P2-M2-R12C：攻击令牌租约装配透传接缝

## 目标与边界

- 分支：`codex/phase2-m2-r12c-attack-token-lease-assembler-seam-20260824`
- 精确基线：R12b READY `72e274aa8156cf5adbe5e2f9b7c0290fe433f265`
- 目标：让 caller 能通过 production encounter assembler 的直接入口与 mapping bridge，显式成对传入 R12b 的 transactional attack-token lease gate/runtime。
- 生产入口：`Phase0aProductionFlowAssembler.assembleEncounter` 与 `assembleEncounterFromMapping`；消费方仍是 `Phase0aCombatSession`。

本切片只是 host-neutral assembler seam：不默认构造 gate/runtime/planner，不复制 Session 的成对与互斥校验，不修改 wave `assemble`、`assembleMigratedEncounterPlan` 或旧 stateless token gate，不接 host/data/repository/save/UI/candidate/tuning/Profile/G2/真人验收，不引入 `ActionTimeline` 或推断 action/lease 生命周期。

## Owned files

1. `lib/features/battle/application/phase0a/phase0a_production_flow_assembler.dart`
2. `test/features/battle/application/phase0a/phase0a_production_attack_token_lease_wiring_test.dart`
3. `docs/superpowers/plans/2026-08-24-p2-m2-r12c-attack-token-lease-assembler-seam.md`

## 冻结 API

`assembleEncounter` 与 `assembleEncounterFromMapping` 各增加：

```dart
Phase0aAttackTokenLeaseBatchGate? attackTokenLeaseBatchGate,
AttackTokenLeaseRuntime? attackTokenLeaseRuntime,
```

参数原样透传给 `Phase0aCombatSession`。Session 继续独占以下不变式：gate/runtime 必须成对；transactional gate 与 `enemyIntentBatchGate` 互斥；prepared successor 只在 planner、observer、reducer 及 commit 全部成功后发布。Assembler 不提前复制这些校验。

## TDD 验收

1. direct `assembleEncounter` 传入精确 gate/runtime；通过记录 gate 的 runtime identity 与 planner snapshot revision 证明透传。
2. `assembleEncounterFromMapping` 保留 gate/runtime identity，并能完成显式 acquire。
3. gate-only、runtime-only 和 stateless + transactional 互斥均由 Session fail closed，且 caller RNG 未消费。
4. 空 mutations 返回 exact predecessor，snapshot revision 不增加。
5. planner lazy throw、observer throw、reducer throw 与 objective source throw 均不发布 arena/lease；assembler 层 reducer throw 用非法 `deltaSeconds` 触发，不注入假 production resolver。
6. objective 后置失败后重试仍从同一 predecessor 开始，成功时只提交一次。
7. no-op lease planner 与 null lease 路径在同 seed 下 events/state/outcome/RNG 后续值等价。
8. 旧 stateless 与 migrated plan 路径回归不变。
9. source guard 禁止 assembler 默认构造 runtime/gate，禁止 `ActionTimeline`、host/data/candidate/tuning 和 hit/defeat/cooldown/missing-intent/role 生命周期推断；禁止修改 `assembleMigratedEncounterPlan` 的 stateless gate 语义。
10. 测试基建复用 production assembler 现有 `loadTestGameRepository` / `resetForTest` 体例，不绕过 production snapshot factory。

## CLAUDE.md §8.2 验收清单

- [x] 生产接线证据：两个真实 production encounter assembler 入口都原样透传给 Session；host 激活继续 Gate。
- [x] targeted tests：新测试、R12a/R12b、production assembler/token/objective/mapping/migrated 八文件逐个复跑 89/89 PASS。
- [x] 红线：零数值/公式/YAML/玩家文案/奖励/存档/UI 变更，不触三系、在线=离线或反主流清单。
- [x] 残留风险：full lifecycle/migrated/host 路径必须另立 Gate 冻结 action identity 与 completion/cancel/interrupt/fail 释放语义。
- [x] 非 UI 任务，不需视口验收；无 debug 日志、临时资产、生成件或 dylib 误提交。
- [x] scoped analyze、format、`git diff --check`、owned-path/status 全绿；精确 READY 由本证据提交后的空提交追加。

## 任务切片

1. 恢复 fresh worktree 依赖、生成件与 `libisar.dylib`，完成 Pi 编码前只读设计审查。
2. 编写专用 production assembler 红测并提交稳定恢复点。
3. 最小修改 assembler，原样透传 gate/runtime，跑 targeted 与 scoped analyze。
4. Pi 对实际 diff 做最终只读审查，triage 后修复真问题。
5. 同步恢复点、提交证据，追加精确 READY 空提交。

## Pi 审查证据

### 编码前设计审查

- 版本：Pi CLI `0.84.1`
- 模型：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 命令摘要：`pi --no-session --model deepseek/deepseek-v4-flash --thinking high --tools read,grep,find,ls --print <R12C 只读设计审查 prompt>`
- 权限：仅 `read,grep,find,ls`，无 bash/edit/write。
- 结论：`PASS`，P0=0、P1=0。
- 采纳的 P2：用 gate/planner 侧记录观察 identity/revision；用非法 `deltaSeconds` 触发 reducer 失败；拒绝路径钉住 RNG 未消费；增加 no-op/null 同 seed 回放等价；注释记录 host/migrated 不对称边界。
- 保留边界：Pi 确认 full migrated/host lifecycle 仍需另行决策，本切片不扩范围。

### 最终 diff 审查

- 版本：Pi CLI `0.84.1`
- 模型：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 命令摘要：用 `git diff --no-ext-diff --unified=80 72e274aa...HEAD -- <3 owned files>` 物化实际 diff，再调用 `pi --no-session --model deepseek/deepseek-v4-flash --thinking high --tools read,grep,find,ls --print <最终审查 prompt + ACTUAL DIFF>`。
- 权限：Pi 仅 `read,grep,find,ls`，无 bash/edit/write；diff 由 Codex 在调用前只读生成并嵌入 prompt，未包含密钥。
- 结论：`PASS`，P0=0、P1=0。Pi 确认正确性、Session 原子发布、拒绝路径 RNG 零消费、outer-flow rollback、production-path 防假绿与 owned boundary 均成立。
- P2 triage：采纳计划证据收尾；source guard 除 `AttackTokenLeaseRuntime.empty(` 外再禁止 `AttackTokenLeaseRuntime.restore(` 默认构造绕行。记录性项保留诚实边界：objective 等后置失败可回滚 flow/session 自有状态，但不承诺回卷 caller-owned RNG 或外部副作用。

## 当前恢复点

- 状态：实现、TDD、影响验证与两轮 Pi 只读审查均完成，待提交收尾证据并追加 READY。
- 最后完成：计划 `a306bd67`；TDD 红测 `a6d1296d`；红测恢复点 `16cc71ac`；最小 production assembler 透传实现 `e6ddf3b7`。Pi 最终审查 PASS 后已收口计划漂移与 `restore` 工厂 source guard P2。fresh worktree 环境为 build_runner 126 outputs、63 个 `.g.dart`，dylib SHA-256 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- 下一步：提交本收尾证据，复核 clean worktree/owned paths/tip，然后追加精确 READY 空提交并交回主控。
- 已跑验证：新测试先因两入口缺冻结命名参数编译红，实现后 10/10 PASS；逐文件影响集为新测试 10、R12b session 15、R12a runtime 16、旧 production token gate 5、production assembler 23、mapping 15、objective integration 2、migrated composition 3，合计 89/89 PASS。Pi P2 source guard 加固后新测试再跑 10/10 PASS；scoped `dart analyze` 5 items 0 issue；format 0 changed，`git diff --check` 与 owned-path 守卫通过。按 CLAUDE.md §8.0 单 feature 节奏不跑 full。
- 阻塞项：无。action completion/cancel/interrupt/timeline 和 production host 依然是未冻结 Gate，不影响本 host-neutral seam。

## READY

最终空提交固定为：`[READY][PI][P2-M2-R12C] 建立攻击令牌租约装配透传接缝`。
