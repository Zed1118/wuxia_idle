# Phase 2 M5 六模式工程集成审计

日期：2026-09-01

原审计基线：`22afa6d3831b4dfb0d20df7d6694f6f7c13ff968`

本轮最新集成基线：`b530d804940930628ea1b61e83b188416bc0b1d2`

任务：`P2-M5-ENGINEERING-INTEGRATION-AUDIT`

## 结论

M5 不能从历史纵切 READY 或已经关闭的 M6 工程接线直接推导为完成。九霄塔 durable dispatch 和 actual-participant 个人记录先把有效矩阵推进到 `39/42`；本轮再为断魂庄接入 exact participant/loadout 的可恢复持久差遣 owner。当前有效矩阵为 `40/42`，仍有 `2/42 BLOCKED`，顶层 M5 工程 Gate 保持 `0/1 BLOCKED`。

轻功与守城现在只在已首通后开放三条精确通道：可见 `direct + playerBot + realtime + replay`、快速推演 `direct + playerBot + headless + replay`、既有差遣 `dispatch + playerBot + headless + offlineResume`。它们复用真实 Host、headless runner、durable receipt 与共享 settlement；首通仍为人控。心魔个人进度复用 U09 胜利事务已落的 personal-scope receipt，角色面板与关卡列表不再继承其他角色的存档级心魔事实。断魂庄现复用 Boss 会话检查点和统一 durable receipt，自动战斗仍停在玩家三选一。其余缺口只剩百草岭首次关键节点手动接管及其 route/milestone 自动化记录，不能由本批外推。

## 42 格生产映射

| 模式 | production entry | 首通门槛 | 自动解锁 | 奖励 | 伤势/失败 | 记录 | 离线/差遣允许矩阵 | 小计 |
|---|---|---|---|---|---|---|---|---:|
| 九霄塔 | PASS `TowerFloorListScreen → runTowerFlow/startTowerDurableDispatch` | PASS `TowerProgressService` 每层首通 | PASS `TowerAutomationPolicy` 已通层 sweep + durable dispatch | PASS `applyTowerVictorySettlement` + 双层 receipt | PASS exact participant 共享结算 | PASS `TowerPersonalRecord` 按存档和实际参与者隔离最高层/有效最好耗时 | PASS 已通层 exact participant durable dispatch；首通仍手动 | 7/7 |
| 轻功 | PASS `LightFootScreen → runStageFlow` | PASS `LightFootService` 路线链 | PASS 已通路线 durable dispatch | PASS 共享 stage/durable receipt | PASS 通用伤势归 exact participant | PASS `MainlineProgress` 路线通关 + 个人战斗账本 | PASS 已首通后三通道精确接入前台 bot、即时 headless 与既有差遣 | 7/7 |
| 守城 | PASS `MassBattleScreen → runStageFlow` | PASS `MassBattleService` 关卡链 | PASS 已通关 durable dispatch | PASS 共享 stage/durable receipt | PASS 通用伤势归 exact participant | PASS `MainlineProgress` 守城通关 + 个人战斗账本 | PASS 已首通后三通道精确接入；headless 持久化本次阵型 | 7/7 |
| 心魔 | PASS 角色突破页本人进入 `InnerDemonScreen` | PASS 每次均本人手动 | PASS 自动化全禁的 fail-closed 策略 | PASS personal-scope receipt | PASS 只结内息紊乱、无物理伤势 | PASS `innerDemonProgressProvider(characterId)` 消费 U09 personal receipt；角色面板与关卡链按本人隔离 | PASS direct + human + realtime，其他组合全拒绝 | 7/7 |
| 断魂庄 | PASS `GauntletLoadoutScreen → GauntletService` | PASS 首次完整通关手动 | PASS 已首通整备页保留 direct replay policy，并提交 exact participant 的 durable dispatch | PASS `chooseReward` 原子奖励；胜败业务结算与 durable receipt 同事务 | PASS 会话末统一伤势/部分收益 | PASS Boss 检查点 + unified durable owner/receipt + 通关事实与战报 | PASS `dispatch + playerBot + headless + offlineResume` 可恢复，胜利仍停在玩家三选一 | 7/7 |
| 百草岭 | PASS `ExpeditionOverviewScreen → ExpeditionService.dispatchRequest` | **BLOCKED** 普通/险关均由 headless runner 推进，未实现首次关键里程碑手动接管 | **BLOCKED** 没有 `routeId + milestoneId` 的手动已通过记录与后续自动门 | PASS 暂存账本 + return receipt | PASS 实际参与者伤势并保留已完成节点 | PASS durable run、深度、返程报告 | PASS 核心形态为单人 dispatch + headless + offline | 5/7 |

