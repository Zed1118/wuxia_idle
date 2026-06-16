# M6 心魔失败惩罚实装 · 设计

**日期**：2026-06-16 ｜ **模型**：opus xhigh ｜ **状态**：设计待审

## 背景

GDD §12.1 设计了心魔关战败惩罚「内力 ×0.85 / 主修修炼度 ×0.9 + 心魔余毒 debuff（闭关 8h 清）」，`numbers.yaml` `inner_demon.failure_penalty` / `residue_debuff` 与 `InnerDemonFailurePenalty` / `InnerDemonResidueDebuff`（`lib/features/inner_demon/domain/inner_demon_def.dart`）已完整定义，但**业务代码零 wire**（2026-06-16 续15 审计证实，GDD §12.1 已加纠偏注）。本设计把它接入战斗结算 + 存档。

现状要点（Phase 0 实测）：
- 心魔关 `StageType.innerDemon`，`isBossStage=false`，镜像敌队由 `InnerDemonService.buildMirrorEnemyTeam` 生成；胜利解锁下一关已实装，**战败无任何副作用**。
- 战后结算在 `BattleResolutionService.resolve()`；现有主线 Boss 散功 `DispelService.applyDefeatPenalty` 仅 `isBossStage=true` 触发。
- 无持久 debuff 设施（`activeBuffs` 仅战斗内瞬时）；闭关 `SeclusionService.computeOutputs` 产出 `internalForcePoints`（可作余毒作用点）。
- 内力 `Character.internalForce` / 上限 `internalForceMax`；主修修炼度 `Technique.cultivationProgress` / 层 `cultivationLayer`，主修由 `Character.mainTechniqueId` 定位。

## 已拍板决策（用户 2026-06-16）

1. **惩罚叠扣**：每次战败都扣 + **地板 cap**（防无限重试归零）。
2. **余毒清除**：**闭关累计满 8h 清**（按 `debuff_clear_via_retreat_hours=8`）。
3. **作用对象**：**全部参战且有主修的玩家角色**（沿用 `applyDefeatPenalty` 的 `participatingCharacters` 先例）。

## 设计

### A. 触发点

`BattleResolutionService.resolve()` 新增分支：`!isVictory && stageDef != null && stageDef.stageType == StageType.innerDemon`。
- 与主线 Boss 散功**天然互斥**（心魔关 `isBossStage=false`），无优先级冲突。
- 胜利路径不动。掉落战败恒空（现状保持）。

### B. 数值惩罚（纯函数）

新增 `InnerDemonService.applyFailurePenalty`（或独立纯函数 + service 编排），对每个参战且 `mainTechniqueId != null` 的角色：

- **内力**：`newIF = max( floor(currentIF × failurePenalty.internalForceMultiplier), floor(internalForceMax × 0.50) )`
  - 系数 0.85 从 `failurePenalty` 读；地板 50% 写入 `numbers.yaml inner_demon.failure_penalty.internal_force_floor_pct: 0.50`（不硬编码，§5.6）。
- **主修修炼度**：`newProgress = floor(cultivationProgress × failurePenalty.mainCultivationMultiplier)`；**`cultivationLayer` 不递减**——"不跌破当前层起点"自动满足（progress ≥ 0、层不掉）。`cultivationProgressToNext` 不变。
- **辅修不动**（`subCultivationMultiplier=1.00`，不实际触碰辅修字段）。
- 返回结构化结果（每角色 before/after 内力 + 主修 progress），供 UI 展示与测试断言。

### C. 心魔余毒 debuff（持久 · 按角色）

- **存档**：`Character` 新增 `double innerDemonResidueHoursRemaining = 0`（0 = 无余毒）。saveVer/schema bump，旧档默认 0 不回溯。
- **施加**：战败结算时对受罚角色设为 `failurePenalty.debuffClearViaRetreatHours.toDouble()`（=8.0）；再败刷新回 8.0（不叠加，上限 8）。
- **战斗输出 ×0.95**：余毒在身角色（`hoursRemaining > 0`）进战斗快照时 `BattleCharacter.outputMultiplier = residueDebuff.battleOutputMultiplier`（默认字段 1.0，零侵入）；`damage_calculator` 最终伤害末端乘。在 `StageBattleSetup.buildTeams` 玩家队快照处接入。
- **闭关内力产出 ×0.80**：`SeclusionService.computeOutputs` 对余毒在身角色 `internalForcePoints × residueDebuff.internalForceRecoveryMultiplier`（=0.80）。
- **清除**：每次该角色闭关收功，`hoursRemaining = max(0, hoursRemaining - actualHours)`；归 0 即清。

### D. 数据流

```
战败(心魔关) → BattleResolutionService.resolve
  → InnerDemonService.applyFailurePenalty(参战角色, 配置)
      → 改 Character.internalForce / Technique.cultivationProgress
      → 设 Character.innerDemonResidueHoursRemaining = 8.0
  → 持久化(Isar 事务)
闭关收功 → SeclusionService: internalForcePoints ×0.80(余毒在身)
        → hoursRemaining -= actualHours, clamp 0
战斗快照 → StageBattleSetup: BattleCharacter.outputMultiplier = 0.95(余毒在身)
        → damage_calculator 末端乘
```

## 测试（TDD）

- **惩罚纯函数**：内力地板生效（低内力时 cap 在 50%）/ 主修 floor 不掉层 / 无主修角色跳过 / 辅修不动。
- **战败结算分流**：心魔关战败施加惩罚 + 余毒；非心魔关 / 胜利不施加；心魔关与 Boss 散功互斥。按 [[feedback_battle_result_path_config_read_crashes_light_test]] 防 config 读崩，结算路径测走真 config。
- **余毒生命周期**：施加→战斗输出 0.95→闭关内力 0.80→累计满 8h 清→不足 8h 仍在→再败刷新回 8.0→旧档默认 0。
- **存档**：saveVer bump + 旧档加载新字段默认 0。
- **红线复评**：惩罚只降不升、`outputMultiplier ≤ 1.0` 不放大伤害；跑 16 红线测 + `full_build_damage_redline` + `inner_demon_r5_redline` 不回归。

## 红线 / 约束

- §5.6 不硬编码：地板 50%、所有系数走 `numbers.yaml`；惩罚逻辑集中在 inner_demon service / damage_calculator，不在 Widget/Notifier 散写。
- §5.4 数值红线：惩罚单向下调，`outputMultiplier ≤ 1.0` 不可能放大伤害。
- §5.5 在线=离线：余毒清除按**闭关时长**累计（游戏内挂机时长），非真实墙钟，不引入计时器。
- fresh worktree：缺 `.g.dart` 先 `dart run build_runner build`；libisar.dylib 截断从主仓拷（[[feedback_wuxia_pen_build_runner]] / [[feedback_fresh_worktree_libisar_dylib]]）。schema 改后接收方 checkout 也须重跑 build_runner。

## 验收

合 main 前：全量 analyze 0 + 全量测试零回归（当前 2247 +1 skip，本批新增测后净增长）。
