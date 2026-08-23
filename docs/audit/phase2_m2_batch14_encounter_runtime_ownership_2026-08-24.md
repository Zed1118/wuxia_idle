# 二阶段 M2 Batch14 遭遇运行时所有权审计（2026-08-24）

## 基线与授权

- 基线：Batch13 READY `77c5520e04355e041a5db6b40dde05b169874117`。
- 用户已授权持续自动推进，并明确要求充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent。
- 本批不需要新的产品语义决策；production host、candidate/tuning、Profile 与真人试玩继续保持 Gate。

## 预检结论

- R11 现有 route/runtime mapper/roster mapper/mapping API 足够组合；builder 不复制 assembler/runtime 的 coverage/tick 校验，也不承诺 caller-owned 整个对象图深冻结。
- 原 R12 跨 tick lifecycle 方案过宽：当前 `Phase0aEvent` 缺 action completion/cancel/interrupt identity，`ActionTimeline` 无 production consumer，相关时间线与 token 配比仍为 tuning。Batch14 只做 R12a 纯不可变 lease prepared-successor；session 接线另立 R12b，真实 timeline 继续受 Gate 锁定。
- R13 defeat 投影只读取 `Phase0aEnemyDefeated` 的稳定标量；R09 frame 的 actor 嵌套容器已深冻，但通用 event payload 不是全类型深拷，故不宣称 external projector 看见的任意 payload 都深冻结。

## 风险控制

- 第二真相源：R11 不复制 assembler/runtime 校验，只证明组合与既有 fail-closed 委托。
- 隐式语义：R12a/R13 禁止按 actor ID、role、intent/event 类型、位置或缺席猜 token lifecycle/objective identity。
- 原子性：所有 lazy iterable 在发布前物化；prepared successor 未成功完成前不污染已发布 owner/snapshot。
- 集成职责：主控入口只消费 R11 plan 的 exact budgets/controller/mapping，显式构造现有 token gate 与 fresh objective tracker；R12a 不伪装成已接 session 的 production lifecycle。
- promotion 泄漏：owned files 不含 production data/host/GDD/CLAUDE/PROGRESS；批末再查 TUNE 状态。
- 可恢复性：四 worktree 从同一 READY 创建，来源小切片 commit，主控稳定 patch-id 集成并独立终审。

## 验证记录

### 已完成来源

- R11：计划 `9ecfff2f`、实现 `0e5fd536`、证据 `bc417989`，初始 READY 后发现恢复点措辞仍停在待 READY 的文档 P2；`ef098994` 修正并冻结新 READY `4d2c016a`。Qoder CLI 1.1.28 实际使用 `Qwen3.8-Max`、reasoning high 完成设计与最终 diff 审查，最终 PASS；83/83、scoped analyze 0，独立复审 P0/P1/P2=0。集成提交 `9545fc41` / `cf5465ed` / `16295176` / `d080b9cb`。
- R12a：计划 `d64a2065`、实现 `1f856e7b`、证据 `29079798`、READY `2e53aaf4`；16/16、scoped analyze 0、format/diff clean，独立复审 P0/P1/P2=0。集成提交 `45ca144d` / `a06a0875` / `149bf7a2`。合同明确为 immutable predecessor → prepared successor → 新 runtime；同一 predecessor 的 sibling successor 是 caller 显式 branch/fork，不虚称全局 CAS 或已接 production lifecycle。
- R13：计划 `e91e6afd`、红测 `a8f50fc1`、实现 `151a4df0`、证据 `6efc0f7f`，主控校正恢复点的测试算术后以新 READY `1efe8247` 冻结。Pi CLI 0.84.1 实际使用 `deepseek/deepseek-v4-flash`、thinking high 完成设计与最终 diff 只读审查；最终 PASS，P0/P1=0。主控按真实文件逐项复跑为 64/64（新 source 15、R09 flow 15、tracker 15、production objective integration 2、roster 8、objective primitive 9），scoped analyze 0，独立复审 P0/P1/P2=0。集成提交 `de4e8b83` / `67423a31` / `27751a6f` / `a9c7160c` / `138f6598`。

### 集成进行中

- 主控在 assembler 新增显式 `assembleMigratedEncounterPlan`，只消费 R11 plan 的 exact mapping、token budgets 与 objective controller；request mapper、objective source、numbers 与单一 RNG 仍由 caller 显式提供。R12a lease runtime 与 ActionTimeline 均未接入 session。
- 新 synthetic composition 测试 3/3 通过；R11/R12a/R13 去重联合回归 158/158 通过；变更 Dart 8 项 scoped analyze 0，format 与 `git diff --check` 通过。
- 待完成：source→integration stable patch-id、full suite、registry/YAML/Markdown/path/main refs 快速闸门、独立集成终审与 READY。
