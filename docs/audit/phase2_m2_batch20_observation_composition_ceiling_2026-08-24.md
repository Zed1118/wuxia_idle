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

## 待完成验证

待两来源 READY 后补充外部模型证据、来源/集成提交、targeted/analyze/format/full、仓库闸门、独立终审与最终 READY。

## 集成环境恢复点

- Batch20 integration 已执行 `flutter pub get`；依赖解析成功，未改动受版本控制文件。
- build_runner 成功写入 126 个生成输出，其中 `.g.dart` 共 63 个；生成后工作树保持 clean。
- 从 Batch19 READY worktree 恢复 ignored `libisar.dylib`，SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；不进入提交。
- R27/V02B source worktree 均从登记提交 `44032d62021504541a70fe2fe13064f779231783` 创建，owned files 互不重叠并已并行派发。
