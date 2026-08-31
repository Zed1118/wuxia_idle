# Phase 2 M5/U14 轻功与守城持久差遣候选审计

## 结论

用户授权的一次加法持久化迁移已把轻功与守城从“只有手动亲战”补成真实生产 durable automation：已首通关卡在生产列表提供差遣入口，实际参与者、装配、守城阵型、离线游标和幂等结算 receipt 先后落入同一持久 owner；执行继续复用既有 Phase 0A mapper、headless runner 和共享胜败 settlement。

因此三个固定工程子门形成候选：

- `P2-M5-LIGHT-FOOT-AUTOMATION-ADMISSION`: `0/1 → 1/1`；
- `P2-M5-MASS-BATTLE-AUTOMATION-ADMISSION`: `0/1 → 1/1`；
- `P2-M6-U14-SPECIAL-MODE-MATRIX-AND-ROUTE-STATES`: `0/1 → 1/1`。

这不晋升 M5、M6、顶层 M0–M9 或整个二阶段；真人试玩、常规桌面视觉、入口文案与守城阵型选择手感全部挂账。

## 生产链

| 边界 | 轻功 | 守城 |
| --- | --- | --- |
| 玩家入口 | 已首通路线的 `LightFootScreen` 差遣按钮 | 已首通关的 `MassBattleScreen` 差遣按钮 |
| typed allowlist | `dispatch + playerBot + headless + offlineResume`，必须已首通 | 同左，且必须持有玩家选定阵型 |
| durable owner | `DurableActivityCombatRun` | 同一 collection，额外持久 `formation` |
| 占用 | 实际角色 + 装备 + 心法 | 实际角色 + 装备 + 心法 |
| 执行 | `mapLightFoot → Phase0aSweepHeadlessRunner` | `mapMassBattle(formation) → Phase0aSweepHeadlessRunner` |
| 结算 | 既有共享胜败 settlement 与 receipt 同一 Isar 事务 | 同左 |
| 恢复 | active run 用固定 seed 重跑；settled run 只展示报告 | 同左，不猜默认阵型 |

旧档从 `0.40.0` 加法迁至 `0.41.0`，新 collection 为空；历史通关不伪造 active run 或已结算 receipt。

## U14 六模式矩阵

| 模式 | 真实生产 owner | 冻结允许语义 |
| --- | --- | --- |
| 九霄塔 | `TowerAutomationAdmissionService` | 已首通层 direct + playerBot + headless + sweep |
| 轻功 | `DurableActivityAutomationService` | 已首通路线 dispatch + playerBot + headless + offlineResume |
| 守城 | `DurableActivityAutomationService` | 已首通关 + 持久阵型，dispatch + playerBot + headless + offlineResume |
| 心魔 | `InnerDemonParticipationPolicy` + 真实本人 snapshot owner | 本人 direct + human + realtime；其他组合拒绝 |
| 断魂庄 | `GauntletAutomationAdmissionService` | 完整首通后 headless replay |
| 百草岭 | `ExpeditionService` | exact typed dispatch + playerBot + headless + firstClear |

矩阵测试直接调用上述实际 policy/service 生产 owner；两条新增模式另有真实 UI、runner、coordinator 与 settlement 证据，不以孤立枚举表代替生产接线。

## 验证与破坏证红

- 组合 targeted：`70/70 PASS`；覆盖 activity、轻功、守城、两地点详情、共享 runner 与两条迁移门。
- 整仓 `flutter analyze --no-pub lib test`：0 issue。
- `dart format .`：`1674 files / 0 changed`。
- remove implementation：删除 `CharacterOccupancyService` 的 durable 聚合后，统一占用与 service 用例实测 `2 FAIL`；精确还原。
- force degenerate value：让 `alreadyCleared` 门恒不拒绝后，policy 用例实测 `1 FAIL`；精确还原。
- 最终全量、独立 Gate 与合并态结果待候选冻结后执行，不能由本段预写为 PASS。

## 红线与挂账

- 未改玩家数值、技能、奖励金额、经济、YAML TUNING、解锁、战斗公式或 reducer。
- `lib/shared/strings.dart` 零 diff；复用既有合法 UI 词条，地点详情已移除旧的错误事实。
- 未新增第二 headless 内核或 settlement 真相源。
- 真人需复验：两个首通列表的差遣入口可发现性、选人/阵型操作、进行中与战报文案可读性、失败/恢复时的主观连贯性。
