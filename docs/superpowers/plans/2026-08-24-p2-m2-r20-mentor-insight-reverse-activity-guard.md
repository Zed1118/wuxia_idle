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
- 编码前设计审查：待执行。
- 最终 diff 审查：待执行。

## 验收 checklist（CLAUDE §8.2）

- [ ] 编码前与最终均用 Qoder CLI 1.1.28 + exact `Qwen3.8-Max` +
  reasoning high 完成 Read/Grep/Glob-only 审查，不授权 Bash/Edit/Write。
- [ ] TDD 红→绿并提交小切片；覆盖四活动、empty/other-character、
  restore revision、invalid ID、输入不变、error fields 和 source guard。
- [ ] 生产接线证据如实标记为“未接”：本任务只交付 host-neutral
  guard，不冒充四类活动入口已接线。
- [ ] targeted tests、scoped analyze、format、`git diff --check`、owned-path
  audit 与 clean status 通过；按任务约束不跑 full suite。
- [ ] 红线影响：0 数值/YAML/玩家文案/三系/在线离线/反主流/
  reward/save/UI/host 变更。
- [ ] 中文动宾小提交完成；计划证据收口后追加精确 READY 空提交。

## 任务切片

1. 完整读取规约、Batch17 R20、R02/R15 和 R18 Qoder 证据体例。
2. 提交本计划恢复点，运行指定 Qoder 编码前只读设计审查。
3. 先新增测试并跑出目标 API/source 缺失的有效红灯。
4. 实现最小 guard，运行 targeted 与静态验证。
5. Qoder 最终只读 diff 审查，主 agent 独立复核 findings 并收口 READY。

## 当前恢复点

- 状态：设计/API 与验收矩阵已冻结，待 Qoder 编码前只读审查。
- 最后完成：核对 Batch17 tip `88e14134`，完整读取 CLAUDE / AGENTS /
  Batch17 R20 / R02 / R15 / R18 与已否清单。
- 下一步：提交计划，运行 Qoder 设计审查，再开始红测。
- 已跑验证：初始 `git status` clean；CLI 1.1.28 与精确模型选择器
  已核对。
- 阻塞：无。production host/shared occupancy 接线继续为显式 Gate。

