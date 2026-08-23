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

- [ ] 生产接线证据：两个真实 production encounter assembler 入口都原样透传给 Session；host 激活继续 Gate。
- [ ] targeted tests：新测试、R12a/R12b、production assembler/token/objective/mapping/migrated 影响集全绿，记录真实通过数。
- [ ] 红线：零数值/公式/YAML/玩家文案/奖励/存档/UI 变更，不触三系、在线=离线或反主流清单。
- [ ] 残留风险：full lifecycle/migrated/host 路径必须另立 Gate 冻结 action identity 与 completion/cancel/interrupt/fail 释放语义。
- [ ] 非 UI 任务，不需视口验收；无 debug 日志、临时资产、生成件或 dylib 误提交。
- [ ] scoped analyze、format、`git diff --check`、owned-path/status 全绿，tip 为精确 `[READY][PI][P2-M2-R12C]`。

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

- 待实现与 targeted 验证后补充真实命令和结论。

## 当前恢复点

- 状态：计划与 TDD 红测已提交，生产实现尚未修改。
- 最后完成：计划提交 `a306bd67`；新测试提交 `a6d1296d`，覆盖 direct/mapping identity、成对/互斥、RNG、no-op 回放、planner/runtime/observer/reducer/objective 原子性及 source guard。fresh worktree 环境仍为 build_runner 126 outputs、63 个 `.g.dart`、dylib SHA-256 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- 下一步：最小修改 production assembler 的两个入口并复跑新测试。
- 已跑验证：`flutter test --no-pub test/features/battle/application/phase0a/phase0a_production_attack_token_lease_wiring_test.dart` 按预期红，唯一根因为两个 assembler 方法均缺 `attackTokenLeaseBatchGate` / `attackTokenLeaseRuntime` 命名参数；Pi 编码前只读审查 PASS。按单 feature 任务节奏不跑 full。
- 阻塞项：无。action completion/cancel/interrupt/timeline 和 production host 依然是未冻结 Gate，不影响本 host-neutral seam。

## READY

最终空提交固定为：`[READY][PI][P2-M2-R12C] 建立攻击令牌租约装配透传接缝`。
