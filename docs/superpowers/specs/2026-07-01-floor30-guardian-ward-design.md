# floor30 护法结界终局战 · 设计 spec

**日期：** 2026-07-01
**状态：** 已定稿（用户拍板 3 项，见决策史）
**范围：** 仅爬塔 floor30 终关 Boss 战
**关联：** 爬塔复核观察点 ③「终局 Boss 100% 胜偏软」（PROGRESS 2026-07-01 爬塔条 + 06-28 首次记录）

## 1. 背景 / 问题

floor30 现状：3 人敌阵——主 Boss 九霄魔尊（`baseHp 42000` / yinRou / 相位 0.90/0.50 带 chargeCounter）+ 左使（4200 血 gangMeng）+ 右使（4000 血 lingQiao）。

`tower_boss_feel_diagnostic` 诊断：满配 on-level 三人队伤害过高，42000 血 2-5 tick 打穿，相位阈值虽触发但 Boss 已死 → **二阶段沦为装饰**。Boss HP 红线封顶 60000，堆血此路不通；且 06-14 已拍板「极值 build 一回合秒杀终局=有意爽感，不动」——故修的目标只能是 **on-level 常规队的体验**，不是 nerf 强度爽感。

## 2. 目标 / 非目标

**目标**：终局 Boss 达到「软门槛 + 表现层危机感」——欠配队会败、on-level+ 稳过；配相位强控/多目标压迫的演出让战斗「像」凶险；给继续养成的理由 + 终局仪式感。契合挂机爽感主旋律。

**非目标**：不做真机制技巧墙（不要求玩家手动介入才能过）；不 nerf 满配强度爽感；不堆 Boss HP；不改其他关（仅 floor30）。

## 3. 约束（红线）

- Boss HP ≤ 60000（保持 42000 不动）；玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000 不碰。
- 招式倍率全局 ≤8000（施压技走现有 `_enforceEncounterSkillRedLines` enforce）。
- 在线 = 离线：结界是战斗内机制，不碰任何 settle / 离线收益路径。
- 三系锁死：护法/Boss realmTier 不改。
- §5.1 反主流：不引入体力/抽卡/留存机制。
- 中文文案全进 UiStrings / narratives；不硬编码数值（走 towers.yaml / numbers.yaml）。

## 4. 设计

### 4.1 机制核心（护法结界）

主 Boss enemy def 新增 boss 级字段 `guardianWard`：

```yaml
guardianWard:
  damageTakenMult: 0.15          # 结界期间主 Boss 承伤乘子(减伤 85%),初值待校准
  guardianIds:
    - enemy_tower_30_cultist_a    # 左使
    - enemy_tower_30_cultist_b    # 右使
```

规则：
- `guardianIds` 中**任一护法存活** → 主 Boss 承伤 × `damageTakenMult`（叠在现有 `schoolDamageTakenMult` 之后、承伤管线末端）。
- 护法**全部阵亡** → 结界破，主 Boss 承伤恢复 ×1.0；此后现有 0.90/0.50 相位吃满伤正常触发（chargeCounter 读秒圆环真正登场）。
- 护法适度提血（校准值）使「burst 掉护法」成真门槛。护法为敌人 `baseHp`，不受 §5.4 装备/玩家血红线约束。

**挂机友好（已核实，非操作墙）**：玩家默认自动 AI `BattleAI._pickTargetId`（`battle_ai.dart:158`）**集火最低血敌**。floor30 护法 4000/4200 血 << Boss 42000 血 → 全自动时玩家队天然先打护法 → 破界 → 杀 Boss。on-level 满配队全自动即可通过；欠配队 burst 不动护法 + 扛不住施压窗口 → 败。**gear check，非操作/目标选择技巧墙**。

### 4.2 表现层危机感（相位施压折入）

