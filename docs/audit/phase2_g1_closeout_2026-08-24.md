# P2 G1 整合收口

日期：2026-08-24  
整合基线：`4ad8d3a4eaf5e772a41ad5a20867295f278d2d9c`  
main / origin main：`e292d3a069fbc0e129dd74fafc1ebb3746f53557`

## 结论

G1 的 21 项生产合同已全部 `ready_reviewed`；额外的关键路径事实审计也完成。旧 Batch1/Batch2 只有 registry 状态漂移，最后两个真残项 C11/C12 均有生产实现、定向验证与独立复核。

## C11 · 冷却秒权威

- 用户明确批准推荐方案。
- 261/261 条生产技能同时存在玩家 `cooldownSeconds` 和敌方
  `phase0aEnemyCooldownSeconds`。
- Q/R 保持 5s/8s；其余玩家技能保持当前 `turns × 0.55s`，敌方保持
  `turns × 1.0s`。
- 数字键、敌方阶段技、顶层/阶段蓄力三处 mapper 只读秒字段；
  `phase0a_stage_content_mapper.dart` 对 `cooldownTurns` 零命中。
- READY tip：`4ad8d3a4eaf5e772a41ad5a20867295f278d2d9c`。

## C12 · 三战术生产消费

- 扫荡开跑前显式选择寻隙、强攻或稳守；选择前 runner 零调用。
- typed policy 经 `SweepScreen → SweepUnit → Phase0aSweepHeadlessRunner →
  Phase0aPlayerBotAdapter` 原值透传，不回落默认 `production()`。
- 三战术仍只生成玩家同型 command，共用同一 reducer/headless 核。
- 选择属本次运行，零 save schema、奖励、readiness 变化；不扩大前台主线 bot 准入。
- READY tip：`39ed522804295dfd6b93dbbd867f152d2b7d2ed2`。

## 验证

- C11 核心契约/代表生产链：13/13。
- mapper、脆弱窗口、主线/塔/扫荡/心魔/断魂庄扩展：53/53。
- `test/features/battle/application/phase0a` + `test/data`：1093/1093。
- C12 screen：6/6；runner + adapter：10/10。
- 独立 C11 审查：P0/P1=0；scoped analyze 与 diff check 通过。
- 整合态全量 Flutter 测试：5199/5199。
- 主应用 `flutter analyze --no-pub lib test tool`：0 issue；
  `test/data/truth_source_guard_test.dart`：9/9。
- registry：111 个任务、50 个决策；M1 恰为 22 项且全部
  `ready_reviewed`，任务/决策重复 0，悬空 decision 引用 0，双 YAML 可解析。
- 首轮全量由纸面可读性守卫发现 C12 选择页误用两处暗底文字 token；已改为
  `WuxiaUi.ink/muted` 并补显式 import。纸面审计 + sweep screen 10/10，随后
  全量复跑 5199/5199。

说明：不带路径的裸 `flutter analyze` 会递归进入仓内已退役、拥有独立依赖边界的
`tools/phase0minus_probe` 子包并报其缺包噪声；本批沿项目既有主应用门禁分析
`lib test tool`，不把退役 probe 子包结果冒充 G1 回归。

## 非阻断项与后续门禁

- readable-first-clear 的既有 SkillDef clone 未完整复制
  `mountDeferred/qiDrainPct/phase0aBehavior`；这不是 C11 引入，且不在 G2 唯一关键路径，仅记为 P2。
- Ch1 production catalog 与 `stage_01_03` 黑风岭纵切尚未实施。现有 40/12、
  reinforcement threshold、warning/grace 及 token budget 全是 candidate-only，不得冒充冻结生产数值。
- G2 前不扩面 M3/M4、五武器、其余生态、21 章或 49 塔。
