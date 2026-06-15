# Session 交接 - P3 战报失败诊断系统

**时间：** 2026-06-15 19:12
**项目：** 挂机武侠
**分支：** main
**最后 commit：** 6a32901a

## 本次完成

可玩性二期 backlog「战报诊断规则(§11.4)」打磨项，全闭环合 main（`900938c8..6a32901a`，9 commit）。
brainstorming(3 决策)→spec→plan(6 Task)→TDD 实装→ff-merge。

- 败北单条硬编码提示 → §7.2 三段式失败复盘（1 主因 + 2 数据 + ≤2 跳转建议）。
- 纯函数 `BattleDiagnosis.from(BattleState, BattleReportConfig)` 镜像 `BattleStatsSummary`，
  全 5 类规则优先级有序首条命中即止 + generic 兜底：
  charge(100)/internal_wound(90)/mob_overrun(80)/frontline_fragile(60)/dps_too_low(40)。
- 阈值进 numbers.yaml `battle_report`（4 字段校验）；文案进 UiStrings（退役 `battleDefeatHintInterrupt`）。
- 增强 `VictoryOverlay` 败北路径（不新建 screen）；跳转 skills/equipment/cultivation 叠 overlay
  不打断「继续」；防御式 `_safeDiagnose`（config 未就绪退化 null）。

## 当前状态

1.0 长线打磨期。本任务合 main + **待 push**（origin 还在 4d2e4b6e）。
全量 **2245 测** + 1 skip 零回归 / analyze 0。0 改伤害公式/红线。

## 进行中的工作

- 无。任务闭环。**push 待办**（见下一步 1）。

## 已知问题 / 待验收

- 视觉验收挂账（bg 测不到 GUI，攒一轮真机/Codex）：本任务三段式诊断块排版
  （visual_route_host 已补 `killed_by_charge` 败北诊断态预览样例，路由 VictoryOverlay）。
  仍叠加：M2 被动卡+lifecycle、L3 题字/横幅配色、P1b StageProgressRow 嵌 tile。
- 续9 心魔入口锁（闭关期间禁入心魔）待用户拍板范围。

## 重要决策

- team jump_target 无独立 screen → 涉及队伍的建议只显文案不给按钮（用户拍板）。
- 诊断启发式口径（致命一击=末条有效伤害 / 死亡 tick=累计伤害达 maxHp 的 tick /
  内伤=appliedEffects 含 internal_injury + 带 debuff 阵亡两路或）—— 引导性提示非硬机制，
  误差可接受（用户拍板）。

## 下一步建议

1. **push main → origin**（本 session 未 push，origin 落后 1 任务）。
2. 攒一轮视觉验收（本任务诊断块 + M2/L3/P1b 挂账）——手动或派 Codex。
3. playability backlog 其它无依赖打磨项 / founder_buff 跨派系扩（需拍 B1-B3）。

## 踩坑提醒

- battle_screen 轻量 widget test（`battle_screen_defer_victory_test`）故意不加载 GameRepository，
  `ref.read(numbersConfigProvider)` 会抛「未初始化」→ 用 `_safeDiagnose` try/catch 兜底（本 session
  回归才暴露）。后续在战斗结算路径读 config 都要考虑此测试环境。
- spec/plan：`docs/superpowers/{specs,plans}/2026-06-15-battle-report-diagnosis-*`。
