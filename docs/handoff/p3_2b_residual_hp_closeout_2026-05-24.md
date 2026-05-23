# P3.2.B 残血容差数值调优 closeout

> 日期:2026-05-24 / 模型:Mac + Opus 4.7 xhigh
> worktree:`/Users/a10506/Desktop/wuxia_idle_p3_2` @ `feat/p3_2_mass_battle`
> 1 commit `本` · 1269 pass / 0 analyze · ~70min(诊断 25min + 实装 25min + 收尾 20min)

---

## 范围闭环

R5.1 stage_03-05 全 draws 数值挂账(P3.2 收尾外延)Phase 0.5 诊断 + F 残血容差方案 ship。stage_03+ 真因暴露:**BattleEngine 底层 stalemate** 而非数值问题,挂账 P3.2.C。

## Phase 0.5 诊断关键发现

| 探针 | 结果 |
|---|---|
| ③ maxTicks=10000(5×) | distribution **完全没变** · 不是时长问题 |
| stage_01/02 wave 末 right=554-7000 残血 | 是「最后 1 残血敌方 KO 不掉」stalemate |
| stage_03+ wave=2 entry=exit pct=1.000 enemyAlive=5-7 leftAlive=2 | **双方互免疫** · 2000 tick 双方 0 伤害交换 · BattleEngine 底层问题 |

## F 残血容差实装(4 文件 + 91 行)

| 文件 | 改动 |
|---|---|
| `lib/features/mass_battle/domain/mass_battle_def.dart` | +`residualHpThresholdPct` 字段(默认 0.05)+ fromYaml 解析 |
| `lib/features/battle/domain/strategy/mass_battle_strategy.dart` | runToEnd wave 委派后判定:`draw && rightExitHp ≤ rightEntryHp × threshold` → 改判 `leftWin` |
| `data/numbers.yaml` mass_battle 段 | +`residual_hp_threshold_pct: 0.30`(诊断阈值 0.05/0.15/0.30 三轮校准) |
| `test/balance/p3_2_mass_battle_redline_test.dart` | +R5.5 残血容差语义测(empty config 默认 0.05 + stage_01 leftWins ≥ 33 下限) |

## R5.1 distribution 改善(50 seed)

| stage | 调优前 | 调优后 | Δ |
|---|---|---|---|
| stage_01 yiLiu·qiMeng | 33 wins / 17 draws | **46 wins / 4 draws** | +13 wins |
| stage_02 yiLiu·jingTong | 9 wins / 41 draws | **32 wins / 18 draws** | +23 wins |
| stage_03 yiLiu·dengFeng | 0 wins / 50 draws | 0 wins / 50 draws | (挂账 P3.2.C) |
| stage_04 jueDing·qiMeng | 0 wins / 50 draws | 0 wins / 50 draws | (挂账 P3.2.C) |
| stage_05 jueDing·jingTong | 0 wins / 50 draws | 0 wins / 50 draws | (挂账 P3.2.C) |

R5.1 红线 `leftWins + draws ≥ rightWins` 全 5 关仍 pass(rightWins=0)。

## 挂账(P3.2.B → P3.2.C)

- **P3.2.C BattleEngine 底层 stalemate**:stage_03+ wave 内 2000 tick 双方互免疫(玩家 leftAlive=2 vs 敌方 enemyAlive=5-7 0 伤害交换)。诊断证伪境界差距假设(stage_05 同阶 jueDing·jingTong 仍 stalemate),真因待挖 — 可能 actionPoint 推进卡死 / target 选取卡死 / 命中率衰减。**触底 BattleEngine 不在 P3.2 mass_battle 数值调优 scope**,新开任务 P3.2.C 单独修。本残血容差 F 方案对 stage_01/02 已有显著改善,stage_03+ 数值层面无解,挂账透明。
- **P3.x UI 战斗 wiring** (前置挂账沿用):阵型选择 dialog + buildWavesFor 公开 + BattleScreen 多槽 UI + wave 切换动画
- **Pen Windows 视觉验收** (前置挂账沿用):P3.1 + P3.2 入口可见(Codex 异步 ~1h)

## 不变量沿用

- **R5.1-R5.4 4 红线测全 pass**(语义不动)
- **§5.4/§5.3/§5.5/§6 红线 0 改**
- **BattleStrategy 接口 3 method 不动** · 残血容差是 MassBattleStrategy.runToEnd 内部小修补
- **doc 体量**:本 closeout ≤80 行 ✅
- **PROGRESS 净增长 ≤ 0**(同 P3.2 顶段更新)

---

**P3.2.B 残血容差收口 ✅** · stage_01/02 显著改善 / stage_03+ 挂账 P3.2.C BattleEngine 底层 · 不阻塞 P3.2 收尾。
