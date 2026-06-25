# 一键挂机扫荡 · plan

> design 见 `2026-06-25-one-key-sweep-design.md`。TDD（先红线测后实装）。
> 依赖链：T1/T2/T3 可先行 → T4/T5 抽结算 → T6 驱动 → T7/T8 UI。

## 任务分解

| # | 任务 | 依赖 | 测 |
|---|---|---|---|
| T1 | numbers.yaml `sweep` 段（action_interval_ms / inter_battle_gap_ms）+ NumbersConfig 解析 + schema 校验 + AnimationNumbers 同步 | — | config 解析测 + schema 拒非法 |
| T2 | `SweepEligibility`（forChapter / forTower 纯函数）+ `SweepUnit` 范围枚举 | — | 门槛全分支（部分清不可扫/全清可扫/新周目重置） |
| T3 | `SweepRecap` 累加模型 + `SettlementSummary`（drops/silver/exp/advancements/injuryDelta） | — | recap 聚合 + 累加幂等 |
| T4 | 抽 `StageVictorySettlement.settle`（从 `stage_entry_flow.dart:716 _applyVictoryResolution` 提纯结算副作用·ref-free）；正常 flow 改调它 + shape UI record | T3 | **既有 stage flow 测零回归** + 新 service 单测 |
| T5 | 抽 `TowerVictorySettlement.settle`（塔侧同理） | T3 | 既有 tower flow 测零回归 |
| T6 | `SweepRunner`（驱动 notifier：循环连播/加速 tick/停标志/halt-on-defeat/累加 recap） | T2,T4,T5 | 确定性测（连播N关/中途停/某关败 halt·参 battle 确定性 notifier 体例） |
| T7 | `SweepScreen`（连播进度 X/N + 实时 recap + 醒目停止按钮）+ `SweepRecapDialog`（数字跳动） | T6 | widget 测（进度显/停按钮/recap 渲染·viewport 扩） |
| T8 | 入口按钮（明显主按钮）：主线章节 header `stage_list_screen` + 塔屏顶 `tower_screen`；eligible 才亮·否则灰+tooltip；UiStrings | T2,T7 | 按钮 eligible/灰显 widget 测 |
| T9 | 整合：analyze 0 + 全量测无回归 + 红线（在线=离线/§5.7/数值yaml/文案UiStrings） | 全部 | 全量 flutter test |

## 关键纪律

- **T4/T5 是改既有关键路径**：纯提取、行为零变更，先确认既有 flow 测全绿作 baseline，提取后必须仍全绿（feedback_layered_bugs）。
- **per-level / 数组式无关**；但驱动层加速 tick 注入勿破坏既有 action_interval_ms 正常路径（默认不传 = 正常节奏）。
- **确定性测走 notifier.advance + ProviderContainer + 永久 listener**（feedback_battle_determinism_test_via_notifier），不直接 tick strategy。
- **入口按钮明显**：用 WuxiaUi 主按钮样式（非 icon-only），eligible 高亮。
- 合并回主 checkout 必跑 build_runner（.g.dart gitignored）；提交前撤 build 产物。

## 验收红线

- 扫荡恒重打（不触发首通/不解锁周目）—— 驱动层断言 isFirstClear 路径不进。
- 战败 halt 停在该关 + 报因 —— halt 行为测。
- 掉落走标准 service —— 复用 T4/T5 不新增掉落分支。