合计：`7 + 7 + 7 + 7 + 7 + 5 = 40/42`。

## 两个真实阻塞

1. 百草岭没有首次关键里程碑必须手动的接管边界。
2. 百草岭没有 `routeId + milestoneId` 的自动化解锁记录，因而也无法证明“首次手动、以后自动”。

两项需要共同的 route/milestone 持久事实、生产 UI/恢复状态机与离线遇门自动返程。它们不是本次“集成守卫”可以诚实补齐的测试缺口。

## 已重跑的生产基线

组合命令覆盖 `activity/tower/light_foot/mass_battle/boss_gauntlet/expedition/inner_demon` 全目录，以及共享 `apply_victory_resolution` 和 `stage_entry_flow`：`565/565 PASS`，退出码 0，末行 `All tests passed!`。

本轮轻功/守城候选另完成扩展定向 `82/82 PASS`、破坏证红 `4 + 1 + 2` 条失败并精确还原、`flutter analyze --no-pub lib test tool` 0 issue，以及锁保护整仓全量 `5828/5828 PASS`、`[E]=0`、末行 `All tests passed!`。

心魔个人进度纵切另完成扩展定向 `113/113 PASS`、两向破坏证红各 `1` 条失败并精确还原、测试契约迁移 Gate `PASS`、`flutter analyze` 0 issue、`dart format .` 1699 files / 0 changed，以及锁保护整仓全量 `5828/5828 PASS`。这些绿色证据连同轻功/守城纵切合计关闭三格，不证明当前其余四个不存在的 owner 已完成。

本轮断魂庄资格修复先取得生产 widget RED `2` 条失败，再完成核心定向 `40/40 PASS`、断魂庄全目录 `192/192 PASS`；强开首通前入口、破坏 exact request、移除原子准入三组 mutation 各精确得到 `1` 条失败并反向还原。`flutter analyze --no-pub lib test tool` 0 issue，`dart format .` 1699 files / 0 changed，锁保护整仓全量 `5833/5833 PASS`。最终测试树相对基线删除行数为 `0`，无需测试契约迁移登记。该批只修复原 `37/42` 中一格的生产资格，不增加分子。

本轮九霄塔持久差遣新增真实塔层入口、exact participant/loadout durable owner、`mapTower` headless 和双层 receipt 原子结算；扩展定向 `79/79 PASS`。三向 mutation 分别得到 `4`、`1`、`1` 条失败并精确反向还原，证明 dispatch allowlist、生产入口与 durable settlement receipt 不是恒真守卫。最终测试树相对基线删除行数为 `0`，旧 sweep 与拒绝契约原样保留，durable 守卫纯增量加入，无需测试契约迁移登记；实现候选阶段 full analyze 0 issue，整仓 format `1700 files / 1 changed`，锁保护全量 `5838/5838 PASS`、`[E]=0`。随后 exact `[READY]` tip `62d6df2aea62d54bb1abf8f730fe8e6cb100f572` 的正式 Gate 重新执行整仓测试并得到 `5840/5840 PASS`；前一数字是候选阶段记录，不是 final-tip Gate 分母。未改 Isar collection 字段、schemaVersion/saveVersion、YAML、数值、奖励或战斗规则；该批净增一格至 `38/42`。

