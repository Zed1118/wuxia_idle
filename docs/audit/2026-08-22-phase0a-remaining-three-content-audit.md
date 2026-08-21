# Phase 0A 剩余三条生产内容审计

> 日期：2026-08-22
> 基线：`main`，事件坐标批与格式门禁收口后
> 性质：只读事实审计与后续切片边界；不是实现授权，也不把降级运行记作迁移完成。

## 结论

生产 manifest 共 149 条，当前 146 eligible、3 skipped：

| 内容 | skip reason | 审计结论 |
|---|---|---|
| `stage_21_05` | `unsupported_win_condition` | 先拍时基语义并重新校准，禁止机械照搬 `ticks: 10` |
| `tower_42` | `unsupported_guardian_ward` | 协同型 guardian；须在基础 ward 后单独迁移破招重定向与合击 |
| `tower_49` | `unsupported_guardian_ward` | 基础 guardian ward 首个纵切候选 |

证据入口：

- 分类与 fail-closed：`test/support/phase0a_production_preflight_manifest.dart`
- 精确三条守恒：`test/support/phase0a_boss_phase_capability_matrix_test.dart`
- 真内容：`data/stages.yaml` 的 `stage_21_05`；`data/towers.yaml` 的 floor 42/49
- Phase 0A 固定步长：`data/numbers.yaml` → `phase0a_arena.fixed_delta_seconds: 0.1`
- 首攻窗口：`data/numbers.yaml` → `initial_attack_cooldown: 2.0`

## 1. `stage_21_05` surviveTicks

### 不能直接迁移的原因

旧战斗 `StageWinCondition.surviveTicks` 的 tick 是 strategy 行动边界；配置 `ticks: 10` 经过 2026-07-29 的 15,750 场旧核校准。Phase 0A 的 `Phase0aArenaState.tick` 每 `0.1s` 增加一次。若直接判断 `tick >= 10`，约 1 秒即胜，甚至早于敌方 2 秒首攻延迟，产品语义显然失真。

### 早班拍板项

推荐先定义 Phase 0A 的生存条件为明确时间域，例如 `surviveDurationSeconds` 的运行时语义；内容层是否改 schema、是否由旧行动 tick 转换，需要独立决策。拍板后必须重新跑三流派/多 seed 校准，不能用常量乘十冒充旧难度等价。

### 实现验收边界

1. 玩家死亡优先于生存胜利；敌人全灭的胜利通道仍保留。
2. 终局事件唯一，终局后 advance 幂等。
3. live/headless 同 seed、同输入得到相同终局拍与事件序列。
4. `stage_21_05` 才转 eligible；其他 148 条分类不变。
5. HUD/结算文案另需 Phase 0A 玩家可见面，不能只迁 headless 判定。

## 2. `tower_49` 基础 guardian ward

### 既有语义

- Boss 配 `guardianWard.damageTakenMult: 0.15`，guardian ids 为左右使。
- 任一护法存活时，Boss 从自动目标优先级中排除，并在手动越过护法命中时承伤乘 0.15。
- 护法全灭后 Boss 恢复全额 ward 承伤；其 `vulnerability: 0.10` 继续按已迁移的蓄力/踉跄窗口处理。

### 推荐原子切片

1. 将 guardian ids 与 ward mult 作为预解析内容事实进入 Phase 0A actor/伤害快照；不得在 reducer 回查 repository。
2. 由 reducer 依据当前 arena 敌人存活态计算 `defenderWardActive`，再沿唯一 `Phase0aDamageCalculatorAdapter` 折入既有 `defenderWardMult`。
3. 玩家 bot 的目标选择加入 guarded Boss 排除语义；手动输入仍允许越过护法命中，但吃 ward 减伤。
4. 补护法存活/全灭、ward×vulnerability 组合、同拍护法死亡边界、确定性回放与真 `tower_49` wiring 测试。
5. 只在语义全链成立后将 `tower_49` 转 eligible；预检应变为 147 eligible / 2 skipped。

### 不得顺手做

- 不在本片迁 `guardInterceptsInterrupt` 或双护法合击。
- 不改 `damageTakenMult`、敌人 HP、伤害公式或目标选择数值。
- 不用静态 `wardMult: 0.15` 永久冻结来伪装动态护法存活语义。

## 3. `tower_42` 协同 guardian

### 比 `tower_49` 多出的语义

- `guardInterceptsInterrupt: true`。
- Boss 蓄力且护法存活时，玩家破招命中 Boss 要重定向给存活护法；护法代吃并踉跄，Boss 蓄力继续。
- 双护法存活时每相位一次合击；击破任一护法后合击不可用。

### 推荐独立切片

在基础 guardian ward 已落地后再做：

1. 冻结破招重定向事件契约：原目标、实际承受者、Boss 蓄力是否持续、护法踉跄拍数均可观测。
2. 处理同拍竞态：护法本拍被其他伤害击杀时，不得继续代吃；稳定选择存活护法（按既有血量/id 决胜语义）。
3. 合击仍为两份既有公式伤害的集中呈现，不新增倍率、不复制 DamageCalculator。
4. 真 `tower_42` 从 YAML → mapper → reducer/AI → headless 全链验收；之后才转 eligible。
5. 完成后 manifest 理论上仅剩 `stage_21_05`，即 148 eligible / 1 skipped。

## 建议派发顺序

1. 用户拍板 survive 时间域，但先不实现。
2. Qwen 新会话/新 worktree：`tower_49` 基础 guardian ward，提示词只附本审计与相关文件索引。
3. 主 agent 审 diff、定向测试、预检与全量后，再开 `tower_42` 协同 guardian。
4. `stage_21_05` 待时间域拍板和校准方案明确后单独处理。

