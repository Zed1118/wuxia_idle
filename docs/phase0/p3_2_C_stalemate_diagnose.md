# P3.2.C Phase 0.5 诊断 — BattleEngine stalemate 真因 + Fix 验证

> 日期:2026-05-24 / 模型:Opus 4.7 xhigh / 工时 ~90min(诊断 40 + fix 验证 50)
> worktree `feat/p3_2_mass_battle` @ HEAD `20789a6` · 探针/fix 已 revert,只留本报告

## TL;DR

**真因 = test 路径 `Character.id = Isar.autoIncrement` sentinel 未持久化导致 characterId 重复 + BattleEngine `_findById` 只返第 1 个匹配 → 实际只玩家 0 号行动**。closeout 假设「BattleEngine maxTicks 强判 / 0 伤害 break / target 调」3 候选**全证伪**。Fix 单独可行但**揭示更深数值问题** → 全 revert,挂账下波由用户决策。

## 探针真因数据(stage_05 wave 2 末态)

| 字段 | 玩家 0 号 | 玩家 1/2 号 |
|---|---|---|
| isAlive | 死 (hp=0) | 活 (hp 满) |
| actionPoint | -5250 | **700000** (2000 tick × spd 350) |
| actions in wave | 7 | **0** |

**异常**:1/2 号 `ap=700000` 末态 = 2000 tick 累积无消耗,**完全没行动**。

## 真因链路

1. `lib/core/domain/character.dart:13` — `Id id = Isar.autoIncrement;` (sentinel = Int64.MIN_VALUE)
2. test `buildPlayerTeam` 用 `Character.create(...)` 创 3 人**不入 isar** → 3 人 character.id 全等 sentinel
3. `BattleCharacter.fromCharacter` L258 `characterId: character.id` → 3 个 BattleCharacter 同 characterId
4. `DefaultGroundStrategy.tick` actors 列表收 3 个玩家 actor(同 id 3 份)
5. `_findById(s, initial.characterId, 0)` 总返 leftTeam **第 1 个匹配** → 永远是 0 号
6. 1/2 号永远不被 resolve action(但每 tick `_advanceTick` 推 ap)

### stage_01/02 为何「部分通过」?
0 号一人 11 actions/wave 1 高 burst,弱敌方能清(46/32 wins);stage_03+ 同阶同层 0 号扛不住 5-7 敌方反击 → stalemate。

## Batch B Fix 验证(全 revert · 不 ship)

修法:7 个 test buildPlayerTeam 加 `..id = -X00 - slotIndex` + default_ground_strategy.dart 加 assert 防御(同 team characterId 唯一)。

| Test | 修后 R5 行为 | 评估 |
|---|---|---|
| **inner_demon R5.1** | **49 wins / 1 rightWin / 0 draws × 7 关** | ✅ **完美解 — 克己语义清晰** |
| **mass_battle R5.1 stage_02** | 0 wins / 50 rightWins | ❌ 数值真不平衡 |
| **ch4/5/6 R5 跨阶 boss** | 1-2 wins / 48-49 rightWins | ❌ 跨阶 boss 真打不过 |

**结论**:fix 是真 bug 修复 + production 健壮性提升,但**揭示 3v5/6/7 守城 + 跨阶 boss 战的数值平衡问题** — 原 R5 红线「pass」是 bug 假象(0 号 carrier 模式)。**调数值是用户主轴,不自主拍板** → 全 revert,挂账下波。

## 下波修法候选(用户决策)

| 候选 | 含义 |
|---|---|
| ① 接受 fix + 调数值 | 修 7 test + production assert,**+ 调 stages.yaml/numbers.yaml** 让玩家方真平衡(大改) |
| ② 接受 fix + 改 R5 expect | 修 test + assert,**改 R5.1 接受当前真分布**(降红线 — 不推荐) |
| ③ 单独修 inner_demon | 只动 inner_demon test,其他 5 test 不动(inner_demon 真解,其他维持 bug 假象);**memory `feedback_balance_buff_singledim_no_effect` inner_demon 部分销账** |
| ④ 不修 ship Demo | 维持现状,bug 假象通过 R5,production 0 影响,**character.id sentinel 隐患保留**(Demo 不触发) |

## 不变量沿用

- production 0 改(Character.id Isar.autoIncrement 路径不变)
- §5.4/§5.3/§5.5/§6 红线 0 改
- BattleStrategy 接口 3 method 不动
- 全量 1269 pass / 0 analyze ✅(revert 后)

---

**诊断结论**:真因 = test 路径 character id 重复,closeout 3 候选全证伪。Fix attempt 验证可行但揭示数值真问题(scope > 自主决策) → revert + 用户决策修法候选 1-4。
