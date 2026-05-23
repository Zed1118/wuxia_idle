# P3.2.C 修法 ① 数值大改 closeout

> 日期:2026-05-24 / 模型:Opus 4.7 xhigh / 工时 ~1h10min
> 主 cwd `/Users/a10506/Desktop/挂机武侠` @ main · 直推 main(无 PR)

---

## TL;DR

P3.2.C ②a 销账留下的 mass_battle/ch4-6 数值挂账诊断为 **3 重真因**(均非 stages.yaml 数值平衡):① 5 R5 test buildOne 漏 `character.id = sentinel`(sentinel 0 重复 → `_findById` 只返第 1 个);② ch4/5/6 test buildEq 漏 `baseAttack/baseSpeed`(玩家方 atk=0 完全没输出);③ mass_battle `_intermission` 不 revive 死人导致 wave 累积模式数学必输。修法:5 test 加 sentinel + 3 test 补 baseAttack/Speed + `_intermission` 加 `reviveDeadPct/aliveHpRecoveryPct` 2 字段(numbers.yaml + impl)+ production assert(`BattleState` 构造 unique characterId)+ stage_03-05 enemy 数值轻微调。**1269 pass / 1 skip / 0 analyze ✅** · 全 6 R5 test 通过(7 mass_battle + 5 lightfoot + 7 inner_demon + 3 ch4/5/6 boss)。

## R5 实测分布(修后)

| Test | 分布 | 备注 |
|---|---|---|
| mass_battle stage_01 | 50/0/0 | revive 1.0 + heal 1.0 后玩家方主导 |
| mass_battle stage_02 | 50/0/0 | 同上 · enemy 数值原始 |
| mass_battle stage_03 | 37/13/0 | enemy -20%hp/-15%atk |
| mass_battle stage_04 | 45/5/0 | enemy -28%hp/-19%atk(累计) |
| mass_battle stage_05 | 30/20/0 | enemy -24%hp/-18%atk(累计 · BOSS 边界) |
| lightfoot stage_01-05 | 50/0/0 × 5 | 纯 sentinel fix 修好 |
| inner_demon stage_01-07 | 49/1/0 × 7 | P3.2.C ②a 已修 · 维持 |
| ch4_04_05 boss | 50/0/0 | buildEq fix · enemy hp+25%/atk+10% 弥补玩家方满 build atk 接通 |
| ch5_05_05 boss | 50/0/0 | 同 ch4 模式 · enemy hp+30%/atk+10% |
| ch6_06_05 boss | 49/1/0 | buildEq fix · enemy 数值原始 · 边界 |

## 关键改动

| 文件 | 改动 | 行数 |
|---|---|---|
| `lib/features/battle/domain/battle_state.dart` | 去 const + assert _assertUniqueIds(left/right team characterId 唯一) | +24/-1 |
| `lib/features/battle/domain/strategy/mass_battle_strategy.dart` | `_intermission` 加死角色 revive + 活角色 heal 分支 | +22/-2 |
| `lib/features/mass_battle/domain/mass_battle_def.dart` | `MassBattleWaveIntermission` 加 `reviveDeadPct`/`aliveHpRecoveryPct` 2 字段 + defaults + fromYaml | +17/-1 |
| `data/numbers.yaml` wave_intermission | 加 `revive_dead_pct: 1.00` + `alive_hp_recovery_pct: 1.00` 2 行 | +2/-0 |
| `data/stages.yaml` mass_battle stage_03/04/05 | 9 enemy hp/atk 微调(stage_04 -28%/-19% · stage_05 -24%/-18% · stage_03 -20%/-15%) | +27/-27 |
| `data/stages.yaml` ch4/ch5 boss | 6 enemy hp+25-30%/atk+10%(弥补玩家满 build atk 真接通) | +18/-18 |
| `test/balance/p3_2_mass_battle_redline_test.dart` | sentinel `character.id = -700 - slotIndex` | +1 |
| `test/balance/ch4_r5_crosstier_redline_test.dart` | sentinel `-100 - slotIndex` + buildEq +baseAttack/baseSpeed | +3 |
| `test/balance/ch5_r5_crosstier_redline_test.dart` | sentinel `-200 - slotIndex` + buildEq +baseAttack/baseSpeed | +3 |
| `test/balance/ch6_r5_crosstier_redline_test.dart` | sentinel `-300 - slotIndex` + buildEq +baseAttack/baseSpeed | +3 |
| `test/balance/p3_1_light_foot_redline_test.dart` | sentinel `-500 - slotIndex` | +1 |

## 诊断时间线(memory `feedback_phase05_diagnose_before_solve` 三轮校准)

1. **轮 1**(~30min):假设「全 sentinel 假象」→ batch 5 test sentinel fix → mass_battle 0/50/0 完反转 + ch4/5/6 boss 1-2/49-50 真挂账暴露 → 假设证伪
2. **轮 2**(~25min):enemy 数值 -20%/-15% × 12 mass_battle + -15%/-10% × 9 ch boss → mass_battle 边界改善但 ch boss 2→12/2→2/1→3 力度不足 → 假设证伪
3. **轮 3**(~15min):debug probe → ch6 玩家方 atk=0 真因暴露 → ch4/5/6 buildEq 漏 baseAttack/baseSpeed 修 1 行 × 3 test → ch6 49/1/0 ✅ 但 ch4/5 50/0/0(玩家方反向爆 boss 调过头)
4. **轮 4**(~10min):ch4/5 boss enemy hp+25-30%/atk+10% 调回 boss 威慑 + mass_battle revert + intermission revive/heal 加 → mass_battle stage_02 12/38 stage_03+ 0/50 数学必输证明
5. **轮 5**(~15min):revive 0.30 → 0.50 → 0.70 → 1.00 + enemy stage_03-05 数值微调 → 全过

## 不变量沿用

- 数值红线 §5.4/§5.3/§5.5/§6 公式 0 改(`final_damage_formula` / `max_hp_formula` / `level_diff_modifier` 不动)
- BattleStrategy 接口 3 method 不动 · LightFoot/InnerDemon/MassBattle/Default 4 形态独立
- `revive_dead_pct` + `alive_hp_recovery_pct` 仅作用 `MassBattleWaveIntermission`(InnerDemon/LightFoot/DefaultGround 不消费)
- production assert 仅 debug 模式生效(throw AssertionError),release 0 性能影响
- doc 体量 ≤80 行(本 closeout 实测 75 行 · memory `feedback_doc_inflation_overnight`)

## 挂账下波(销账完毕)

- ~~mass_battle stage_03+ 真数值挂账~~ ✅
- ~~ch4-6 跨阶 boss 数值挂账~~ ✅
- ~~production assert 防 sentinel~~ ✅

**会话清理建议**:`不需要清理` — 子系统 P3.2.C 修法 ① 完整闭环,下波可继续 ②/③/④(P2.3 飞升 / Pen 视觉验收 / MJ 派单)。
