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

## 已完成来源

- R22：计划 `88b11641`、红测 `670b4999`、实现 `079d073d`、analyze 收口 `f74ab37e`、sealed/wrong-kind 加固 `5151a900`、证据 `29d2999b`，来源 READY `2b644cbe57a73b838edbc439fe839917008ebe7d`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking high，只读设计/终审，最终 P0/P1/P2=0；targeted 58/58、scoped analyze 2 items / 0 issue、format/path/diff/status clean。六个集成提交 `4300d7f5` / `654b3b70` / `e8a1bd3f` / `4a09e14c` / `d80b8fc8` / `9de58481` 的 stable patch-id 与来源逐项一致，3/3 owned blobs 一致。
- R23：计划 `e723bbc6`、红测 `70f7613c`、实现 `4ee7f253`、本地验证 `c8b5418d`、主控 finding 修复 `1febfa98`、有效终审 `7bfb0122`，来源 READY `efe1f45aa01b82d0ea8c91625678b4587f9f26a0`。Qoder CLI 1.1.28 使用精确 selector `Qwen3.8-Max`、reasoning high、Read/Grep/Glob-only；首次 PASS 因主控发现“非成功结算也可 release”而作废，修复后有效终审 P0/P1/P2=0；targeted 59/59、scoped analyze 2 items / 0 issue、format/path/diff/status clean。六个集成提交 `660eea62` / `5aeeb3d6` / `16123fab` / `b1704ec2` / `752a819e` / `a4ba9833` 的 stable patch-id 与来源逐项一致，3/3 owned blobs 一致。
- R24：计划 `f630fd8a`、红测 `a79e6c7e`、实现 `eb139b6d`、matcher/source guard 加固 `c4674294`、证据 `fa7fe3cd`，来源 READY `cbc2b4ec2fa48f59de74ca119e2900046f59dc46`。Pi 精确 `deepseek/deepseek-v4-flash` high 设计首轮超时后只读重试通过；最终原始 0/0/5 findings 全部修复或经主控归类关闭，有效终审 P0/P1/P2=0；targeted 66/66、scoped analyze 3 items / 0 issue、format/path/diff/status clean。五个集成提交 `0c6b05fa` / `b0d7ea4b` / `293bd586` / `ef8e1ef0` / `245af125` 的 stable patch-id 与来源逐项一致，4/4 owned blobs 一致。

## 集成验证

- 主控逐项重算 R22/R23/R24 共 17 个 source→integration stable patch-id 与 10 个 owned blobs，全部与来源 READY tip 一致。
- 影响集去重联合 targeted 184/184 PASS；changed-Dart scoped analyze 7 items / 0 issue；format 7 files / 0 changed。
- `flutter test --no-pub --reporter compact` 从 clean integration 起点单次完成 5102/5102 PASS；未并行启动第二个 full 进程。
- 相对 Batch17 精确 13-file path guard、`git diff --check` 与 clean status 通过；main 与 origin/main 仍均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。
- registry 结构与独立集成终审将在本验证提交后复核，清零后再追加 READY marker。

## 最终结论（待独立终审）

- Batch18 只冻结 host-neutral 的显式 defeat objective 投影、成功结算后的 next-stage runtime admission 与 lease batch receipt；不宣称 production host、candidate promotion、checkpoint/anchor projector、timeline 推断、durable store/schema/CAS/outbox、tuning/Profile/G2/真人验收已完成。
- 独立终审与 registry/docs 闭环复核通过后才追加空 READY marker。

## 集成环境恢复点

- Batch18 integration 已执行 `flutter pub get`；依赖解析成功，未改动受版本控制文件。
- build_runner 成功写入 126 个生成输出，其中当前 `.g.dart` 共 63 个；生成后 `git status --short` 为空。
- 从 Batch17 READY worktree 恢复未跟踪的 `libisar.dylib`，SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；该运行库不进入提交。
