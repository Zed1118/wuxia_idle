# Phase 1 纵切切片 2 接管恢复计划

> 日期：2026-08-20
> 分支：`feat/phase1-vs-slice2-mainline-wiring-0820`
> 状态：`READY / WAITING FOR MERGE`
> 上位规格：`docs/spec/2026-08-19-phase1-vertical-slice-draft-spec.md`

## 目标

让主线 Ch1 五关从真实入口进入 Phase 0A 战斗，并让 0A 的真实末态驱动结算、奖励与进度保存；完成 live/headless 胜负与末态 HP 一致性验证。正式原子切换与旧 3v3 拆除不在本切片内。

## 2026-08-20 接管审计结论（均已处置）

现有代码已完成灰度门、主线宿主、真实 roster 与入口分流的基本骨架，方向符合 Phase 1 纵切规格，但尚未达到可合并状态：

1. ✅ `CombatSettlementSnapshot` + 双引擎 adapter 已落地；0A 真实末态显式驱动奖励、统计、成长与伤势结算，不再回读旧 provider。
2. ✅ 灰度门只放行 `stage_01_01..05` 的一周目。
3. ✅ fixed delta / 最大战斗秒数迁入 `phase0a_arena.simulation` 并强校验，live/headless 同源。
4. ✅ Ch1 五关同 seed 的胜负、事件与末态 HP 一致；真实 Ch1 → headless → Isar 奖励/经验/伤势全链通过；中途退出零污染。
5. ✅ 1280×720 / 1440×900 主线 Boss 宿主 smoke、Phase 0A 双视口表现组与 0C 50 次进退/暂停/缩放组通过。

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

- [x] 生产入口：真实主线 Ch1 → 0A → 结算 → 奖励 → 进度保存全链成立。
- [x] Targeted tests：灰度门、宿主、结算 e2e、live/headless 一致性逐文件通过。
- [x] 红线：数值与 fixed delta 均来自 YAML；无中文文案散写；在线/live 与 headless 同核。
- [x] UI：1280×720、1440×900 无溢出，键盘/焦点/鼠标语义不回退。
- [x] 残留风险：Windows 实机 Gate 与六人主观 Gate 仍按上位路线 C 依赖锁死，不在本切片冒充完成。

## 当前恢复点

- 状态：READY；完成收账提交后打 `[READY]` tip，进入合并 Gate。
- 最后完成：灰度门/时钟/结算全链收口；群体技能暴击进入战后统计；双视口与 0C 工程组通过。
- 下一步：合并主线；随后抽离 `StageBattleSetup` 快照职责并规划真实技能映射/Ch1 难度校准。
- 已跑验证：主线接线 15、真实 Isar 结算 14、mapper 12、headless 11、reducer/event/结算/controller/source-contract 相关组均过；`flutter analyze` 0 issue；最终全量 **5207 pass / 0 fail**。
- 阻塞项：分支内无；路线 C 正式替换仍锁六人主观 Gate 与 Windows 实机 Gate。