- 结界护罩 overlay + 题字「护法结界·刀枪不入」（复用现有 presentation 基建：screen_flash / 状态标签 / 题字层）。
- 结界窗口内：护法围殴 + 主 Boss 周期群体施压（复用现有 AOE / yinRou 内伤），营造「打不动 Boss、被两护法围殴」危机窗口。
- 破界演出：护法全灭 → 题字「结界破！」+ screen flash + Boss 进相位强控 → 刚上线的读秒圆环（蓄力/破绽/内伤环）承载相位演出。
- 全部走表现层，不进 BattleState 结算红线。

### 4.3 软门槛校准（balance）

- 边界目标：宗师阶 on-level 满配队 **100% 稳过**（不 nerf 爽感）；欠配队（-1 阶 绝顶 / 低强化 / 缺件）会败。
- 用现成 `tower_boss_feel_diagnostic` / `balance_simulator` 跑 2 profile × N seed 验证：on-level 破界时机 + 胜率；欠配 profile 验证会败。
- 调参量：`guardianWard.damageTakenMult`、护法 HP、护法/Boss 施压强度。Boss HP 42000 不动。
- 涉数值走 `[balance]`；初值定后由诊断测校准，本 spec 不钉死具体值。

## 5. schema / 配置

- `guardianWard` 为 towers.yaml floor 主 Boss 可选字段（其他关/其他敌 null）。
- 加载层 schema 校验（fail-fast，仿现有 `_validate*` 范式）：`guardianIds` 引用的 enemy id 必须在本 floor `enemyTeam` 存在；`damageTakenMult ∈ (0, 1]`；`guardianIds` 非空。
- 仅 floor30 使用；他关 `guardianWard=null` → 承伤管线零回归。

## 6. 单元边界（isolation）

- **承伤管线扩展**：结界 DR 作为承伤乘子末端一环，与 `schoolDamageTakenMult` 同层，独立可测。
- **结界状态判定**：纯函数「`guardianIds` 中是否有存活」→ bool，喂给承伤计算，无 side effect。
- **配置层**：`guardianWard` schema + 校验独立于战斗逻辑。
- **表现层**：题字/护罩/破界演出走现有 presentation 基建，不进结算。

四块各有单一职责、明确接口、可独立测。

## 7. 测试策略

- 确定性 seed 战斗测（`ProviderContainer` + 永久 listener + `notifier.advance`，参 memory `feedback_battle_determinism_test`）：on-level seed → 破界 → 胜；欠配 seed → 败（软门槛真实，非只 boost 标签，照 battle e2e 写、实测 leftWin）。
- 结界机制单测：护法存活 → 主 Boss 承伤减；护法全灭 → 承伤恢复；`damageTakenMult` 与 `schoolDamageTakenMult` 叠乘正确。
- schema 校验测：`guardianIds` 悬空 / 越界 / mult 越界 → fail-fast StateError（含坏 id）。
- 红线守护测：Boss HP ≤60000（不变）；仅 floor30 挂结界、他关零回归。
- 全量 `flutter test --no-pub -j1` 回归。

## 8. 实装复杂度 / 风险

- **复杂度**：触碰承伤管线（damage_calculator / default_ground_strategy 承伤末端）+ 战斗状态机（结界态判定接入 tick）+ schema。**建议实装升 xhigh**。
- **风险**：① 承伤末端叠乘顺序需与 schoolDamageTakenMult / 凝甲 defenderCritDamageTakenMult 明确定序（避免双重折扣错算）；② 护法群体施压若过强可能误伤 on-level 队（软门槛偏硬）→ 靠诊断测校准兜底；③ 破界瞬间承伤跳变需与相位 title 演出时序对齐。

## 9. 决策史（本次拍板）

1. 手感目标 = **软门槛 + 表现层危机感**（非硬技巧墙 / 非纯表现层）。
2. 作用范围 = **仅 floor30 终关**（不推广 20/10 major）。
3. 机制方案 = **A 护法结界**（B 相位群体强控作演出层折入；否决 C 狂暴计时 gimmick）。
