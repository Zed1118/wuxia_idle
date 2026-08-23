# P2 M2 Batch16：事务化宿主就绪接缝

## 目标

从 Batch15 READY `cf6a4ab61c06e3141658b37473cfa23b838342db` 出发，先精确重放已完成终审的 R12b session-owned attack-token lease 事务接缝，再并行补齐三个互不重叠、无需新产品决策的 host-neutral 结构合同：assembler 显式 lease pair 透传、migrated encounter 结算适配、主线首通准入与单关听剑占用的 prepared admission。本批不切 production host，不晋升 candidate，不冻结 ActionTimeline 或任何 tuning，不执行 Profile/G2/真人验收。

## 共同恢复点

- R12b 来源 READY：`72e274aa8156cf5adbe5e2f9b7c0290fe433f265`；89/89 targeted、4969/4969 full、scoped analyze 0、Qoder 与 Codex 终审 P0/P1/P2=0。
- 五个 R12b 非空提交已重放为 `2d7e21b6` / `ed12bcca` / `04a4d637` / `ff1d89f6` / `a9522747`，stable patch-id 逐项一致。
- R12c 以来源 R12b READY 为基线独立实现；R17/R18 以 Batch16 的 `a9522747` host-neutral code base 为共同基线，三项 owned files 不重叠。

## 并行任务

1. R12c / Pi + DeepSeek V4 Flash high：只给 `assembleEncounter` 与 `assembleEncounterFromMapping` 增加 nullable lease gate/runtime pair 原样透传；不提供默认、不修改 migrated stateless gate。
2. R17 / Pi + DeepSeek V4 Flash high：让 `Phase0aSettlementAdapter` 消费显式 `Phase0aEncounterMapping`，与旧 mapping 入口共用一份私有 settlement core，证明逐字段等价。
3. R18 / Qoder CLI + exact Qwen3.8-Max high：组合 R14 admission 与 R15 owner-bound occupancy prepared successor，只覆盖显式 first-clear request 和同 stage choice，不宣称 durable transaction。

## 硬边界

- R12c 不接 `assembleMigratedEncounterPlan`、production host、ActionTimeline、action/lease ID 或 completion/cancel/interrupt/release 推断。
- R17 不决定 route/objective/reward/injury，不接 save/repository/host/data/candidate/tuning。
- R18 不查掌门、空闲、活动、伤势、门人关系或存档，不实现 claim/grant/rate/cap/persistence/UI。
- candidate fixture 晋升、真实 objective payload、production host route、timeline 生命周期、敌量/令牌/听剑 tuning、durable outbox/claim、Profile/Windows/真人验收继续 Gate。

## 验收

- 来源必须按共同基线、owned files 与中文动宾小提交完成 TDD；Pi/Qoder 记录精确版本、模型、thinking/reasoning 与只读设计/最终 diff 审查。
- 主控逐项核验 actual diff、stable patch-id、失败零发布、旧路径等价与 Gate 诚实性。
- 集成态运行去重联合 targeted、changed-Dart scoped analyze、format、YAML/diff/path/main refs、full suite 与独立终审；P0/P1/P2 清零后只追加“结构接缝”READY。

## 当前恢复点

- [x] Batch15 READY 已冻结，main/origin main 未修改。
- [x] R12b 五个非空提交已按 stable patch-id 重放到 Batch16，主控复跑 89/89。
- [x] 登记 R12b/R12c/R17/R18 与 Batch16 的依赖、owned files 和 Gate。
- [x] Batch16 integration 恢复 126 build outputs、63 个 `.g.dart` 与正确 dylib SHA。
- [ ] 三来源完成外部工具证据、测试、独立复审与 READY。
- [ ] 主控集成、联合/full 验证、终审与 Batch16 READY。
