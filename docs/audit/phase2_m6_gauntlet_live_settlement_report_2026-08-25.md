# P2-M6 断魂庄亲战结算报告闭环审计

## 交付身份

- 任务：`P2-M6-GAUNTLET-LIVE-SETTLEMENT-REPORT`
- 基线：`8671f8920a9e2ef3cd7bf869a047808d0fd742b1`
- 分支：`codex/phase2-m6-gauntlet-live-settlement-report-20260825`
- 代码/语义复核候选：`444d0b2dcf0b79e6e0db2f1678f4c3175d2176ac`
- 状态：`ready_reviewed`

## 生产语义

- 断魂庄 live controller 与 headless runner 都从同一 Phase 0A 终态、语义事件和实际单人 ID 生成 `CombatSettlementSnapshot`，不新建 reducer/session/结算真相源。
- `GauntletService` 在推进关次的同一事务内核验 run 成员、HP 检查点、装备归属和心法实体，再调用共享 `CombatResolutionService`；装备 `battleCount` 与招式使用只写入实际参与者。
- 逐关共享结算显式禁用伤势写入，也不传 `stageDef`；断魂庄原会话末伤势、经验、领悟、奖励、补给和三选一仍是唯一真相源。
- 胜利奖励页从 active run 和 `Character` 真表展示实际亲历者；单人身份悬空或重复时 fail closed，不回退掌门。旧多人待选奖存档保持可恢复。
- 随机源由生产 `rngProvider` 注入 service，不存在方法体内 `DefaultRng` 绕过测试覆写。

## 红绿与验证

- 初始 RED 在 3 个目标测试文件中因缺少 settlement/参与者 API 编译失败；实现后定向 `25/25 PASS`、断魂庄/入口/相邻生产域 `219/219 PASS`、奖励报告双视口 `2/2 PASS`。
- scoped analyze 与根应用边界 `flutter analyze lib test` 均 `0 issue`；无参数根 analyze 的 1943 项来自独立 nested package `tools/phase0minus_probe` 未安装自身依赖，未冒充根应用结果。
- 候选全量 `flutter test` 最终 `5532/5532 PASS`，墙钟 `4:51`；`git diff --check` 与白名单通过。
- 第一轮全量暴露 3 项集成返工：2 处前序九霄塔源码契约仍断言旧变量名，1 处为本切片 inline `DefaultRng` 的真实回归；均修复、串行转绿并由最终全量覆盖。
- 主控最终检查实际 diff、产线、fail-closed 与双重结算边界：`P0=0 / P1=0 / P2=0`。Luna/high 只用于开工时的只读缺口审计，它找到共享账本断点并缩短关键路径，不冒称最终独立复审。

## 结果驱动记录

- 验收门变化：断魂庄亲战共享账本与参与者报告必要生产子门 `WIP 0/1 → READY 1/1`；M6 顶层仍 `WIP`。
- 可观测耗时：WIP 登记 `14:34`，生产、回归、返工与治理收口约 `15:13`，约 39 分钟，未到 120 分钟上限的 50% 检查点。
- 可观测用量：无可靠周用量读数，未伪造百分比；只记墙钟、最终验证和 3 项集成返工。
- 这是新工作流第 4 个可比 gate；任务风险面不同，仍不宣称 40%-70% 效率提升。

## 边界与未关闭项

- 本结论只关闭“断魂庄实际单人的 live/headless 终态进共享战斗账本，胜利报告显示该人”子门，不代表完整断魂庄、M6 或二阶段完成。
- 轻功/守城仍固定掌门且没有逐次选人/实际参与者报告；M6 “亲战/差遣→结算→报告”顶层闭环仍待其他生产入口收口。
- 未修改 schema/saveVersion、YAML、`TUNING/candidate`、数值、奖励、经济、解锁、叙事、战斗规则或 main。