本轮塔个人记录新增 `TowerPersonalRecord` 和 0.44 加法迁移，只从真实胜利结算写入；手动、扫荡、持久差遣共用原事务。扩展定向 `164/164 PASS`，三向 mutation 分别得到 `4`、`2`、`1` 条失败并精确还原；其中旧档夹具先发现无角色导致伪回填假绿，补成“有角色但无参战证明”后才获得有效 RED。analyze 0 issue，整仓 format `1704 files / 0 changed`。首轮锁保护全量另捕获四条仍写死 `0.43.0` 的旧迁移断言，更新到精确 `0.44.0` 后相关迁移集 `10/10 PASS` 并进入测试契约迁移登记；修复后锁保护整仓复跑 `5844/5844 PASS`、退出码 0、`[E]=0`。exact READY tip Gate 由本任务最终 receipt 单独绑定，不在执行前预写 PASS。该批净增一格至 `39/42`。

本轮断魂庄持久差遣复用 `BossGauntletRun` 检查点和既有 `DurableActivityCombatRun`，不新增 schema/saveVersion。扣帖、补给、Boss 会话和 durable owner 同事务创建；胜败结算与 receipt 同事务提交，生产恢复卡消费同一 owner，胜利只到既有三选一。核心生产 `29/29 PASS`、断魂庄全域 `199/199 PASS`、共享 activity `20/20 PASS`、analyze 0 issue。四向 mutation 分别得到 `4`、`1`、`2`、`1` 条失败；其中装配漂移用例初次暴露“更晚异常替代早期守卫”的假绿，补强 `lastAdvancedAt` 不变断言后才获得有效 RED。测试契约迁移 Gate 对 `expect 删 4 / 增 46、用例删 2 / 增 10、登记 6 条` 输出 PASS；exact-tip 全量与项目 Gate 在最终提交后执行。该批净增一格至 `40/42`。

上一轮九霄塔 durable 候选的最终工程检查：

- exact final tip：`62d6df2aea62d54bb1abf8f730fe8e6cb100f572`；
- `flutter analyze`：0 issue，Gate 末行 `No issues found! (ran in 17.3s)`；
- `dart format .`：Gate 记录 `1700 files / 0 changed`；
- 锁保护整仓全量：`5840/5840 PASS`，退出码 0，`[E]=0`，Gate 末行 `05:32 +5840: All tests passed!`；
- Gate：`forbidden_files`、`test_deletions`、`commit_msg`、`worktree_clean`、`full_test`、`analyze`、`format`、`receipt_crosscheck` 均 PASS；
- 最终测试树相对基线删除行数为 `0`，无需测试契约迁移登记；
- 本机原始日志位于忽略目录 `build/m5_tower_durable_gate.log`，receipt 位于 `build/m5_tower_durable_gate_receipt.yaml`；执行脚本为本机操作层 `/Users/a10506/.claude/skills/afk/scripts/gate.sh`，SHA-256 `edf4710983c929d04036c5896bb40e17842d9ad06553bfad9775f0df832f0fea`。因此 final Gate 在本机已有原始证明，但日志与脚本未进入仓库，跨机器可移植复核能力弱于仓内证据；后者是证据治理风险，不等于 Gate 未执行。

## 后续推荐施工顺序

1. 补百草岭手动里程碑接管和 `routeId + milestoneId` 自动化记录；两格共用同一事实 owner，应作为一个受控迁移推进，范围跨离线推进、可见战斗、返程报告和恢复。

每批都必须独立分支/worktree、可编译破坏证红、targeted、analyze、format、锁保护全量、Gate、合并 push 与精确 SHA CI。真人桌面和 Windows 实机继续挂账，不能替代工程门，也不被工程门替代。
