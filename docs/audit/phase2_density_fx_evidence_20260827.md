# N15 密度视效证据（2026-08-27）

## 结论

- 状态：`[BLOCKED]`。固定分母格 1–4 为 `0/4 PASS`。
- 直接阻塞：生产端不存在高/低特效密度设置入口；也没有塔 14/群战 18/24 active 密度目标配置。
- 按派单围栏，补设置/provider/VFX 消费或补密度配置都必须改 `lib/`/生产配置；本单不越权修复。

## 锚点溯源

- N2 审计现取：`phase2_spec_reality_audit_20260826.md:55` 仍为「LOD、低特效不改实体/难度及多密度 UI 可读性 | 7 组」，结论「无法判定」。
- 方案 `L800-802` 明确要求低特效不减实体、不改令牌、不降难度；`L1420-1428` 是七格后三格的视觉可读性边界。
- G2 记录仅有黑风岭双视口/8–12 active，不能外推本批密度点。

## 生产入口审计

- 真实设置值对象 `GameplaySettings` 只有 `autoPlayDefault`、`battlePlaybackSpeed`、`textDensity`、`reduceFlashing`。
- `gameplaySettingsProvider` 读 `GameplaySettingsService`；`reduceFlashing` 只在 domain/service/settings panel 出现。
- `lib/features/battle/`、`mainline/`、`tower/`、`mass_battle/` 对 `reduceFlashing` 的消费数为 0；`gameplaySettingsProvider` 在主线入口被用于自动战斗偏好，不是特效消费点。
- 全 `lib/` 无 `EffectDensity/effectDensity/VfxDensity/vfxDensity/lowEffects/lowEffectDensity` 生产符号。
- 因此 `reduceFlashing` 不是可用的低特效 run 入口，更不能把它猜成「特效密度」。

## 四格结果

| 格 | 结果 | 实测证据 |
|---:|---|---|
| 1 | `FAIL` | 无高/低特效生产设置，无法构造唯一差异 run，真实敌人数不能确定比对。测试显式 `skip: _grid1Skip`。 |
| 2 | `FAIL` | 同一前置缺失，不存在两条可比的生产令牌序列。测试显式 `skip: _grid2Skip`。 |
| 3 | `FAIL` | 同一前置缺失，不生成伪造的逐 tick hash；本批未使用 Dart `hashCode`。测试显式 `skip: _grid3Skip`。 |
| 4 | `FAIL` | 塔 14 层生产 `enemyTeam=3`且 Phase 0A 映射=3；群战五关波形为 `[5,5]`/`[5,6,6]`/`[6,6,7]`/`[5,6,6,7]`/`[6,6,7,7]`，单波 active 只有 5/6/7。「总量 24」不是「同时活跃 24」；无 14/18/24 active 目标配置可读。测试显式 `skip: _grid4Skip`。 |

## 完整实测输出

```text
[N15][ENTRY] reduceFlashing=settings-only; reduceFlashing-battle-consumers=0; effect-density-symbols=0
[N15][DENSITY] tower-floor-14 configured=3 mapped=3; mass-waves={stage_mass_battle_01: [5, 5], stage_mass_battle_02: [5, 6, 6], stage_mass_battle_03: [6, 6, 7], stage_mass_battle_04: [5, 6, 6, 7], stage_mass_battle_05: [6, 6, 7, 7]}; mass-totals={stage_mass_battle_01: 10, stage_mass_battle_02: 17, stage_mass_battle_03: 19, stage_mass_battle_04: 24, stage_mass_battle_05: 26}; active-counts={5, 6, 7}
```

## 验证

- Targeted：`flutter test --no-pub test/features/battle/application/phase0a/phase2_density_fx_evidence_test.dart --reporter expanded`连跑两次，均 `2 PASS / 4 SKIP / 0 FAIL`。
- 确定性：两份完整日志 `cmp` 退出 0，SHA-256 均为 `7ff3fc9d4416f90f91aa2007f66f47734bc354928c7c215f9d5ccc3b5d485b21`。
- Skip 审查：共4个 `skip:`，与上表 4 个 `FAIL` 一一对应。
- 最终 Gate：`~/.claude/skills/afk/scripts/gate.sh <worktree> 5440f931 HEAD --whitelist <3 files>` 全量模式 PASS；`5613 PASS / 4 SKIP`，analyze `0 issue`，format `1620 files / 0 changed`。
- Gate PASS 只证明阻塞包可集成且无额外回归，不改变格 1–4 `0/4 PASS` 与 `[BLOCKED]` 结论。

## 本证据不覆盖什么

- 格 5–7 未做；它们需渲染截图，归 N16，本批未自行扩到视觉验收。
- 「高/低特效对比」天然无法发现两边被同等改坏的缺陷；凡同时影响两条 run 的改动，hash 仍可能相等。
- 本批只覆盖列出的密度点，不外推到任何未测密度。
- 本报告只证明当前生产前置不足，不证明低特效等价性，也不等于 N15 通过。

## 解锁条件

- 以独立任务新增高/低特效密度值、provider、设置 UI 与战斗/VFX 生产消费，并保证不进入领域决策。
- 以独立决策/配置任务冻结塔 14 及群战 18/24 active 目标，且与真实实体构造分离，使配置变异能把测试转红。
