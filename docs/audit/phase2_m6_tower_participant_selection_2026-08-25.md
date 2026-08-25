# P2-M6 九霄塔实际参与者生产纵切审计

## 交付身份

- 任务：`P2-M6-TOWER-PARTICIPANT-SELECTION`
- 基线：`c6c0a6696e68d64efb084f96b9d35cf063d2a711`
- 分支：`codex/phase2-m6-tower-participant-selection-20260825`
- 代码/语义复核候选：`e00181257966ffac51fc9c2747b0b50e096f22e4`
- 状态：`ready_reviewed`

## 生产语义

- 九霄塔每次挑战都从当前掌门与当代存活门人中逐次选一人；成员归属复用 U08 的只读调度真相源，活动状态只读 `CharacterOccupancyService`，不再使用旧全局三席决定塔参与者。
- 选中的同一角色 ID 在真实 `Phase0aTowerBattleHost` 装配前再次复核身份、存活、主修、疗养、活动占用和装备引用，再由 `PlayerCombatantSnapshotAssembler.loadExactRoster` 生成单人快照；任何错人、悬空或重复占用均 fail closed，不回退掌门。
- 胜利与败北均要求 settlement 中恰有该参与者。成长、伤势、装备 `battleCount`、心法使用和角色事件写回实际参与者；塔层首通、掉落、周目、排行榜、Boss 纪念与胜利仪式仍保持存档/宗门共享语义。
- 塔生产路由不再读写 `activeCharacterIds` / `isActive`。扫荡只做共享结算 API 的机械改名，参与者 policy 未改。

## 红绿与验证

- 初始有效 RED：`7 PASS / 2 FAIL`，证明非 active 门人虽进入 settlement 却没有成长，且地点入口仍被其他角色闭关全局阻断。
- 主控语义复核再发现败北 settlement 错人未拒绝、实际败北参与者的战斗账本与伤势未落地；两项守卫修复前均失败，修复后转绿。
- 最终定向集 `40/40 PASS`；塔完整域 `116/116 PASS`；相邻 sweep、江湖地图、U08 调度 `153/153 PASS`，统一占用服务正确路径另 `3/3 PASS`；选人弹窗双视口 `2/2 PASS`。
- `dart analyze lib`、`dart analyze test/features/tower`、`dart analyze test/features/jianghu_map` 和根应用标准边界 `flutter analyze --no-pub lib test tool` 均为 `0 issue`。
- 无参数 `flutter analyze --no-pub` 的其余 1945 项来自独立 nested package `tools/phase0minus_probe` 未安装自身依赖；仓库 CI 明确以 `lib test tool` 为根应用边界。本纵切自身最初两条 lint 已修复，不把 nested package 结果冒充本切片通过或失败。
- 最终全量只运行一次：`flutter test --no-pub --reporter compact`，`5527/5529 PASS`，墙钟 `292.88s`。两条并发失败分别落在未触碰的 `phase0a_mechanics_presentation_test.dart` 与 `pending_jianghu_affairs_screen_test.dart`；两个失败文件随后串行复跑合计 `6/6 PASS`。本审计不伪写为全量全绿，也不重复刷全量。
- 主控最终语义复核 `P0=0 / P1=0 / P2=0`；本轮未启用子 Agent，不把主控复核冒称为独立 Agent 复审。

## 结果驱动记录

- 验收门变化：九霄塔逐次选人与实际参与者战斗结算必要生产子门 `WIP 0/1 → READY 1/1`；M6 顶层四门不由此晋升。
- 可观测耗时：WIP 登记约 `10:29`，完成生产、风险验证与治理约 `11:00`，约 31 分钟，低于 90 分钟上限的 50% 检查点。
- 可观测用量：无可靠周用量读数，未伪造百分比；只记录墙钟时间。
- 集成返工：修正历史代际候选、旧 active 首席掉落预览、败北提前返回、疗养准入和 settlement 错人守卫；最终全量另暴露 2 条未触碰域的并发不稳定，串行复跑全绿。
- 这是新工作流第 3 个可比 gate。三门验证面与全量基线不同，样本仍不足，不宣称 40%-70% 效率提升。

## 边界与未关闭项

- 本结论只关闭“任意 eligible 空闲当代角色可经真实塔 Host 亲战，既有个人战斗账本、成长与伤势归实际参与者”的子门，不代表完整塔模式、U08、M6 或二阶段完成。
- 冻结方案 §9.2 的“每角色塔层个人最好成绩”当前没有持久模型；现有 `TowerProgress` 是每存档单行。因本轮禁止 schema/saveVersion 变更，该项保持 `BLOCKED`，不得用 Boss 纪念或存档级最高层替代。
- 不修改 headless、扫荡参与者、当值历练、schema/saveVersion、YAML、`TUNING/candidate`、数值、奖励、经济、解锁、叙事、战斗规则或 main。
