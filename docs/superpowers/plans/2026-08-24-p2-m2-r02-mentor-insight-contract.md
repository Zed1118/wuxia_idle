# P2-M2-R02 随行听剑纯合同与幂等 claim 合同

## 目标

从 G0 READY `44e42497` 出发，在独立分支实现随行听剑（MENTOR-INSIGHT-CORE-01 / OCCUPANCY-01 / RATE-01）的**纯合同切片**：

- domain 层：随行听剑政策 —— 首通可选 0-1 名门人、不入战 / 不受伤 / 不分掉落 / 不重复发放、单关占用、与闭关 / 远征 / 断魂庄 / 疗伤四类活动互斥、四种结算释放、成长对象仅主修招式熟练度；
- application 层：首通幂等 claim 合同 —— 版本化幂等键、首通闸门、内存台账、幂等恢复结算（不重复发放）。

**本合同不写**：比例、每关 cap、生产发放、存储、tuning 默认；不改任何既有 shared / data / save / UI / host 实现，不改 task / decision registry 与 GDD / CLAUDE / PROGRESS。

## 合同范围与冻结边界（决策映射）

| 决策 | 冻结语义 | 本合同表达 |
|---|---|---|
| MENTOR-INSIGHT-CORE-01 | 首通可随行 0-1 名门人；不入战、不受伤、不分掉落、不重复发放 | `MentorInsightChoice`（0/1 名）、`MentorInsightPolicy.maxCompanions=1`、`noCombatParticipation` / `noInjury` / `noDropShare` / `firstClearOnly` 固定保证；claim 幂等见 application 层 |
| MENTOR-INSIGHT-OCCUPANCY-01 | 单关占用；success / failure / explicit exit / idempotent recovery settlement 四种结算后释放；与闭关、远征、断魂庄、疗伤全部互斥 | `MentorInsightOccupancyScope.singleStage`（枚举唯一取值）、`MentorInsightReleaseReason` 四值枚举、`MentorInsightBlockingActivity` 四值枚举、`MentorInsightPolicy.canAccompany(BlockingStatus)` |
| MENTOR-INSIGHT-RATE-01 | 成长对象仅主修招式熟练度；比例与每关上限为 TUNING | `MentorInsightGrowthTarget.mainTechniqueProficiency`（枚举唯一取值）；合同面无任何数值字段，结构性红线测试钉死 |

## 实现

新增文件（范围外零改动）：

- `lib/features/mainline/domain/mentor_insight_policy.dart` — 纯合同类型与校验（体例对齐 `shared/battle_shared/failure_policy.dart`：无持久化、无 schema、无生产接线）；
- `lib/features/mainline/application/mentor_insight_claim_policy.dart` — 幂等 claim 键（`v1|mentorInsight|stageId|characterId`）、首通闸门、内存台账（体例对齐 shared `RewardClaimKey` / `RewardGrantGuard`，因键形不同自成一体，不改 shared）；
- `test/features/mainline/domain/mentor_insight_policy_test.dart` — 13 测（CORE / RATE / OCCUPANCY / 纯合同边界）；
- `test/features/mainline/application/mentor_insight_claim_policy_test.dart` — 17 测（键确定性 / round-trip / fail closed / 幂等发放 / 恢复结算 / 纯合同边界）。

## 证红与验证

- 先写测试证红：合同文件不存在 → 两个测试文件编译失败（合同面未实现）。
- 实现后 targeted 30/30 通过（`flutter test` 两文件 `--no-pub`）。
- scoped `dart analyze` 4 文件 0 issue；`dart format` 与 `git diff --check` 通过。
- 结构性红线测试：合同文件无 `package:isar` / `@collection` / `SaveData` / `saveDataId` 依赖；无 `rate` / `cap` / `amount` / `pct` / `percent` 成员面（DartSourceContract AST 断言）。

## 恢复点与风险

- 未接入生产：无 data / save / UI / host / activity 改动；claim 台账为内存态，生产接线需按 shared 体例落库并承接事务性（RATE 定标与生产接线留给后续批次）。
- 互斥反向（已随行门人不得进入四类活动）只在本合同声明，落地由宿主接线时消费 `canAccompany`。
- 风险：四类活动中的「疗伤」非 `ActivityKind` 枚举成员，生产接线需自行判定角色疗伤状态填充 `MentorInsightBlockingStatus.inHealingRecovery`；本合同以纯输入快照隔离该差异。
