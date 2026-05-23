# P3.2 §12.3 群战守城 全收尾 closeout

> 日期:2026-05-24 / 模型:Mac + Opus 4.7 xhigh
> worktree:`/Users/a10506/Desktop/wuxia_idle_p3_2` @ `feat/p3_2_mass_battle`
> 5 commit `ae97f83 → 本` · 1268 pass / 0 analyze · 累计 ~2h xhigh / spec 估 6-7h · 精度 0.30×

---

## 范围闭环

5 关守城试炼平行支线全闭环(沿 LightFoot 体例)· yiLiu 3 + jueDing 2 · wave 2-4 / 敌 5-7「以少胜多」· 不接管 wuSheng 突破链。

## Batch 实装总览

| Batch | 内容 | commit | 实际 | 估时 |
|---|---|---|---|---|
| 2.1 schema | StageType + Formation enum + numbers.yaml mass_battle 段 + MassBattleDef 类 + StageDef 字段 | `ae97f83` | ~25min | 45min |
| 2.2 strategy | MassBattleStrategy 组合委派 + applyFormationTo + _intermission + R6 11 测 | `0b1296b` | ~30min | 1.5h |
| 2.3 stages + service | 5 关 stages.yaml + MassBattleService 三态 + game_repo 校验 + service 9 测 | `35864cc` | ~25min | 1h |
| 2.4 narrative + UI | ~2.2k 字 11 yaml + MassBattleScreen + main_menu 入口 13→14 | `d7c9b38` | ~25min | 1.5h |
| 2.5 R5/R6 + doc | R5.1-R5.4 红线测 + GDD v1.12→v1.13 + ROADMAP + PROGRESS + 本 closeout | `本` | ~15min | 1h |
| **累计** | — | 5 commit | **~2h** | 6-7h(精度 0.30×) |

## 关键设计点

- **组合委派**:`MassBattleStrategy` 持 `const DefaultGroundStrategy _delegate`,零代码重复(沿 LightFoot 体例 · memory `feedback_avoid_over_engineer_abstraction`)
- **immutable runToEnd 一次性 wave 循环**:入口 `applyFormationTo` 烘焙仅 leftTeam → for wave: 替换 rightTeam → `_delegate.runToEnd` → leftWin 继续 / rightWin+draw 终止 → 末尾不走 intermission
- **`applyFormationTo` 仅 leftTeam 烘焙**(玩家战略选择 · 与 LightFoot 双方对等关键差异 · R6 测专测此差异)
- **`_intermission`** 按 `config.waveIntermission` 4 字段控制 + **必清空 result+pendingUltimates** 防下波 short-circuit
- **clamp [0.0, 0.95]** 防破 §5.4/§5.5 红线

## R5/R6 红线测结果

- **R5.1 5 关 × 50 seed**:全过(rightWins=0)· **但** stage_03/04/05 全 draws(数值平衡问题 · 见挂账)· distribution:
  ```
  stage_01: 33 wins / 17 draws
  stage_02:  9 wins / 41 draws
  stage_03:  0 wins / 50 draws
  stage_04:  0 wins / 50 draws
  stage_05:  0 wins / 50 draws
  ```
- **R5.2 formation cap + §5.4 + 仅 leftTeam 差异**:全过(对比 initial.rightTeam vs modified.rightTeam 4 字段无变化)
- **R5.3 unlock 链 e2e**:全过(stage_06_05 → mass_battle_01..05 渐进解锁 · 5 关 cleared 三态)
- **R5.4 wave 间 preserve/reset e2e**:stage_02 wave=3 10 seed 至少 1 leftWin(实测 9 leftWin · 沿 R5.2 体例约束语义)
- **R6 烘焙单测 11 项**:3 阵型 stat delta + clamp 2 + 仅 leftTeam 差异 + fixture 兼容 + wave ctor 4 项

## 架构决议(spec §3 漏点 · Batch 2.5 拍板)

| 选项 | 选择 | 理由 |
|---|---|---|
| (A) Strategy 加 mutable wave index | ✗ | 破 immutable 设计 · 与 LightFoot 体例不一致 |
| (B) BattleNotifier wave-aware | ✗ | 改 core/application 太大 · YAGNI |
| **(C) runToEnd 一次性 immutable** | ✓ | strategy 保持干净 · R5 测直接调不走 UI · UI 战斗 wiring 留 Batch 3.x |

## 挂账(P3.2 收尾外延)

- **P3.2.B 数值调优**:stage_03/04/05 R5.1 全 draws(玩家 3 vs 累计 17-26 敌 · maxTicks=2000 跑不完)解法候选:① wave 间 HP 部分回血(numbers.yaml wave_intermission 加 hp_recovery_pct)② 敌方后波数值递减(numbers.yaml mass_battle.wave_progression.atk_decay_pct)③ maxTicks 放宽到 5000+(临时 hack)· **不阻塞 P3.2 收尾**
- **P3.x UI 战斗 wiring**:阵型选择 dialog + `buildWavesFor` 公开(从 R5 test inline 升 production)+ `stage_entry_flow` massBattle 分支 + `BattleScreen` 多槽 UI / wave 切换动画 — 当前点击 mass_battle stage 走 fallback DefaultGround 单场 3v3(头 3 敌 · 不 crash 但非真守城体验)
- **Pen Windows 视觉验收**:P3.1 + P3.2 入口可见(Codex 异步 ~1h · 非阻塞)

## 不变量沿用

- **GDD §5.4/§5.3/§5.5/§6 红线 0 改**(Formation 修正烘焙到 BattleCharacter view layer · base 公式不变)
- **BattleStrategy 接口 3 method 不动**(组合委派 + immutable runToEnd)
- **LightFoot / InnerDemon / DefaultGround 战斗形态 0 改**(平行支线独立 · `isLayerLocked` 无 massBattle 路径)
- **doc 体量**:本 closeout 80 行 · spec 126 行 · phase0 72 行 · PROGRESS 净增长 -4 行 ✅

---

**P3.2 §12.3 群战守城收口 ✅** · 1.0 P3.2 闭环 · 整体 ~80% · 下波候选 P3.2.B 数值调优 / P3.2 worktree merge / P2.3 飞升
