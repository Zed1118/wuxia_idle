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
- [x] integration 已完成 pub get、build_runner 126 outputs、63 个 `.g.dart` 与正确 dylib SHA 恢复；R19/R20 独立来源已并行派发。
- [x] R20 完成 Qoder 两轮只读审查、44/44、scoped analyze 0 与 Codex 终审，六个非空提交已按 stable patch-id 集成。
- [x] R19 完成 Pi 两轮只读审查、45/45、scoped analyze 0 与 Codex 终审，五个非空提交已按 stable patch-id 集成。
- [x] 完成 R19/R20 并行来源，并从 R19 集成 code tip 创建 R21 独立 worktree。
- [x] R21 完成 Pi 两轮只读审查、81/81、scoped analyze 0 与独立终审，四个非空提交已按 stable patch-id 集成。
- [x] 主控完成 15 个来源提交 stable patch-id 与 9 个 owned blob 核验；12-file path guard、`git diff --check`、clean status 与 main refs 均通过。
- [x] 集成态去重联合 targeted 125/125、changed-Dart scoped analyze 6 items / 0 issue、format 6 files / 0 changed、registry 91 tasks / 0 duplicate / 0 dangling、full 5079/5079 PASS。
- [x] 独立集成代码终审 P0/P1/P2=0，确认 R19/R20/R21 组合边界与全部 Gate 保持。
- [ ] 冻结最终 registry/audit、完成 docs-only 终审并追加 Batch17 READY。
