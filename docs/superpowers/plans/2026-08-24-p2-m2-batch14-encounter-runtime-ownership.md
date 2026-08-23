# P2 M2 Batch14：遭遇运行时所有权接缝

## 目标

从 Batch13 READY `77c5520e` 出发，并行完成 migrated route 到 fresh runtime plan 的显式组合、攻击 token lease 的纯不可变 prepared-successor 合同，以及 roster 驱动的显式 objective defeat 投影源。Batch14 不切 production host，不接未冻结 ActionTimeline，不晋升 candidate/tuning。

## 并行任务

1. R11 / Qoder CLI + Qwen3.8-Max high：组合 migrated route → runtime contract bundle → same-director roster → encounter mapping；只创建 fresh owner，不复制 assembler/runtime 的校验真相源。
2. R12a / Codex high：建立显式 lease/action identity、不可变 snapshot、acquire/release mutation 与 owner-bound prepared successor；不接 session、event 推断或 timeline。
3. R13 / Pi + DeepSeek V4 Flash high：按 exact roster actor coverage 显式声明 target/commander defeat projection；其余六类 objective 事件只能由 caller projector 提供。

## 冻结合同

- R11 的具体参数类型在编译期排除 legacy；resolver 与 actor factory 按 content order 精确一次，roster 使用 bundle 的同一 director。builder-created bundle/director/controller/roster/mapping 为 fresh owner；caller 的 arena、adapter 与 actor factory 返回值仍由 caller 负责。coverage、player adapter、move binding、tick 与 active-enemy 校验继续委托既有 assembler/runtime，禁止复制。
- R12a 的 lease ID、token kind、priority 与安全事实全部由 caller 显式提供；不得从 actor ID、intent、role、hit、cooldown、defeat 或位置推断 acquire/release。prepare/finalize/commit 任一失败不得改变已发布 snapshot；真实跨 tick timeline 与 session 接线另立 R12b。
- R13 constructor 要求 projection map key set 与 roster runtime actor ID 完全一致，空 list 是显式 no-op；defeat 按 combat event 顺序、单 actor declaration 顺序生成稳定 event ID，随后才按 external projector 声明/yield 顺序追加六类事件。external projector 不得绕过 coverage 生成 TargetDefeated/CommanderDefeated。
- 三项均不得修改 production YAML/data、host/stage route、UI/save/reward/injury、玩法数值、candidate fixture 或 tuning 状态。

## 集成与验收

- 每项在独立 branch/worktree 小切片实现，来源提交与空 READY marker 可恢复；R11/R13 必须记录实际外部 CLI/model 与审查证据。
- 主控逐项核对 actual diff、source→integration stable patch-id、中文动宾提交、owned files 与生产隔离。
- 来源 READY 后由主控在 assembler 新增显式 `assembleMigratedEncounterPlan`：只从 plan 取 exact mapping、attack-token budgets 与 objective controller，构造 stateless enforcing gate 与 fresh objective tracker；token request mapper、objective event source、numbers 和单一 RNG 仍由 caller 必填。R12a 不在此伪接 session，留给后续 R12b。
- 新增 `phase0a_migrated_encounter_composition_test.dart`，用 synthetic encounter 同时证明 typed plan、same-director roster、token 稳定子序列、objective 唯一胜利源、单 RNG stream 与既有 fail-closed/回滚；legacy 入口保持不变。
- 集成态只组合显式 opt-in seam，不构造 host/default。执行联合 targeted、变更 Dart analyze、format、YAML/Markdown/diff/path 检查、full Flutter test 与独立终审；P0/P1/P2 清零后追加 Batch14 READY。

## 当前恢复点

- [x] Batch13 READY `77c5520e` 冻结，main/origin main 保持 `e292d3a0`。
- [x] 完成 R11/R12a/R13 只读 API 预检并收窄高风险语义。
- [x] 创建三实现 worktree 与一集成 worktree。
- [x] 登记任务；四 worktree 完成 pub get、build_runner 126 outputs、63 个 `.g.dart` 与 dylib SHA 对齐。
- [x] 并行派发并完成 R11 / R12a / R13 来源实现、主控复核与 READY。
- [x] 主控组合显式 migrated plan 入口；3/3 新测试、158/158 去重联合回归、8 项 scoped analyze、format/diff 闸门通过。
- [x] full 4954/4954、12 组稳定 patch-id、仓库快速闸门与独立终审 P0/P1/P2=0。
- [ ] 写入最终 validated commit 并追加 Batch14 READY。
