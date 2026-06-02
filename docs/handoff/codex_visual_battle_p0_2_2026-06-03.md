# P0-2 战斗单位可见化 · Codex@Pen 截图验收派单

分支：`feat/p0_2_battle_visibility`（merge main 后 Pen `git pull`）
目标：把 3v3 自动战斗从「小圆头像 + 220px 日志侧栏」改造为「第一眼看得出谁在打谁」的动作位骨架。
本批纯表现层：放大单位(110) + 玩家立绘接线 + 弹道笔触 + 受击闪 + 日志折叠抽屉 + 胜负遮罩 vignette。**未改 BattleState / 未引 Flame**。

验收路由（dart-define `VISUAL_ROUTE`）：复用现有 `battle_scene` / `battle_boss_frame`。

| # | 验收门 | 期望 |
|---|--------|------|
| 1 | 单位放大可辨 | 我方/敌方各 3 单位头像放大(110)，一眼可辨谁是谁；玩家有立绘显立绘、无立绘显首字水墨占位；敌人显敌人图。 |
| 2 | 战场占满宽 | 日志侧栏已删，战场横向占满；默认无侧栏抢视觉。 |
| 3 | 日志折叠抽屉 | 顶栏右侧有日志按钮(list_alt)，默认收起；点开右侧抽屉显历史，点遮罩/关闭按钮收起。 |
| 4 | 弹道笔触 | 攻击命中瞬间，攻击者→目标出现一条流派色笔触线（普攻细 3 / 大招粗 5），短促渐隐。 |
| 5 | 受击闪 | 被击单位命中瞬间叠一层淡色块（暴击绛红 / 普攻白）快速淡出。 |
| 6 | 大招题字 | 大招仍弹题字 overlay（暖金玩家 / 绛红敌方）+ 弹道更粗。 |
| 7 | 胜负遮罩 vignette | 胜利/失败 overlay 用径向暗角（中心淡四周暗），**战场单位仍清晰可读**，非整屏纯黑。 |
| 8 | 死亡灰化 | 阵亡单位灰度化 + 半透明，明显区别于存活单位。 |
| 9 | 布局/异常 | 1280×720 最低窗口下无 RenderFlex overflow；日志 0 exception/assertion。 |

建议截图：`07_battle_running.png`(战斗中, 弹道+放大单位) / `battle_skill.png`(大招弹道粗+题字) / `08_battle_result.png`(胜利 vignette, 战场可读) / `09_log_drawer.png`(日志抽屉开) / `10_dead_grayscale.png`(死亡灰化)。

注意：弹道/受击为命中瞬间表现，autojourney/READY 后自动结算偏快可能截不到弹道中帧 —— 若如此，用 `VISUAL_STAGE` 抽样或放慢 actionInterval 抓帧；门 4/5 截不到属时机问题非缺陷，代码层已 widget test 覆盖。
