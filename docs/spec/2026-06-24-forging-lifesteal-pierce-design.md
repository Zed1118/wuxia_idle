# 开锋吸血(lifesteal)/破甲(pierce)接通战斗 · 设计 spec

> **来源**：全系统审计 A1（`docs/audit/full_system_audit_2026-06-24.md`）——开锋槽吸/破词条玩家可 forge 但战斗零消费。
> **方向**（用户拍板）：接通进战斗，补全 GDD §6.5 开锋 build 深度。specialSkill 单列（见末尾）。
> **基线**：HEAD `0ca48b4f`，saveVer `0.28`。**不改数值**（沿用 numbers.yaml 现配），只接公式 + 战报。

## 1. 背景与现状

GDD §6.5 开锋 3 槽：+10/+15 选「攻/速/吸/破」，+19 专属技能。"同一把剑可走破甲流也可走吸血流"。
- **现状缺口**：`derived_stats.dart:222` `_forgingBonusPct` 只 switch `attack`(:200)/`speed`(:216)；`lifesteal`/`pierce` 解析进 `ForgingSlot` 但 battle 全链零消费（`battle_state.dart:337` 组装 availableSkills 不含 forgingSlots；damage_calculator.dart:274 注释自承"为后续吸血/破甲扩展"）。玩家槽1/2 能真选吸/破、占槽、战斗无效。
- **数值现配**（`numbers.yaml:612-634`，不改）：槽1(+10) `bonus_value` 吸血 10 / 破甲 15；槽2(+15) 吸血 15 / 破甲 20。语义=百分比（沿用 `_forgingBonusPct` /100 体例）。

## 2. 设计决策（已拍板）

| 项 | 决议 |
|---|---|
| **破甲穿透语义** | **A 绝对减**：`有效防御率 = max(0, 防御率 − Σpierce)`。武圣 35% 防御被破甲 20% → 15%。直观、贴高防硬目标 |
| **吸血回血** | `回血 = 该次攻击实际主伤害 × Σlifesteal%`，clamp `min(maxHp, currentHp+heal)`。基于实际伤害故暴击/克制/破甲后自然放大；**震伤等附加固定伤害不计入** |
| **闪避/AOE/死亡** | 被闪避(0 伤害)→0 回血；AOE 每命中分别回；阵亡攻击者不触发 |
| **叠加** | pierce/lifesteal 均**攻方全身装备**(武器/护甲/饰品)对应槽 `bonus_value` 求和。槽1/2 不同类型→每件最多各 1，3 件 → pierce 最大 Σ60% / lifesteal Σ45% |
| **战报** | 吸血「吸血 +N」+ 破甲「破甲」标记，均进战报（battle_log/EnumL10n/UiStrings 合法 sink），与克制/暴击标记对称 |

## 3. 接入点与数据流

### 3.1 派生属性（`derived_stats.dart`）
新增跨全装备聚合函数（区别于单件 `_forgingBonusPct`）：
```dart
static double forgingPiercePct(List<Equipment> equipped, NumbersConfig n)
static double forgingLifestealPct(List<Equipment> equipped, NumbersConfig n)
```
遍历 `equipped` 各 `forgingSlots`，`unlocked && type==pierce/lifesteal` 累加 `bonusValue/100`。复用 `_forgingBonusPct` 的"仅 unlocked 计入"语义。

### 3.2 破甲 → `damage_calculator.dart`
- `calculateResolved` 新增参数 `double attackerPiercePct = 0.0`（默认 0 零回归）。
- 防御率项(:175)：`final defMult = 1.0 - max(0.0, defenderDefenseRate - attackerPiercePct);`
- `calculate()` facade + `AttackContext` 默认传 0；战斗调用方（`default_ground_strategy` 等组装 AttackContext 处）从 `attacker.equippedList` 算 `forgingPiercePct` 传入。
- **不影响招式级 `piercesDefense`**（布尔全穿透，独立路径，:217 段不动）。

### 3.3 吸血 → `battle_resolution.dart`（application）
- 攻击结算后（拿到 `attackResult` 实际主伤害），若 attacker 存活且 `forgingLifestealPct>0`：
  `heal = (实际主伤害 × lifestealPct).floor()`，`attacker.currentHp = min(maxHp, currentHp+heal)`，写回 BattleState（copyWith）。
- AOE 多目标循环内每命中累加 heal；被闪避命中 heal=0。
- 回血量记入 actionLog 供战报展示（不写 BattleState 额外字段，沿 actionLog 体例）。

### 3.4 战报（battle_log）
- 吸血：攻击行动 description 附「吸血 +N」（N>0 才显）。
- 破甲：`attackerPiercePct>0 且 defenderDefenseRate>0`（实际削了防御）时附「破甲」标记。
- 文案进 EnumL10n/UiStrings/battle_log 合法 sink，不散写。

## 4. 红线验证
- `test/balance/full_build_damage_redline_test.dart`：满破甲 build（3 件 Σpierce60%）calculator 探针——武圣 35% 防御清零、伤害 +54%（13.5万→~21万），**硬断言不进百万**。
- `test/tools/balance_simulator_test.dart`：极值×周目诊断不退步、不进百万。
- 吸血不加伤害、回血 clamp maxHp 不绕 hp 红线。

## 5. 测试清单（TDD）
1. `derived_stats`：forgingPiercePct/LifestealPct 求和——单件/多件/0 槽/未解锁槽不计/混合类型。
2. `damage_calculator` 破甲：绝对减正确 + `max(0,...)` 下界（pierce>防御率→0）+ 默认 0 零回归 + 不动招式级 piercesDefense。
3. `battle_resolution` 吸血：回血=实际伤害×%、clamp maxHp、闪避 0 回、AOE 每命中、阵亡不回。
4. 红线：full_build_damage_redline 满破甲探针 + balance_simulator 不退步。
5. 战报：吸血 +N / 破甲标记按条件出现。

## 6. specialSkill 边界（本 spec 不含 · 单列 backlog）
槽3 specialSkill 当前全装备 `specialSkillCandidates` 为空（`forging_panel.dart:28`，UI 显示「该装备无专属技能」，玩家 forge 不上）= 系统未启用，非暴露无效。接通需：① 为装备设计专属技能内容 + `EquipmentDef.specialSkillCandidates` 配置；② `battle_state.dart:337` availableSkills 接入 forgingSlots specialSkillId；③ UI 空状态解除。范围含内容设计，独立 spec，登记 backlog。

## 7. 影响面
- 改：derived_stats（+2 函数）/ damage_calculator（+1 参数 +防御率项）/ battle_resolution（吸血回血）/ battle_log（2 标记）/ AttackContext 组装处。
- 不改：numbers.yaml 数值 / 招式级 piercesDefense / saveVer（无新持久化字段，actionLog 非持久）。
- 零回归保障：新参数默认 0、新函数加性，未开锋吸/破的装备行为不变。
