# P2 M2 Batch17：听剑事务边界

## 目标

从 Batch16 READY `abefcee74a5b4749662a534a0793f995c2a2f891` 出发，继续闭合三个无需新产品决策的 host-neutral 合同：保存本次主线准入真正新增的听剑同伴并支持显式释放、阻止同一听剑同伴进入四类互斥活动、把 exact durable claim 观察值交给既有奖励政策决策。本批不实现持久 store/CAS/outbox、成长发放、production host 或 settlement 身份绑定。

## 并行与依赖

1. R19 / Pi + DeepSeek V4 Flash high：扩展 R18 admission provenance，并组合 R15 release prepared successor；caller 显式提供四种 frozen release reason。
2. R20 / Qoder CLI + exact Qwen3.8-Max high：建立 immutable occupancy snapshot 上的反向活动准入 guard；与 R19 owned files 不重叠，可并行。
3. R21 / Codex high + Pi 最终只读审查：依赖 R19 的 `admittedCompanion`，只完成 canonical claim key + exact durable observation → 既有 policy outcome。

## 硬边界

- 不从 settlement/result/exit 状态推断 release reason，不把 predecessor 里旧或 foreign occupancy 误作本次 admission provenance。
- 不扩 production `ActivityOccupancy`、Character/Isar/healing 查询或 shared registry。
- 不实现 claim ledger、schema、unique CAS、outbox、grant、rate/cap 或持久事务。
- settlement↔admission durable identity、release/grant/claim 原子边界、共享 occupancy 真相源继续架构 Gate。
- candidate/objective/timeline/tuning/Profile/G2/production host/真人验收继续 Gate。

## 验收

- 两个并行来源在独立 worktree 完成 TDD、精确外部模型审查、targeted/analyze/format/path/diff/status 验证与 READY。
- R19 集成后才创建 R21 来源恢复点；不得用文档依赖冒充代码依赖。
- 主控逐项核验 source→integration stable patch-id、actual diff、失败零发布、single-use/exact-predecessor、Gate 诚实性。
- 集成态运行联合 targeted、changed-Dart scoped analyze、format、YAML/diff/path/main refs、full suite 与独立终审；清零后只追加 Batch17 READY。

## 当前恢复点

- [x] Batch16 READY 已冻结，full 5035/5035、独立终审 P0/P1/P2=0，main/origin main 未修改。
- [x] Batch17 独立 integration worktree 已从 Batch16 READY 创建。
- [ ] 恢复 integration/source 环境并完成 R19/R20 并行来源。
- [ ] 集成 R19 后完成 R21 来源。
- [ ] 联合/full 验证、独立终审与 Batch17 READY。
