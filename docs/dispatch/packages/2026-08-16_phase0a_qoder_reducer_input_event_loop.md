# Phase 0A 确定性 reducer / 输入 / 事件闭环（Qoder）

## 目标

在根应用 `lib/features/battle/` 内完成第二批最小生产域闭环：同一个纯 Dart reducer 同时消费玩家与 AI 适配器产生的输入，输出已经结算的语义事件；不接 UI、不复用旧 3v3 状态机、不从 probe 引入代码或依赖。

## 基线与必读

- 基线：派单方提供的第二批执行 worktree tip；已包含首片 `phase0a/arena_vector.dart`、`realtime_combat_rules.dart` 与两份生产反馈/资产契约。
- 必读：`CLAUDE.md` §5、§8.0、§8.2、§8.3、§9、§9.1；`GDD.md` §2.1/§5；`docs/spec/rejected_task_registry.md`。
- 必读：`docs/audit/phase0a-production-wiring-audit-2026-08-16.md` §4-§6；`docs/spec/2026-08-16-phase0a-production-feedback-contract.md`。
- 参考旧生产公式边界：`damage_calculator.dart` / `derived_stats.dart`；本片不迁公式、不改数值，只让调用方显式提供已结算伤害。

## 实装边界

1. 先创建 `docs/superpowers/plans/2026-08-16-phase0a-qoder-reducer-input-event-loop.md`（≤150 行），把本单验收逐项写入，恢复点记录命令和通过数。
2. 在 `lib/features/battle/domain/phase0a/` 增加不可变纯 Dart 模型与 reducer：
   - 单角色玩家对多敌的 actor/state；显式位置、朝向、生命、真气、移动速度、技能运行态；
   - 同一输入协议覆盖移动、普攻、Q 聚怪、R 清场；玩家与 AI 不得有两套结算入口；
   - reducer 只接受调用方显式传入的 `deltaSeconds`、范围、角度、环半径、真气消耗、CD、已结算伤害等参数，不提供调优数值默认值；
   - 稳定排序/去重，给定相同初态与相同输入序列必须得到相等状态和相等事件序列；
   - 伤害、死亡、聚怪/清场逐目标结果、技能可用态事件必须携带契约中的运行时结果，表现层无需重算；合法未命中不得伪造 hit。
3. 在 `lib/features/battle/application/phase0a/` 增加薄会话/适配层：
   - 玩家适配器把按键/方向/动作请求转成上述统一 intent；
   - AI 适配器从同一只读 state 产生同型 intent，最近目标/同距稳定 id 决胜；
   - 会话层只编排 adapter → resolver → reducer，不复制移动、命中、扣血、CD 或胜负规则；
   - 伤害 resolver 作为显式注入的纯回调/接口；本片测试用固定 resolver，未来生产接 `DamageCalculator`，禁止在 adapter/reducer 写第二套公式。
4. 语义事件至少覆盖：`attack_started`、`hit_landed`、`enemy_defeated`、`gather_started/applied`、`clear_started/applied`、`skill_availability_changed`。字段与已冻结反馈契约一致；可用强类型字段，不用 `Map<String, dynamic>`。
5. 在 `test/features/battle/domain/phase0a/` 与 `test/features/battle/application/phase0a/` 先写红测，再实现。至少覆盖：
   - 同序列重复回放完全相等；玩家/AI 输入走同一 reducer；对角移动归一；最近目标同距稳定选择；
   - 普攻命中/未命中；伤害数字与剩余血量；死亡仅一次；
   - Q 环内不推、环外投影、逐目标 outcomes；R 多目标稳定顺序；
   - CD/真气不足拒绝，ready/cooldown/qi 运行态字段；冷却边界归零；
   - 源码契约：禁 Flutter/Flame/probe import、禁旧 `BattleState`/`BattleAI` 依赖、禁数值参数默认值。

## §8.2 交付 checklist

- **生产接线证据**：根应用 application 会话真实消费 domain reducer；测试须从会话入口穿透 adapter/resolver/reducer，不得只测 fixture helper。
- **targeted tests**：逐目录/逐文件运行并记录通过数；另跑首片 24 项回归与 probe `combat_rules_test.dart` 8 项对照。
- **红线说明**：零 YAML/schema/saveVersion/数值公式变化；不触三系、在线=离线、反主流项；Dart 无中文文案/调优常量散写。
- **残留风险**：明确尚未接 UI、真实 `DamageCalculator`、胜负结算/存档、精英 telegraph 的范围，不得把它们写成已完成。

## 禁区与停止条件

- 禁改旧 `battle_state.dart`、`battle_ai.dart`、strategy、provider、presentation、生产入口、结算、YAML、GDD、PROGRESS、pubspec、probe、schema/saveVersion。
- 禁引入依赖，禁 push/merge/rebase/revert/碰 main；只写自己的 worktree。
- 若统一 intent 无法表达 Q/R outcomes，或必须修改既有数值/结算 API 才能继续，先冻结 `[BLOCKED]` 并写证据，不得绕开。

## 验证与冻结

- `dart format`；`git diff --check`；新增 targeted tests；首片 24 项；probe 对照 8 项；根 `flutter analyze --no-pub`。
- 用一次局部破坏证明确定性或结算测试有判别力，恢复后再验绿。
- 小切片中文动宾 commit；最终 tip 前缀 `[READY]`，worktree 干净。
