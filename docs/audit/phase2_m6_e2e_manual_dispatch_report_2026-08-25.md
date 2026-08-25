# Phase 2 M6 百草岭真实差遣端到端闭环审计

日期：2026-08-25

分支：`codex/phase2-m6-e2e-manual-dispatch-report-closeout-20260825`

基线：`47b2d4a706ed38c13181c0250866fc3f775e0604`

代码候选：`bcf2c0396c1f610e6e7d102d674cf59b51199f77`

复核修复候选：`f69f61ce96db542a319253c6d7e2d77890d542a8`

## 结果合同与门变化

本门只关闭“百草岭真实逐次差遣、实际参与者快照、Phase 0A headless 自动/离线战斗、共享战斗账本与返程身份报告”这一 M6 必要生产子门：`0/1 → 1/1`。顶层 M0–M9 仍为 `1/10`，M6 仍 WIP；不将本子门 READY 解释为 U01、M6 或二阶段完成。

## P0 基线与所有权

- 启动点为既有 READY tip `47b2d4a706ed38c13181c0250866fc3f775e0604`，其祖先链依次包含断魂庄、轻功、守城、九霄塔实际参与者/共享结算/身份报告四门。
- 启动时 registry 共 145 项：144 `ready_reviewed` + 1 `completed`，无 active WIP；本任务是唯一新增主 WIP。
- 未登记 worktree `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-e2e-manual-dispatch-report` 仅作只读核查：它是 clean 的旧 shell，不接管、不删除、不作为生产证据。
- 生产 owner 保持唯一：`ExpeditionService` 接收请求并落 durable participant；`CharacterOccupancyService` 统一占用；`CurrentLeaderResolver` 解析掌门；`Phase0aExpeditionCombatRunner` 运行既有同核 headless；`CombatResolutionService` 写共享个人战斗账本；`ExpeditionRecapScreen` 只展示已核验的返程身份。

## 生产路径

`宗门 Hub / 江湖地图 → ExpeditionOverviewScreen → ActivityParticipationRequest(expedition/dispatch/playerBot/headless) → ExpeditionService → eligible 当前代际角色 → ActivityMemberSnapshot → CharacterOccupancyService → Phase0aExpeditionCombatRunner → 既有 Phase 0A reducer/headless → CombatSettlementSnapshot → CombatResolutionService → ExpeditionReturnResult → ExpeditionRecapScreen 实际参与者报告`

UI 不再直接调用 legacy raw dispatch。生产 selector/runner 只消费 durable snapshot；战斗前重新核验角色代际、生死、疗养、精确装备与心法。终局 settlement 必须恰好包含该单一参与者且胜负、HP 对齐，错人时在 cursor、奖励和个人账本写入前 fail closed。远征深度、奖励、会话经验与伤势仍由既有 `ExpeditionService` 负责，避免共享账本重复发放。

## RED / GREEN 与验证证据

- 有效 RED：依赖和生成件就绪后，契约因缺 `dispatchRequestFor`、`contentId` 与返程 participant 字段出现 3 个编译失败；native-assets 的前置环境崩溃未冒充 RED。
- 定向：真实差遣契约、真实 runner 与随机源棘轮联合 `19/19 PASS`；overview UI typed request 纳入活动域。
- 百草岭活动域：`121/121 PASS`。
- 相邻掌门解析、当代调度、活动占用、主线参与者政策/可见重打、江湖地图身份与随机源域串行 `48/48 PASS`。
- 应用路径：`flutter analyze --no-pub lib test`，0 issue。
- 全量：唯一一次 `flutter test --no-pub` 在 reporter 约 `5:00`（约 5 分钟）结束为 `5559 PASS / 1 FAIL`；失败是本门新增 `ExpeditionService` 在共享结算内 inline `DefaultRng()`，由全仓随机源棘轮准确拦截。修复为构造注入既有 `Rng`、生产 provider 注入既有 `rngProvider` 后，棘轮 `5/5`、定向 `19/19`、活动域 `121/121`、相邻域 `48/48`、analyze 0。当时因成本单位误读而未重跑第二次全量，因此本审计明确不把该次全量写成全绿；最终统一候选须补一次完整套件。
- `git diff --check`、registry YAML 解析与 owned-file 双向白名单通过。

## fail-closed 与保留边界

无效/悬空掌门、跨代角色、死亡、疗养、无主修、重复占用、provider 异常、悬空/错配/重复装备与心法、stale participant、错人 settlement 均由测试覆盖并拒绝写入，不回退掌门。headless/sweep 继续遵守 `MAINLINE-REPLAY-PARTICIPANT-01` 的当前掌门政策；本门未新增 reducer、session、headless 内核、provider 或 settlement 真相源。

未改 schema/saveVersion、YAML、`TUNING/candidate`、奖励、经济、解锁、叙事和战斗规则；未恢复旧 3v3、断魂庄前台 bot、代选奖励或统一完成报告；未修改、合并或 push main。

## 成本、阻塞与下一门

主成本读数为墙钟时间。该次全量 reporter 约 `5:00`，实际约五分钟；历史上误读为五小时并据此停止追加全量。它发现并关闭了一个真实随机源注入 P1；修复后的风险匹配验证全部通过，最终统一候选须补一次完整套件。后续门使用固定定向验收，跨切面最终候选再执行一次全量。

当前前三 blocker：

1. U01 的 manual/auto/replay/headless/sweep 与随行听剑仍未形成全模式一致性证据。
2. U09/U10/U14 尚未按冻结产品合同完成生产纵切。
3. M2 G2 只正式覆盖黑风岭 `stage_01_03`，不能外推为完整正式试玩门。

下一最高价值门：按既定顺序审计并关闭 U01 全模式一致性；如触及 schema、TUNING、产品决策或新的共享真相源，则保留 clean/WIP 并标 BLOCKED，不猜测。
