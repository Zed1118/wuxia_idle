# P2-M2-R20：听剑反向活动互斥守卫

## 目标与边界

从 Batch17 登记 tip `88e14134` 出发，在 R02 四类固定互斥活动与
R15 immutable occupancy snapshot 之上建立 exact-character 反向准入
guard。本切片只拒绝已在当前 snapshot 中听剑的同一角色进入四类
活动，不查询也不修改任何活动或占用状态。

- 分支：`codex/phase2-m2-r20-mentor-insight-reverse-activity-guard-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r20-mentor-insight-reverse-activity-guard`
- owned files 严格限定为：
  - `lib/features/mainline/application/mentor_insight_reverse_activity_guard.dart`
  - `test/features/mainline/application/mentor_insight_reverse_activity_guard_test.dart`
  - 本计划文件
- 不改 registry / audit / main；不增加 host / persistence / UI / data /
  candidate / tuning / fallback activity。

## 冻结 API 与决策表

- `requireMentorInsightActivityEntryAllowed({required
  MentorInsightStageOccupancySnapshot occupancy, required int characterId,
  required MentorInsightBlockingActivity activity}) -> void`
- `MentorInsightActivityEntryRefusedError` 暴露 exact
  `activeCompanion` / `activity` / `characterId` 三项事实。
- `characterId <= 0` 按 R02/R15 的 integer ID 合同 fail closed，抛
  `ArgumentError`；不对 ID 做 trim、替换或默认。
- `occupancy.companion == null` 或 active companion 的 `characterId` 与请求角色
  不等时直接通过。
- active companion 的 `characterId` 与请求角色 exact 相等时，
  `retreat` / `expedition` / `bossGauntlet` / `healing` 四类全部抛
  `MentorInsightActivityEntryRefusedError`。
- snapshot `revision` 不参与决策；guard 只读一个 immutable snapshot，
  不更改 snapshot / companion / runtime。
- 四类活动固定复用 `MentorInsightBlockingActivity.values` 和 R02
  `MentorInsightPolicy.mutuallyExclusiveActivities`，不新建第二套枚举。

## TDD 与 source guard

1. 四活动决策表：exact active character 全拒绝，并锁定 exact error
   fields。
2. empty occupancy 与 other-character 请求全通过。
3. 同一 active companion 在不同 restore revision 下结果一致。
4. zero / negative character ID fail closed，且先于 occupancy 决策。
5. 成功与拒绝路径均不改变输入 snapshot 及 companion facts。
6. 锁定四值枚举和 R02 互斥集合；source guard 要求实现仅 import
   R15 runtime 与 R02 policy，禁止 `ActivityOccupancy` / `Character` /
   `Isar` / healing 状态 / host / persistence / UI / data / candidate / tuning，
   且不访问 `revision`。

## Qoder 只读审查证据

- CLI/version：`qoderclicn` 1.1.28；`--list-models` 实测含精确
  `Qwen3.8-Max`。
- 编码前设计审查：实际执行 `-m Qwen3.8-Max` +
  `--reasoning-effort high` + `--permission-mode dont_ask` +
  `--tools Read Grep Glob` + `--no-session-persistence`，明确禁止
  Bash/Edit/Write。Qoder 实际仅使用 Read/Grep/Glob，结论
  `DESIGN PASS`，P0=0、P1=0。三项 P2 均纳入测试设计：import
  正则白名单 + 文本禁词 + AST 三层 source guard；error 的
  `activeCompanion` 用 `same()` 锁定同一实例；测试锁定
  `MentorInsightBlockingActivity.values` 与既有互斥集合等价。
  Qoder 自述无法内省证明底层模型，因此精确模型证据仅以
  CLI selector 与 `--list-models` 可用性为准，不伪造额外自报。
- 最终 diff 审查：实际使用同一 `qoderclicn` 1.1.28 /
  exact `-m Qwen3.8-Max` / `--reasoning-effort high` /
  `--permission-mode dont_ask` / Read-Grep-Glob-only /
  `--no-session-persistence`，明确禁止 Bash/Edit/Write。本任务三文件
  相对 baseline 均为新增，Qoder 完整读取三文件与 R02/R15
  对照文件，实际使用 7 Read / 1 Glob / 1 Grep、零写入，
  结论 `FINAL PASS`，P0/P1/P2=0/0/0。它明确确认 invalid ID
  先拒绝、R02 集合唯一真相源、exact companion 对象同一性、四活动
  决策表、revision 无关、输入不变与三层 source guard 全成立。
  Qoder 仍诚实声明无法内省证明底层模型，精确模型证据继续以
  CLI selector 和 model catalog 为准。

## 验收 checklist（CLAUDE §8.2）

- [x] 编码前与最终均用 Qoder CLI 1.1.28 + exact `Qwen3.8-Max` +
  reasoning high 完成 Read/Grep/Glob-only 审查，不授权 Bash/Edit/Write。
- [x] TDD 红→绿并提交小切片；覆盖四活动、empty/other-character、
  restore revision、invalid ID、输入不变、error fields 和 source guard。
- [x] 生产接线证据如实标记为“未接”：本任务只交付 host-neutral
  guard，不冒充四类活动入口已接线。
- [x] targeted tests、scoped analyze、format、`git diff --check`、owned-path
  audit 与 clean status 通过；按任务约束不跑 full suite。
- [x] 红线影响：0 数值/YAML/玩家文案/三系/在线离线/反主流/
  reward/save/UI/host 变更。
- [x] 中文动宾小提交完成；本证据提交后直接追加精确 READY 空提交。

## 任务切片

1. 完整读取规约、Batch17 R20、R02/R15 和 R18 Qoder 证据体例。
2. 提交本计划恢复点，运行指定 Qoder 编码前只读设计审查。
3. 先新增测试并跑出目标 API/source 缺失的有效红灯。
4. 实现最小 guard，运行 targeted 与静态验证。
5. Qoder 最终只读 diff 审查，主 agent 独立复核 findings 并收口 READY。

## 当前恢复点

- 状态：实现、本地验证与 Qoder 两轮只读审查全部完成，
  进入 READY 交付。
- 最后完成：`a1330858` 冻结计划、`40dfc994` 记录设计审查、
  `3790448d` 锁定红测、`30002ef9` 实现最小 guard。有效红灯
  精确为目标 source/API/error 缺失；实现后 R20 12/12 通过。
  Qoder 终审 `FINAL PASS` / 0/0/0；Codex 独立复核三文件 actual
  baseline diff，P0/P1/P2=0/0/0。
- 下一步：提交本终审证据，复跑 diff/path/status，然后追加精确
  `[READY][QODER][P2-M2-R20] 冻结听剑反向活动互斥` 空提交。
- 已跑验证：R20 12/12、R02 policy 14/14、R15 runtime 18/18，
  三文件分别执行、去重合计 44/44；changed-Dart scoped analyze
  2 items 无问题；format 2 files 0 changed；baseline `git diff --check`
  与 owned paths 检查通过，工作树干净。fresh worktree 先恢复
  `flutter pub get`，并从 Batch16 worktree 根复制 `libisar.dylib`，
  SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；
  本测试未需要 build_runner。按任务约束未跑 full suite。
- 阻塞：无。production host/shared occupancy 接线继续为显式 Gate。

## READY

最终精确空提交：
`[READY][QODER][P2-M2-R20] 冻结听剑反向活动互斥`。
