# Phase 1 纵切切片 2 接管恢复计划

> 日期：2026-08-20
> 分支：`feat/phase1-vs-slice2-mainline-wiring-0820`
> 状态：`WIP / NOT READY`
> 上位规格：`docs/spec/2026-08-19-phase1-vertical-slice-draft-spec.md`

## 目标

让主线 Ch1 五关从真实入口进入 Phase 0A 战斗，并让 0A 的真实末态驱动结算、奖励与进度保存；完成 live/headless 胜负与末态 HP 一致性验证。正式原子切换与旧 3v3 拆除不在本切片内。

## 2026-08-20 接管审计结论

现有代码已完成灰度门、主线宿主、真实 roster 与入口分流的基本骨架，方向符合 Phase 1 纵切规格，但尚未达到可合并状态：

1. `runStageFlow` 在 0A 胜利后仍由 `applyVictoryResolution` 读取旧 `battleProvider` 的 `BattleState`。0A 宿主没有把末态写入该 provider，真实奖励、战斗统计与成长结算因此没有由本场 0A 结果驱动；现有测试只证明了进度回调被调用。
2. `Phase0aMainlineGate.shouldUsePhase0a` 当前放行全部 `StageType.mainline`，超出已拍板的 Ch1 五关范围。
3. live 宿主把 `fixedDeltaSeconds` 写成 Dart 常量 `0.1`，未消费配置真相源。
4. 尚无 Ch1 五关 live/headless 的胜负 + 末态 HP 双跑一致性测试，也无真实 Isar 奖励/进度/退出零污染 e2e。
5. UI 改动尚未完成 1280×720 / 1440×900 smoke 与帧时间验证。

全量测试的两条现状红已定位为裸 `Random` 构造与 Phase 0A 表现层中文诊断串；接管时已按既有注入点/英文诊断口径修正，不代表上述主链缺口已解决。

## 实现切片

1. 先定义引擎无关的主线结算输入，至少承载胜负、参战角色、末态 HP、技能使用与统计；旧 3v3 和 Phase 0A 各自适配，禁止让新入口伪读旧 `battleProvider`。
2. 让 `Phase0aMainlineBattleHost` 回传可结算的真实终局快照；`runStageFlow` 只消费本场返回值。
3. 把灰度门收窄为 Ch1 五关，并补非 Ch1 主线、塔、空敌队等反例。
4. 把 fixed delta 移入 `phase0a_arena` 强类型配置，live/headless 共用。
5. 补真实 Isar e2e：胜利写奖励与进度；战败、重试放弃、系统返回均零进度/零奖励污染。
6. 参数化跑 Ch1 五关 live/headless 同 seed，断言胜负与双方末态 HP 一致。
7. 完成双视口视觉 smoke、帧时间验证、targeted + analyze + 批末全量。

## 验收清单（CLAUDE.md §8.2）

- [ ] 生产入口：真实主线 Ch1 → 0A → 结算 → 奖励 → 进度保存全链成立。
- [ ] Targeted tests：灰度门、宿主、结算 e2e、live/headless 一致性逐文件通过。
- [ ] 红线：数值与 fixed delta 均来自 YAML；无中文文案散写；在线/live 与 headless 同核。
- [ ] UI：1280×720、1440×900 无溢出，键盘/焦点/鼠标语义不回退。
- [ ] 残留风险：Windows 实机 Gate 与六人主观 Gate 仍按上位路线 C 依赖锁死，不在本切片冒充完成。

## 当前恢复点

- 状态：WIP，禁止合并，分支 tip 不打 `[READY]`。
- 最后完成：新增引擎无关 `CombatSettlementSnapshot`；旧 `BattleState` 经适配继续零行为变化；`applyVictoryResolution` 可显式消费本场快照并只结算真实参战者。
- 下一步：让 Phase 0A controller/headless 累积同源事件，由 adapter 生成真实终局快照并随宿主退出返回。
- 已跑验证：结算红测先因缺类型/参数编译红；实现后 `apply_victory_resolution_test` 13 pass，旧结算/心魔/伤势/统计/英雄镜头定向组 57 pass。
- 阻塞项：无新增用户拍板；工程上被真实结算链缺口阻塞。
