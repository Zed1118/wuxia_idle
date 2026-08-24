# P2 M6 主菜单“当前要事”精确角色路由纵切

## 任务包

- taskId：`P2-M6-CURRENT-MATTERS-TARGET-ROUTING`
- milestone：M6
- owner：`codex_root`
- baseCommit：`23ab38cd7da8ae33923cc0b068c5905078b05f0d`
- branch：`codex/phase2-m6-current-matters-target-routing-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-current-matters-target-routing`
- status：`ready_reviewed`

## 已确认生产缺口

主菜单“当前要事”会从真实 active roster、闭关 session、伤势和突破状态生成生产摘要，
但摘要合同未携带目标角色。展示层因此把闭关、伤势和突破全部硬编码导航到
`characterId = 1`，闭关还硬编码 `RealmTier.xueTu`。继承换代、门人受伤或门人达到突破
条件时，玩家会被送到错误角色；若角色 1 不存在，路由仍猜测身份而不是 fail closed。

二阶段方案 §11.1、M6 目标与 Gate 要求统一用户入口接生产并对角色身份异常 fail closed；
现有首局审计也把“当前要事”列为主菜单主要行动路径。本纵切只修复该入口的目标
载荷与路由，不改变摘要优先级、文案、状态生成规则或任何下游业务。

## 文件白名单

- `lib/features/main_menu/application/main_menu_status_summary_provider.dart`
- `lib/features/main_menu/presentation/main_menu_status_summary.dart`
- `test/features/main_menu/main_menu_status_summary_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-current-matters-target-routing.md`
- `docs/audit/phase2_m6_current_matters_target_routing_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 生产合同

1. `MainMenuStatusSummaryItem` 对需要角色身份的路由携带 typed 目标角色；闭关目标额外
   携带该角色当前境界，不得由展示层猜测。
2. 闭关摘要只在 active roster 中恰有一个角色的 `currentRetreatSessionId` 指向当前
   active session 时生成，并导航到该角色/境界的 `SeclusionMapListScreen`。
3. 伤势摘要继续聚合 active roster 的受伤人数和最长普通伤势时长，点击精确进入 active
   roster 顺序中的首名受伤角色。
4. 突破摘要继续选择 active roster 顺序中的首名达标角色，点击精确进入该角色。
5. 需要角色载荷的路由若载荷缺失、悬空或不唯一则 fail closed，不回退角色 1 或学徒境界。
6. 桃花岛与主线路由、摘要优先级、最多五项、文案和下游业务保持不变。
7. 不修改 schema/saveVersion、YAML、调优、数值、奖励、经济、解锁、角色/闭关写路径或 main。

## TDD 与验收

- 红测：构造非 1 号闭关角色、非 1 号受伤角色和非 1 号突破角色，断言生产摘要载荷
  与最终 Screen 参数；现状缺少载荷且总是导航到 1 号角色，必须失败。
- fail-closed：悬空闭关 session 不生成可行动摘要；手工注入缺少目标的角色路由不得 push。
- 定向：摘要顺序/文案保持、闭关/伤势/突破精确目标、桃花岛/主线不变、1280×720 与
  1440×900 无 overflow。
- Gate：format、变更范围/root application analyze、`git diff --check`、白名单、独立语义
  复核 P0/P1=0、最终一次全量、clean READY。

## 停止边界

若需要改变活动占用、闭关 session schema、伤势/突破规则、摘要优先级/文案、主菜单
信息架构或任何数值，停止并另立切片。

## 完成证据

- registration：`2de7a2e393bacbb224f62a98039c525301ef4cfe`
- 初始红测：`8f21453eb979057878c5fb853813996d5dc506f9`，目标载荷合同不存在，0/1。
- 首个代码候选：`8926d0c3da6e473991774ae508af5bb92392dc29`。
- 复核红测：`d68af49b6d8ab9309da7106f3175b8fce083d83c`，正数悬空 ID 仍错误 push，10/11。
- code/reviewed candidate：`08eac7961e669451f39668129f131188433374af`。
- 聚焦 14/14；主菜单、角色面板与闭关相邻域 387/387；双视口 2/2。
- 变更范围与根应用 `flutter analyze --no-pub lib test tool`：0 issue。
- 最终全量 `flutter test --no-pub --reporter compact`：5430/5430 PASS。
- 独立复核首轮 P0=0/P1=1/P2=2；修复后 P0=0/P1=0，唯一文档 EOF P2 已在
  最终同步关闭，语义结论可 READY。
- `git diff --check`、10 文件白名单与最终 clean 状态通过。

最终 marker：`[READY][CODEX][P2-M6-CURRENT-MATTERS-TARGET-ROUTING] 修正当前要事角色路由`。
