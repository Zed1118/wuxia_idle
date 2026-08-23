# P2 G2 第一批生产接线

## 目标

从 Batch2 READY `56450ba3` 开始，只接入已经能证明与现有 Ch1 行为等价、且不需要 tuning/PROPOSED 决策的 M1 合同。禁止用 no-op adapter 冒充生产完成，也禁止为追求任务数把纯候选同时接入 reducer 造成双结算。

## 本批执行

1. C02：现有 Phase0A 单目标 strike selection 改用 C02 `ForwardFanScope` 或最薄 typed adapter；保留单目标、距离/ID、guardian 与零朝向兼容语义。
2. C10：新增现有 `Phase0aEvent` 到 `CombatEventRecord` 的只读、全类型、确定性投影；不改变 reducer、sequencer、VFX。

## 审计后阻塞

- C03：`firstEffect` 与现有同拍伤害可能双结算，且 tick/seconds 转换未冻结；只读表现 feed 不是生产结算接线。
- C05/C06/C16：生产无 posture/status/defense 公共运行态；shield-only counter、`DefenseBranch.hit` 与 counter event 落点未决，禁止直改 reducer。
- C07：缺 action identity/lifecycle，reservation/commit 无法安全接入。
- C08：缺 canonical weapon/effect registry 与连段运行态；直接接会改变已验收普攻节奏。
- C09：modifier 字段消费归属和 recovery 方向未冻结。
- C13B：主线/塔/扫荡无 sessionId，规则表/持久 ledger/dangerTier 数据源均未拍板；远征/断魂庄已有独立持久幂等，不能叠第三套 ledger。
- C14B：gauntlet 已在单事务内用 run 删除防重；当前 API 重入时已无 runId，临时内存 guard 既不能持久防重也无法构造旧 claim key，拒绝冗余接线。

## 验证

- 每条切片先证红、targeted、analyze、diff-check。
- 集成后重跑 reducer、Ch1 mapper/headless、mainline wiring、event sequencer/VFX 受影响集合。
- 补根包生成物与 probe 子包依赖后跑全仓 `flutter analyze --no-pub`。
- 外部模型交叉审查只作为问题来源，Codex 主窗口复核后才合并。
