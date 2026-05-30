# P5.2 敌人内力按境界对称化 · 设计 spec

**日期**：2026-05-30 · **模型**：opus xhigh · **状态**：设计已拍板，待 writing-plans

## 背景 / 目标

敌人内力当前是**扁平常量 1000**（`numbers.yaml enemy_defaults.internal_force`），与境界无关。内力在战斗中**不恢复、只随放招单调递减**（唯一变化点 `default_ground_strategy.dart:281` 扣 cost），故**开局内力 = 全场预算**。结果：武圣境界终 Boss 也只有 1000 内力，传说神功大招（cost 1600）/ 失传神功大招（cost 1100）永久放不出（`battle_ai.dart:105` 门控 `currentInternalForce < internalForceCost`）。

**目标**：敌人内力改为按境界（realmTier+realmLayer）查表对称化，让进阶 Boss 招牌大招能放、ceiling 难度随境界自然上升。承接 #4⑤ ceiling 取舍 + B1 真杠杆。

## Phase 0 诊断（事实，含行号）

- **EnemyDef**（`lib/data/defs/stage_def.dart:195-241`）：已有 `realmTier` + `realmLayer`，**无内力字段**。
- **取值点**（`lib/features/battle/application/stage_battle_setup.dart:283-296` `_enemyToBattle`）：`maxInternalForce = currentInternalForce = enemyDefaults.internalForce`（满开局 1000）。
- **EnemyDefaults**（`lib/data/numbers_config.dart:1101+`）：仅 `internalForce / criticalRate / evasionRate`；`internalForce` **仅 2 caller**（上述 292-293），改查表后即死字段。
- **查表 API 现成**：`GameRepository.getRealm(RealmTier, RealmLayer)`（`game_repository.dart:1314`）→ `RealmDef.internalForceMax`。
- **覆盖**：stages.yaml `realmTier` 118 次 = `realmLayer` 118 次 → 所有敌人均配 layer，查表零 null 风险。
- **红线**：`numbers.yaml red_lines.internal_force_max: 15000`；RealmDef 本身 `_enforceRedLines` 已 clamp ∈ [500,15000]。
- **大招 cost**：失传 ult 1100 / 传说 ult 1600（`data/skills.yaml`）。

### 玩家内力梯度（RealmDef，对称化直接复用）

| 境界 | 首层 qiMeng | 末层 dengFeng |
|---|---|---|
| 学徒 xueTu | 500 | 1100 |
| 三流 sanLiu | 1200 | 2000 |
| 二流 erLiu | 2200 | 3500 |
| 一流 yiLiu | 3800 | 5700 |
| 绝顶 jueDing | 6000 | 9000 |
| 宗师 zongShi | 9500 | 12500 |
| 武圣 wuSheng | 13000 | 15000 |

→ stage_06_05 西凉霸主（武圣·qiMeng）对称化后内力 **13000**，传说大招 1600 可放 8 次。

## 设计决策（用户拍板）

1. **取值公式 = 纯查表对称 ×系数**：`敌人内力 = RealmDef.internalForceMax[tier][layer] × internal_force_scale`（numbers.yaml 新增系数，默认 1.0 = 平衡旋钮）。不动 EnemyDef schema。
2. **开局内力 = 满开局**：`current = max`，沿用现状语义。

## 改动集（最小，纯查表）

| # | 文件 | 改动 |
|---|------|------|
| 1 | `data/numbers.yaml` enemy_defaults | 删 `internal_force: 1000`，新增 `internal_force_scale: 1.0`（注释标语义：敌人内力相对同境界 RealmDef.internalForceMax 的全局缩放） |
| 2 | `numbers_config.dart EnemyDefaults` | `internalForce: int` → `internalForceScale: double`（fromYaml 读 `internal_force_scale`）；`fromYaml` 加范围校验 scale ∈ (0, 2] 否则 throw |
| 3 | `stage_battle_setup._enemyToBattle` | `final realm = GameRepository.instance.getRealm(enemy.realmTier, enemy.realmLayer);` → `final enemyIf = (realm.internalForceMax * enemyDefaults.internalForceScale).round().clamp(0, redLines.internalForceMax);` → max=current=enemyIf |
| 4 | 红线 | clamp ≤ 15000 兜底（系数 >1 时防越界）；scale 范围校验在 #2 fromYaml |

## 测试矩阵

- **查表锚点**：构造学徒/二流/武圣敌人 → 内力 = 对应 RealmDef.internalForceMax（500 / 2200 / 13000）。
- **scale 生效**：scale=0.5 → 武圣敌人内力 6500；scale=1.0 默认。
- **clamp**：scale=2.0 + 武圣 dengFeng(15000) → clamp 15000 不越红线。
- **Boss 能放大招**：武圣 Boss 内力 13000 ≥ 传说大招 cost 1600（语义回归，对比改前 1000 < 1600 放不出）。
- **fromYaml 校验**：scale=0 / 负 / >2 → throw。
- **回归**：现有 stage_battle_setup / battle / mass_battle 测试全绿。

## 数值平衡验收（关键，TDD 之外）

实装 ×1.0 后跑 balance_simulator，对比 baseline `test/tools/output/balance_summary_2026-05-29.md`：
- 看 floor / ceiling / on-level 三 bracket 胜负与 tick。
- **风险**：武圣 Boss 满内力 13000 + 不恢复 → 首回合即可放 8000 倍率传说大招，可能秒杀 floor 玩家。
- **若过强**：① `internal_force_scale` 整体下调；② 针对 stage_06_xx 调敌人 realmLayer 或大招 cost。**per-stage 不预先手配，sim 驱动微调**。
- 低境界敌人内力反降（学徒 1000→500），招式 cost 低无负面。

## 验收标准

1. flutter test 全绿（baseline 1581 + 新增查表/scale/clamp/Boss 测）。
2. flutter analyze 0。
3. balance_simulator 复跑产出新 summary，floor 玩家不被进阶 Boss 首回合秒杀（或记录 scale 下调决议）。
4. 武圣 Boss 战斗日志可见传说/失传大招实际施放。
5. 红线 ≤15000 不破。

## 非目标 / YAGNI

- 不加 EnemyDef per-enemy 内力字段（违「不硬编码」+ 易漂移）。
- 不做敌人内力战斗中恢复机制（沿用单调递减语义）。
- 不预先逐 stage 手配（sim 驱动）。
