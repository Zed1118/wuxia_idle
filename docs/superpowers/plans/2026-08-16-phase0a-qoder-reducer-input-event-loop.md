# Phase 0A 确定性 reducer / 输入 / 事件闭环计划（Qoder）

## 目标

在根应用完成第二批最小生产域闭环：`lib/features/battle/domain/phase0a/` 纯 Dart 不可变模型 + 单一 reducer，玩家与 AI 适配器经同一 intent 协议进入同一结算入口，输出携带运行时结算结果的语义事件；`lib/features/battle/application/phase0a/` 薄会话/适配层只编排不复制规则。不接 UI、不复用旧 3v3、不引入 probe 代码/依赖。

依据：派单 `docs/dispatch/packages/2026-08-16_phase0a_qoder_reducer_input_event_loop.md`；接线审计 §4-§6；反馈契约 `docs/spec/2026-08-16-phase0a-production-feedback-contract.md`。

## 分支

`feat/phase0a-qoder-reducer-input-event-loop`（本 worktree）。

## 验收标准（§8.2 转 checklist）

- [x] 生产接线证据：`application/phase0a` 会话真实 import 并消费 domain reducer；测试从会话入口穿透 adapter→resolver→reducer，不只测 fixture helper。入口 = `Phase0aCombatSession.advance`。
- [x] 统一输入协议：移动/普攻/Q 聚怪/R 清场同一 sealed intent；玩家与 AI 无两套结算入口。
- [x] 确定性：相同初态 + 相同输入序列回放 → 相等状态与相等事件序列（含 seq/tick）；稳定排序（距离→id）、按 seq 单调去重。
- [x] 事件携带运行时结算结果（resolvedDamage / remainingHealth / cooldownRemaining / qiCurrent / qiRequired），字段与冻结反馈契约一致，强类型无 `Map<String, dynamic>`；合法未命中不伪造 hit；死亡仅一次。
- [x] reducer 无调优数值默认值：deltaSeconds / 范围 / 角度 / 环半径 / 真气消耗 / CD 全部调用方显式传入；伤害走显式注入 resolver（本片固定实现，未来生产接 `DamageCalculator`），adapter/reducer 无第二套公式。
- [x] 红测覆盖项：回放相等 / 双源同 reducer / 对角归一 / 最近目标同距 id 决胜 / 命中未命中与伤害余血 / 死亡仅一次 / Q 环内不推环外投影与逐目标 outcomes / R 稳定顺序 / CD·真气不足拒绝与 ready·cooldown·qi 运行态 / 冷却边界归零 / 源码契约（禁 Flutter·Flame·probe·旧 BattleState/BattleAI·数值默认值）。
- [x] targeted tests 逐目录记录通过数；首片 24 项回归绿；probe `combat_rules_test.dart` 8 项对照绿。
- [x] `dart format` 干净；`git diff --check` 干净；根 `flutter analyze --no-pub` 0 issue。
- [x] 一次局部破坏证明测试有判别力（改坏→红→复原→绿），恢复点留痕。
- [x] 红线自查：零 YAML / schema / saveVersion / 数值公式变化；不触三系、在线=离线、反主流项；Dart 无中文文案/调优常量散写。
- [x] commit 中文动宾小切片；tip `[READY]`；worktree 干净。

## 任务切片

1. **S1 计划落档**（本文档）。
2. **S2 红测先行**：`test/features/battle/domain/phase0a/phase0a_reducer_test.dart`、`test/features/battle/application/phase0a/`（适配器 + 会话入口测）、扩源码契约测到 application 目录与 BattleState/BattleAI 禁令；记录编译红。
3. **S3 domain 实装**：模型/intent/事件/reducer（`phase0a_combat_model.dart` / `phase0a_combat_intent.dart` / `phase0a_combat_events.dart` / `phase0a_combat_reducer.dart`）；reducer 测转绿。
4. **S4 application 实装**：玩家适配器、敌 AI 适配器、会话层；全部测转绿。
5. **S5 证红**：局部破坏一行（如聚怪环判定或稳定排序）→ targeted 红 → 复原 → 绿。
6. **S6 冻结**：format / diff --check / analyze / targeted + 首片 24 + probe 8 / 更新恢复点 / `[READY]` commit。

## 停止条件（触发即停，写恢复点 [BLOCKED]）

- 统一 intent 无法表达 Q/R outcomes → 冻结并举证。
- 必须修改既有数值/结算 API 才能继续 → 冻结并举证。
- 需要 UI / 真实 `DamageCalculator` / 胜负存档接线 → 记残留风险，不顺手实装。

## 残留风险（本片不做，仅登记）

- 未接 UI 与生产战斗入口；resolver 为接口预留，未接真实 `DamageCalculator`。
- 无胜负结算/存档、无真气回复机制、无精英 telegraph/破招链入 reducer（首片规则函数已备）。
- 玩家生命归零仅停止敌方攻击判定，battle_defeat 事件与终局结算归后续片。

## 当前恢复点

- 状态：首轮返修已冻结待评审（tip `[READY]`，worktree 干净）。
- 返修依据：`docs/dispatch/packages/2026-08-16_phase0a_qoder_reducer_followup.md`，只修两项、不扩范围。
- 返修落点：
  - 必修1 Q/R 显式作用半径：`Phase0aGatherIntent` / `Phase0aClearIntent` 新增 required `effectRadius`；reducer 仅对距 caster ≤ effectRadius 的存活敌对单位结算（闭区间），范围外不入 outcomes/不被拉拢/扣血/失衡/死亡；`ringRadius` 仍只决定 Q 落点；`ringRadius > effectRadius` 按 CD/真气同规则静默拒绝（无事件、不耗气、不动 CD）；玩家适配器新增 required `gatherEffectRadius` / `clearEffectRadius` 并透传，无默认值。
  - 必修2 同拍刷新技能印：`_tryCastSkill` 不再预置 availability；施放成功后同拍按槽序对**全部**技能槽重算 `availabilityOf`，施放槽 ready→cooldown、余气不足槽 ready→qi 同拍各发一次真实迁移，下一空拍不重发；payload 携带 cooldownRemaining / qiCurrent / qiRequired。
- 证红记录（返修）：① 红测先行 tip `bc67fd86`——新测引用不存在的 `effectRadius` 编译红；② 实现后 64/64 全绿。首上证红（同距决胜翻转）留痕见 git 历史。
- 已跑验证（2026-08-16，返修）：
  - 逐文件 targeted：规则 20 + 契约 8 + reducer 27（+5 新测）+ 会话 9 = 64/64 pass。
  - 首片 24 回归（规则 20 + 契约原 4）含于上行，绿。
  - probe 对照 `tools/phase0minus_probe` → 8/8 pass；根 `flutter analyze --no-pub` → No issues；`dart format` / `git diff --check` 干净。
- 禁区自查：返修仅改 intent / reducer / 玩家适配器与对应测试（4 文件），未触首单禁区外任何文件。
- 阻塞项：无。残留风险不变（未接 UI / 真实 DamageCalculator / 胜负结算存档 / 精英 telegraph 链）。
