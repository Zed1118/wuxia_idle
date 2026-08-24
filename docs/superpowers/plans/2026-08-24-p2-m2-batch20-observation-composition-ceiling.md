# P2 M2 Batch20：观测能力与组合上限

## 目标

从 Batch19 READY `43209cb3a4d77c45eda0fdc6aebe57a1465d7e58` 出发，并行完成两个无需新产品决策且 owned files 不重叠的切片：窄 typed runtime observation snapshot，以及 Ch1 candidate 一拍 idle/no-mutation transactional composition matrix。本批不接 production host，不晋升 candidate，不伪造 defeat/checkpoint/anchor 或 lease lifecycle，不绑定 settlement 与 run identity。

## 并行任务

1. R27 / Pi + DeepSeek V4 Flash high：新增 immutable observation value/source，EncounterFlow 每次读取 fresh 容器，但成员保持 R25 exact identity；不改变 BattleFlow/assembler/advance。
2. V02B / Qoder CLI + exact Qwen3.8-Max high：把 V02A 95 条显式 declaration 机械搬入单一 test-support，以五关 R11→R22→R26 组合一拍 caller-declared drop-all/no-mutation flow，并读取 R25 progress/receipt。

## 硬边界

- R27 不增加 epoch/tick/revision、listener/stream/history/ledger/codec，不把 snapshot 冒充 durable event，也不暴露 owner/mutation capability。
- V02B 只执行一拍 idle/no-defeat；不声称 defeat 在 flow 内产生，不断言真实 spawn/combat event 数、伤害、性能或 balance。
- V02A 的 95/67/3/25 与独立 70-event expected 表必须回归；helper 不得从 ID/role/position/objectives 生成 declaration。
- settlement↔run authoritative identity、production host、candidate promotion、checkpoint/anchor、real lease lifecycle/budget policy、durable/tuning/Profile/G2/真人验收继续 Gate。

## 验收

- 两来源独立 worktree TDD，各经精确外部模型设计/终审、targeted/analyze/format/path/diff/status 后追加 READY。
- 主控复核 actual diff、stable patch-id、owned blobs、fresh/exact identity、failure zero-publication 与 Gate 诚实性。
- 集成态运行去重联合 targeted、changed-Dart scoped analyze、format、registry/diff/path/main refs、单次 full suite 与独立终审；清零后追加 Batch20 READY。

## 当前恢复点

- [x] Batch19 READY `43209cb3a4d77c45eda0fdc6aebe57a1465d7e58` 已冻结，full 5129/5129、独立终审 P0/P1/P2=0，main/origin main 未修改。
- [x] Batch20 两任务已由独立只读预检核验；没有第三条不跨 Gate 且非重复的切片。
- [ ] Batch20 integration/source worktree 环境恢复、两来源并行实现与来源 READY。
- [ ] 联合/full 验证、独立终审与 Batch20 READY。
