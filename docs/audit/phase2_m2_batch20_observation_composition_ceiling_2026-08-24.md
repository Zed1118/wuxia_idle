# 二阶段 M2 Batch20 观测能力与组合上限审计（2026-08-24）

## 基线与授权

- 集成基线：Batch19 READY `43209cb3a4d77c45eda0fdc6aebe57a1465d7e58`。
- 用户已授权持续自动推进并充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 host-neutral observation 与 candidate-only 验证。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- R25 已有两个 direct getter，R26 已返回 concrete flow；再包 advance/state/outcome facade 是重复。R27 只需定义 immutable value + narrow source，使调用者依赖只读 capability。
- V02A 的 95 条 declaration 可机械搬入 test-support，供 V02A/V02B 复用；V02B 可在不新增 production API 的前提下证明 R22 source、R26 assembler、R25 observations 组合成立。
- R17 settlement snapshot 没有 run/stage/admission/session identity；R19/R23 继续组合会允许另一场 battle 的结果驱动当前 admission，因此 mainline 后续暂缓而不是伪造 guard。

## 风险控制

- snapshot 过报：R27 fresh container 不代表新提交；不得添加共同 tick/revision/transaction identity。
- helper fake-green：95 条 declaration 原样硬编码，V02A 独立 70-event expected 表继续保留，不从 fixture objective 或字符串生成。
- idle 过报：V02B caller gate 只返回 drop-all intents 与 empty mutations；一拍 receipt 只证明显式组合/观测，不证明 defeat/lifecycle/budget policy。
- failure 诚实性：只保证 flow-owned state/progress/receipt 不发布失败候选，不承诺 caller RNG/planner/source 等外部副作用回滚。
- production/candidate promotion/checkpoint-anchor/settlement identity/durable/tuning/Profile/G2/真人验收继续 Gate。

## 来源实现与审查

### R27 遭遇运行时观测快照

- source READY：`78c5d6b82e4bc8bcbffce9c9d1b017a4ca06809a`；实现提交 `3bc33cb1`。
- 7 个非空 source commits 已逐一集成为 `0f7edc3a`、`bfb0ea41`、`3392bac6`、`35217a1b`、`dc485629`、`2919b6b3`、`c5cb8fbf`。
- 只改 5 个 owned paths；targeted 83/83、4 changed Dart analyze 0、format 0、path/diff/status guards 通过。
- Pi + DeepSeek V4 Flash 设计审查返回 DESIGN PASS。最终 actual-diff 完整 prompt 与精简重试均在约 5 分钟内零输出并有界退出，故没有 Pi final PASS；Codex 独立替代终审复跑 39/39 并检查 actual diff，P0/P1/P2=0。
- 实现只新增 immutable `Phase0aEncounterRuntimeObservation` 与窄 source；每读 fresh 容器，nullable members 保持 R25 getter 的 exact identity；未改 BattleFlow、assembler、advance 或任何 Gate。

### V02B 候选可观测事务组合矩阵

- source READY：`fc41e42bd2e039ba334789fc60dc13cf7bc724c0`；实现提交 `d441f6d7`。
- 5 个非空 source commits 已逐一集成为 `ab27791a`、`ad7a254c`、`9555d5d3`、`716fd237`、`a5f85e9e`。
- 只改 4 个 owned paths；targeted 116/116、3 changed Dart analyze 0、format 0、path/diff/status guards 通过。
- Qoder CLI 1.1.28、exact Qwen3.8-Max、reasoning high、Read/Grep/Glob-only：设计阶段完整与精简 prompt 各约 5 分钟零输出并有界退出；最终 actual-diff 审查约 152 秒返回 PASS，P0/P1/P2=0。
- V02A 的 95 条 declaration（67 Target / 3 Commander / 25 empty）机械搬入 test-support，70 条独立 expected events 留在 V02A；五关各只做一个 caller-declared idle/drop-all/no-mutation tick，不声称 defeat/lifecycle/host/promotion。

## 集成验证

- source→integration stable patch-id：12/12 精确一致；9 个来源 owned files 的 tip blobs：9/9 精确一致。
- 相对 Batch19 READY 精确 12 个 changed paths：3 个 Batch20 登记/计划/审计文档、5 个 R27 owned paths、4 个 V02B owned paths；两来源 owned files 不重叠。
- 去重联合 targeted：14 个文件，160/160。
- 7 个 changed Dart items：`flutter analyze --no-pub` 0 issue；`dart format --output=none --set-exit-if-changed` 0 changed。
- 单次 full suite：5153/5153；相对 Batch19 的 5129 项新增 24 项。
- `git diff --check` 通过；registry 102 tasks / 0 duplicate ids / 0 dangling prerequisites。
- 集成终审前 `main` 与 `origin/main` 均保持 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。

## 独立集成终审与冻结结论

- 独立只读 Agent 以 validation `c3eeea62ae809f1bedb5d2c882e402816f4684b1` 审查 actual diff，结论 PASS，P0/P1/P2=0；未重复 full suite。
- reviewer 独立重算：12/12 stable patch-id、9/9 non-empty blob SHA、精确 12 paths、owned overlap 0、registry 102/0/0、`git diff --check` clean、worktree clean、main/origin main refs 未变。
- R27 仅提供 fresh typed container 与 exact member identity；V02B 仅证明 candidate-only idle transactional composition；所有声明与 Gate 和 source 计划一致。
- validation commit：`c3eeea62ae809f1bedb5d2c882e402816f4684b1`。
- READY marker：`[READY][CODEX][P2-M2-BATCH20] 冻结观测能力与组合上限`。

## 残留 Gate

- production host/route、candidate promotion、checkpoint/anchor authoritative projectors。
- 真实 action/lease lifecycle 与 budget policy、defeat-in-flow、完整 simulation/balance/performance。
- settlement↔run/stage/admission/session authoritative identity。
- durable store/schema/CAS/outbox、tuning/YAML/Profile/G2/真人验收。

Batch20 在不跨越上述 Gate 的前提下达到可恢复 READY 条件；后续不存在经独立盘点确认的第三条 genuine gate-free M2 实现切片，故不自动创建 Batch21。

## 集成环境恢复点

- Batch20 integration 已执行 `flutter pub get`；依赖解析成功，未改动受版本控制文件。
- build_runner 成功写入 126 个生成输出，其中 `.g.dart` 共 63 个；生成后工作树保持 clean。
- 从 Batch19 READY worktree 恢复 ignored `libisar.dylib`，SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；不进入提交。
- R27/V02B source worktree 均从登记提交 `44032d62021504541a70fe2fe13064f779231783` 创建，owned files 互不重叠并已并行派发。
