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
- [x] Batch20 integration 已完成 `flutter pub get`、build_runner 126 outputs（63 个 `.g.dart`）与 `libisar.dylib` 恢复；两 source worktree 已从登记提交 `44032d62` 创建并派发。
- [x] R27 source READY `78c5d6b82e4bc8bcbffce9c9d1b017a4ca06809a`：83/83、analyze 0、format 0、Codex 替代终审 P0/P1/P2=0；Pi 设计审查通过，但最终审查两次有界 5 分钟无输出，未伪造 Pi final PASS。
- [x] V02B source READY `fc41e42bd2e039ba334789fc60dc13cf7bc724c0`：116/116、analyze 0、format 0；Qoder 设计阶段两次有界 5 分钟无输出，最终 actual-diff 审查由 exact Qwen3.8-Max high 返回 PASS，P0/P1/P2=0。
- [x] 12/12 source→integration stable patch-id、9/9 owned blobs、精确 12 paths；联合 targeted 160/160、7 changed Dart analyze 0、format 0、full 5153/5153，registry 102/0/0，main/origin main 未修改。
- [ ] 独立集成终审、docs-only closure 与 Batch20 READY。
