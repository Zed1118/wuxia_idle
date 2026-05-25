# P1.2 §12.1+§12.2 江湖恩怨 + 声望 全 4 batch closeout · nightshift T17(B1+B2)+ T17b(B3+B4)

## TL;DR(5 行)
P1.2 全 4 batch 完整闭环 · 跨 2 nightshift dispatch(T17 budget exceeded 后 T17b retry)·
4 commit · baseline +23 测(B2 已有 18 + B3 R4 5 + B4 R5 18)· 0 analyze warning ·
1.0 整体 78→85% 跳档 · UI(ReputationPanelScreen)+ battle(bakeEnmityMultipliers)双 wired ·
真 NPC mapping 留 1.1 时挂 StageDef.npcId schema 扩。

## Commit timeline
| Batch | SHA | Origin | 内容 |
|---|---|---|---|
| B1 schema | `68c816d` | T17 nightshift | Reputation/NpcRelation Isar + numbers.yaml jianghu + factions.yaml + stages/encounters extend |
| B2 service | `ed0f862` | T17 nightshift | ReputationService + NpcRelationService + EncounterIntegration(applyOutcome reputationApplier) |
| B3 UI+battle | `581db75` | T17b nightshift | ReputationPanelScreen + ReputationTierChip + main_menu 17 入口 + battle_providers.bakeEnmityMultipliers async helper |
| B4 R5+closeout | `<this>` | T17b nightshift | R5 18 测族(R5.3 红线 / R5.4 trigger / R5.5 label / R5.6 schema / R5.7 helper)+ closeout doc |

## R5 测族结果(B4)
- R5.3 §5.4 红线 ≤ 8000 普伤 enmity 1.25 fixture · 3 测(clamp_max 契约 + 双向对等 + 实测 clamp)
- R5.4 trigger 数值 e2e · 4 测(stage_boss_kill_delta=5 / rival_delta=3 / encounter ±8 / applyDelta e2e)
- R5.5 §5.2 七阶 label 锁 · 3 测(7 阶顺序 + UiStrings 同步 + 区间无 gap)
- R5.6 P3.4 schema 隔离 · 3 测(ReputationSchema name 不撞 + NpcRelationSchema 独立 + 双 collection 并存)
- R5.7 bakeEnmityMultipliers helper · 5 测(双向对等 + max-across + noop + negative id + empty)
- 全 18 测过(`flutter test test/features/jianghu/jianghu_r5_test.dart` ✅)

## 工作量复盘
- spec 估 ~7h xhigh(`docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md` 全 4 batch)
- 实际 wall time:T17 ~50 min(B1+B2 cherry-pick · budget 8 USD 耗尽截断)
  + T17b ~30 min(B3+B4 · budget 15 USD 充足)
- 收口 ratio ~0.2(估 vs 实)· 跨 2 batch 拆分是 T17 budget 不够触发的必要 retry,
  非 spec 估算偏差。

## 挂账(下波)
- Q3 C 心法触发(留 1.1):武林大会 / 比武招亲 等多 NPC encounter delta 公式
- Q4 D 援军 stage(留 1.1):同盟 NPC 出场参战 stage 类型扩
- Q5 C 双轴(留 1.1):声望 × NPC 关系 cross-product UI(矩阵视图)
- Phase 5 narrative 江湖 encounter 完整文案 8-12 条留 1.1
- **StageDef.npcId 真 NPC schema 实装**(本 task 字符串占位 · 1.1 接入后
  bakeEnmityMultipliers 自动接 real NPC mapping · 无 strategy 改)
- factions.yaml 进 NumbersConfig 后 ReputationPanelScreen 显门派中文名
  (当前显 factionId 英文 id)

## 不变量沿用
- §5.4 红线 ≤ 8000 普伤(R5.3 enmity 1.25 单维度 + T20 cross_system_damage_test 跨维度
  audit 双校验)
- §5.3 七阶锁(R5.5 校验 7 阶顺序 + label + 区间无 gap)
- §5.5 在线=离线 · §5.1 反留存(本 task 不引入任何留存机制)
- BattleStrategy / DamageCalculator 0 改(bakeEnmityMultipliers async helper 在
  battle setup 阶段 SET BattleCharacter.attackPowerMultiplier,既有 P3.1.B 末端乘项
  自动接管,strategy 内部不感知 enmity 语义)
- founder_buff_service 0 改(P1.1 候选 2 已 ship · 与 jianghu 解耦)
- factions.yaml 与 encounters.yaml 通过 factionId 弱联(加载层不强校验,Service 端
  ReputationService.tierOf 兜底中间档 yiLiu)
