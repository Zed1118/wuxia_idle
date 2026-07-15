# Session 交接 · 江湖远行 Phase B（B2.2–B2.3 后端完成）

**时间：** 2026-07-16（承 `2026-07-16_0020` 会话）
**分支：** feat/baicao-duanhun-phase-b（worktree `baicao-duanhun-phase-a2`·**未 push·未合 main**）
**HEAD：** `37419c6e`（本会话 5 commit：`225c98d3` 状态机 / `6ec6a1d5` 生产接线 / `4ff7c464` 恢复点 / `9d4668be` 返程 / `37419c6e` settleToNow；docs commit 另计）

## 本会话完成（百草岭远征后端全线，严格 TDD）
- **B2.2a `settle` 状态机**：6 不变式（在线分段==一次性离线 / 幂等 / 单批上限 24 / cursor 守卫 / 战败即停 / 时间回拨）。节点完成时刻按 `departedAt+累计时长`绝对锚定 → 推进为 `(run,now)` 确定函数，幂等/在线=离线自然成立。敌队经 `ExpeditionCombat` 注入 seam 解耦。
- **B2.2b 生产接线** `ExpeditionCombatRunner`：派遣成员经 `StageBattleSetup.buildPlayerTeamForCharacters`（新增 additive 公开法·零回归）装真队 + 占位敌（学徒阶·`TODO(batch3-probe)`）+ `ExpeditionBattleRunner`。**e2e 真角色端到端推进节点 5 真打真赢**（feedback_layered_bugs 守卫）。
- **`settleToNow`**：循环分批追平/战败。
- **B2.3 `recall({defeated})`** 单事务：发 stagedRewards（全员含倒下者经验·受发布上限层锁）+ 物品入库 + 战败伤势（倒下重伤/其余轻伤·召回不附伤）+ 删 run（占用自动解除）。

## 已验证（本会话 worktree 实测）
- `flutter analyze --no-pub lib test` **0**
- 全量 `flutter test --no-pub` **4071 pass / 0 fail**；`stage_battle_setup_test` 35 回归绿
- macOS build **本环境不能跑**（仅 CommandLineTools·`xcodebuild` 缺）→ 留 morning

## 未完成（下一步 = B2.4，纯视觉·morning 真机验收）
- **B2.4**：provider（注入 `ExpeditionCombatRunner(isar)` + `expeditionConfig!`·结算走 `settleToNow`·召回走 `recall`）+ `expedition_overview_screen`/`expedition_recap_screen` + 3 visual_route（`expedition_overview/active/recap`·沿 team_lineup seed 体例）。§7.1 总览显队伍/方针/深度/完成节点/下一节点剩余/召回；§4.7 行记显最深/完成/重要战斗/主要奖励/断魂帖数/伤势。
- **B.V**：macOS build + Codex @1280×720/1440×900 目检。

## 关键决策 / 踩坑（B2.4 必读）
- 修炼/伤势不 per-node 调 resolve（§4.6 伤势归返程按最深节点+倒下人数结算，已在 B2.3）。
- 战败无持久 flag（下一战确定性再败可复现）；exp 全员各得完成节点经验；敌队/伤势深度曲线数值占位待 batch3 探针。
- provider 装 config 防异步 race（`feedback_flutter_async_config_race_controller_final`）：别构造期定死 null。
- **push 是用户的活**——phase-b 全未 push、A2 已 FF 入本地 main 亦未 push。

## 恢复点
详 plan `docs/superpowers/plans/2026-07-15-baicao-duanhun-phase-b-expedition.md` §当前恢复点。
