# P2-M2-R02 随行听剑纯合同与幂等 claim 合同

## 目标

从 G0 READY `44e42497` 出发，在独立分支实现随行听剑（MENTOR-INSIGHT-CORE-01 / OCCUPANCY-01 / RATE-01）的**纯合同切片**：

- domain 层：随行听剑政策 —— 首通可选 0-1 名门人、不入战 / 不受伤 / 不分掉落 / 不重复发放、单关占用、与闭关 / 远征 / 断魂庄 / 疗伤四类活动互斥、四种结算一律释放、成长对象仅主修招式熟练度；
- application 层：首通 claim 纯合同 —— 只接受调用方事实（isFirstClear、externallyDurablyClaimed），输出 grant / skip / fail-closed 决策，不执行数值回调、不拥有 ledger、不声称持久化；
- shared 层：扩展 `RewardClaimKey` 增加 mentorInsight 形态（stageId + characterId），复用共享版本化 canonical / parser。

**本合同不写**：比例、每关 cap、生产发放、存储、tuning 默认；不改 data / save / UI / host 实现，不改 task / decision registry 与 GDD / CLAUDE / PROGRESS。

## 合同范围与冻结边界（决策映射）

| 决策 | 冻结语义 | 本合同表达 |
|---|---|---|
| MENTOR-INSIGHT-CORE-01 | 首通可随行 0-1 名门人；不入战、不受伤、不分掉落、不重复发放 | `MentorInsightChoice`（0/1 名，非空门人 id > 0）、`MentorInsightCompanion`（characterId > 0）、`MentorInsightPolicy.maxCompanions=1` 与 `noCombatParticipation` / `noInjury` / `noDropShare` / `firstClearOnly` 固定保证；claim 决策见 application 层 |
| MENTOR-INSIGHT-OCCUPANCY-01 | 单关占用；success / failure / explicit exit / idempotent recovery settlement 四种结算后释放；与闭关、远征、断魂庄、疗伤全部互斥 | `MentorInsightOccupancyScope.singleStage`（枚举唯一取值）、`MentorInsightReleaseReason` 四值枚举、`MentorInsightBlockingActivity` 四值枚举、`MentorInsightPolicy.canAccompany(BlockingStatus)`；释放与成长发放完全解耦，failure / exit / recovery 不自动触发成长 |
| MENTOR-INSIGHT-RATE-01 | 成长对象仅主修招式熟练度；比例与每关上限为 TUNING | `MentorInsightGrowthTarget.mainTechniqueProficiency`（枚举唯一取值）；合同面无任何数值字段，结构性红线测试钉死 |

## 实现

新增 / 修改文件（范围外零改动）：

- `lib/shared/battle_shared/reward_claim_key.dart` — **新增所有权**：`RewardClaimKeyKind.mentorInsight` + `RewardClaimKey.mentorInsight(stageId:, characterId:)` factory（characterId > 0 校验）、`_expectedPartCount` 新 case、parse 对 mentorInsight 的 characterId 正整数校验、`stageId` / `characterId` getter；canonical / parser / 版本化完全复用共享实现；
- `lib/features/mainline/domain/mentor_insight_policy.dart` — 纯合同类型与校验（体例对齐 `shared/battle_shared/failure_policy.dart`：无持久化、无 schema、无生产接线）；非空 mentee 与 companion characterId 均要求 > 0；release 与成长解耦注释；
- `lib/features/mainline/application/mentor_insight_claim_policy.dart` — claim 纯决策合同：`MentorInsightClaimOutcome { grant, skip, failClosed }` + `MentorInsightClaimPolicy.decide(isFirstClear, externallyDurablyClaimed)`；**不自造键 / parser / ledger，不执行数值回调**；
- `test/shared/battle_shared/reward_claim_key_test.dart` — **新增所有权**：mentorInsight 组（确定性 / round-trip / 隔离 / 校验 / fail-closed），既有测试不动；
- `test/features/mainline/domain/mentor_insight_policy_test.dart` — 新增 `>0` 校验断言；
- `test/features/mainline/application/mentor_insight_claim_policy_test.dart` — 决策表 + shared 键复用 + `RewardGrantGuard` 进程内纪律演示（明确不代表 durable storage）+ 结构性红线（无第二套 codec / 无存储 / 无比例 cap 成员）。

## 证红与验证

- 先更新测试证红：shared `mentorInsight` factory 未实现 → 测试编译失败（合同面未实现）。
- 实现后 targeted 全绿：`flutter test` R02 两测 + shared key / reward policy 四文件 58/58 通过（`--no-pub`）。
- scoped `dart analyze` 全部改动文件 0 issue；`dart format` 与 `git diff --check` 通过。
- 结构性红线测试：合同文件无 `package:isar` / `@collection` / `SaveData` / `saveDataId`；claim 合同文件无 `MentorInsightClaimKey` / `Ledger` / `parse(` / `componentSeparator` / `versionPrefix`（无第二套 codec）；无 `rate` / `cap` / `amount` / `pct` / `percent` 成员面（DartSourceContract AST 断言）。

## 恢复点与风险

- 未接入生产：无 data / save / UI / host / activity 改动；claim 决策的数值落地与 durable 记账由宿主承接（shared `RewardGrantGuard` 仅为进程内纪律演示，不代表 durable storage）。
- 互斥反向（已随行门人不得进入四类活动）只在本合同声明，落地由宿主接线时消费 `canAccompany`。
- 风险：四类活动中的「疗伤」非 `ActivityKind` 枚举成员，生产接线需自行判定角色疗伤状态填充 `MentorInsightBlockingStatus.inHealingRecovery`；本合同以纯输入快照隔离该差异。
- 修订记录：主控审查退回后按 6 点整改 —— 删除自造 claim key / parser / ledger，扩展现有 shared `RewardClaimKey`，claim 合同改为纯决策面，release 与 growth 解耦，非空门人 id / companion characterId 要求 > 0，保持 rate/cap/amount/pct、save、UI、production wiring 全缺席。
