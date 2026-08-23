# 二阶段 M2 Batch18 显式运行时延续边界审计（2026-08-24）

## 基线与授权

- 集成基线：Batch17 READY `87ee892189dd1c4c1d131e4a06df649f34328769`。
- 用户已授权持续自动推进并充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 frozen host-neutral 合同。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- R13 已能消费 caller 明示的 per-actor defeat payload，但缺少 encounter entry→R07 actor 的显式映射与当前 objective Target/Commander typed coverage 闭合；R22 可做纯 data-validation bridge。
- R19 已冻结本关 release，R01 已冻结 next-stage run transition，R15 已冻结单关 optional occupancy；R23 可组合下一关 prepared admission，但不能冒充 host 或 durable coordinator。
- R12b 只在全部 throwable work 成功后提交 lease runtime；R24 可发布同批 immutable receipt 供 caller 验证，但不能推断 ActionTimeline 生命周期。

## 风险控制

- projection 推断：R22 只搬运 caller 构造的既有 typed payload，并经 `bindingByEntryId` exact mapping；严禁 ID 同名、role、position 或 defeat kind 推断。
- objective 过报：R22 只扫描 Target/Commander defeat refs；Ch1 checkpoint/anchor 仍不 executable，candidate 仍非 production。
- 下一关原子性过报：R23 只承诺 owner-bound in-memory prepared commit；settlement/session/durable identity 继续 Gate。
- receipt 过报：R24 receipt 只观察 caller-declared mutations 与 committed snapshots；不生成 action fact，不代表持久日志或 exactly-once。
- production/candidate/tuning/Profile/G2/真人验收继续 Gate。

## 待完成验证

待来源 READY 后补充外部工具证据、来源/集成提交、targeted/analyze/format/full、仓库闸门、独立终审与最终 READY。

## 集成环境恢复点

- Batch18 integration 已执行 `flutter pub get`；依赖解析成功，未改动受版本控制文件。
- build_runner 成功写入 126 个生成输出，其中当前 `.g.dart` 共 63 个；生成后 `git status --short` 为空。
- 从 Batch17 READY worktree 恢复未跟踪的 `libisar.dylib`，SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；该运行库不进入提交。
