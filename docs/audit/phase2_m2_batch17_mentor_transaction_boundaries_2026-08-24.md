# 二阶段 M2 Batch17 听剑事务边界审计（2026-08-24）

## 基线与授权

- 集成基线：Batch16 READY `abefcee74a5b4749662a534a0793f995c2a2f891`。
- 用户已授权持续自动推进、充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 frozen host-neutral 合同。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- R18 没有保存“本次 admission 真正新增的 companion”；empty choice 叠加旧 occupancy 时若下游直接读 snapshot，可能误 release 或误 claim。R19 必须显式保存 nullable provenance。
- R15 已冻结四种 release reason 与 owner-bound prepared successor；R19 可机械组合，但不能推断结算事实或宣称 durable transaction。
- R02/R15 已冻结听剑同伴与四类阻塞活动；R20 只需对 immutable occupancy snapshot 做 exact-character 反向 guard。
- 既有 mentor claim policy 与 canonical `RewardClaimKey` 足以支撑 R21 的“观察事实→决策”边界，但 durable truth source、CAS、grant/outbox 尚未冻结。

## 风险控制

- provenance 漂移：empty choice 的 `admittedCompanion` 必须恒为 null，即使 predecessor 已占用；非空只取本次 R15 exact successor。
- composite commit 绕过：R19 的 committable R15 successor 必须 private，只暴露 read-only views，并保持 exact-predecessor/single-use。
- 活动真相过报：R20 不查实际活动状态、不修改 shared occupancy，只拒绝 exact active companion 的四种请求。
- durable 过报：R21 不查询或写入 durable store；成功场景只接受 caller 提供的 exact-key observation，错误或缺失 fail closed。
- production/candidate/objective/timeline/tuning/Profile/G2/真人验收继续 Gate。

## 待完成验证

待来源 READY 后补充外部工具证据、来源/集成提交、targeted/analyze/format/full、仓库闸门、独立终审与最终 READY。

## 环境恢复点

- Batch17 integration 完成 lockfile pub get、build_runner 126 outputs、63 个 `.g.dart` 与根目录 `libisar.dylib` 恢复；dylib SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- R19/R20 worktree 均从登记提交 `88e1413486889a0b98d027bd56f56b7ba51cbc5d` 创建并并行派发；两个来源 owned files 不重叠。

## 已完成来源

- R21：计划 `67b382e3`、红测 `6773f630`、实现 `57222498`、验收 `a47a6383`，来源 READY `ee2ee815`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking high、Read/Grep/Find/Ls-only；设计 findings 已转为决策表/source guard，最终 `FINAL PASS` 代码 P0/P1=0，非阻断 P2 经主控 triage 后无代码缺陷；Codex 独立代码终审 P0/P1/P2=0。R21+R19+R18+R02 claim+shared key targeted 81/81、scoped analyze 2 items / 0 issue、format/diff/path/status clean。四个集成提交 `c4a64fb1` / `6d0de95e` / `6118a75e` / `4e511c5a` 的 stable patch-id 与来源逐项一致。production host、durable truth/store/CAS、grant/outbox、settlement identity、release/grant/claim 原子性、persistence/data/tuning 继续 Gate。
- R19：计划 `cd20dc1c`、Pi findings 收紧 `3e458f2d`、红测 `5ec27f7d`、实现 `fd268f49`、终审 `429d0148`，来源 READY `45faccd0`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking high、Read/Grep/Find/Ls-only；实现前发现的 3 项 P1 全部在编码前关闭，最终代码 P0/P1=0，两项文档 P2 已关闭。R19+R18+R15 targeted 45/45、scoped analyze 4 items / 0 issue、format/diff/path/status clean；Codex 独立终审 P0/P1/P2=0。五个集成提交 `d500d1c3` / `7b45838a` / `9ccc746d` / `edf7f206` / `481f781a` 的 stable patch-id 与来源逐项一致；主控在 provisional code integration 态复跑 45/45，并在来源 READY 后补齐终审证据。production host、durable persistence、claim/reward、settlement identity、candidate/tuning 继续 Gate。
- R20：计划 `a1330858`、Qoder 设计证据 `40dfc994`、红测 `3790448d`、实现 `30002ef9`、本地验证 `d8f1f00b`、终审 `d243a84a`，来源 READY `245cf2fd`。Qoder CLI 1.1.28 使用精确 selector `Qwen3.8-Max`、reasoning high、Read/Grep/Glob-only；设计 `DESIGN PASS`，最终 `FINAL PASS` P0/P1/P2=0，并诚实记录无法内省底层模型。R20+R02+R15 去重 targeted 44/44、scoped analyze 2 items / 0 issue、format/diff/path/status clean；主控独立复跑 44/44 与 analyze 2 items / 0 issue。六个集成提交 `9036f6ca` / `7504e49f` / `a1a11e6b` / `090aa89d` / `6ef11663` / `14383743` 的 stable patch-id 与来源逐项一致。production 四活动入口、shared occupancy、host/persistence/data/tuning 继续 Gate。
