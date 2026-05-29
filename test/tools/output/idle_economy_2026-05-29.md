# 根因A 挂机经济曲线 · idle_economy 验证 · 2026-05-29

挂机封顶 72h(`retreat.cap_hours`)· 基线 solarBonus/ziShi/zhengWu = 1.0 · 玩家境界 = 各图 requiredRealm。

## B1 共鸣度(人剑合一)

- 挂机折算:`5 battleCount/h` × 72h = **360** /件出战装备
- 默契阈值(解锁人剑合一):**300**
- 挂机到默契:**60h**
- 实战对照:`+1 battleCount/胜`(battle_resolution.dart:136)→ 挂机 1h ≈ 实战 5 胜的共鸣推进(idle 是慢速涓流)
- 判定:72h 挂机 360 ≥ 300 ✅ 离线可达人剑合一;需 60h 多日投入,不秒解锁

## B2 EXP / B3 凝练修炼度(逐图)

Ch3 大Boss(stage_03_05)baseExpReward = **6000** · 早期修炼层(初窥→小成)= **100** · insight→修炼比率 = **1.0** · base_learn = **0.5**/h

| 图 | requiredRealm | scale | B2 idleEXP | 折Ch3Boss | tier-fair升层 | B3 insight | 凝练修炼度 | 折早期层 |
|---|---|---|---|---|---|---|---|---|
| 山林(shanLin) | xueTu | 1.00 | 7200 | 1.2 | 12 | 36 | 36 | 0.36 |
| 古剑冢(guJianZhong) | sanLiu | 1.30 | 7488 | 1.2 | 6 | 46 | 46 | 0.46 |
| 藏经阁(cangJingGe) | sanLiu | 1.30 | 8424 | 1.4 | 6 | 70 | 70 | 0.70 |
| 悬崖瀑布(xuanYaPuBu) | erLiu | 1.69 | 21294 | 3.5 | 4 | 60 | 60 | 0.60 |
| 断崖绝壁(duanYaJueBi) | zongShi | 3.71 | 133665 | 22.3 | 1 | 200 | 200 | 2.00 |

## 平衡带断言

- **B1**:72h 挂机 battleCount ≥ 默契阈值 ∧ 到阈值耗时 ∈ [24, 72]h
- **B2 设计锚**:二流 xuanYaPuBu 折 Boss ∈ [3, 4.5](根因A ×2.5 目标 3-4)
- **B2 通用**:每图 tier-fair 升层 ∈ [1, 21](可观但不爆 3 个大境界)
- **B3**:每图凝练折早期层 ∈ [0.3, 3.0](有意义 sink,不破修炼度主路)

## 局限

- 折Ch3Boss 仅在二流(Ch3 同期 tier)有意义;高 tier(宗师 duanYaJueBi)对 Ch3 Boss 折算失真,故 B2 通用断言改用 tier-fair 升层。
- 不含装备 drop / 内力涨幅 / 心法相生增益(只验三批核心成长维度)。
- 实战 EXP 用 stage.baseExpReward(全员 full 不平摊),挂机 vs 实战"成长速度"对比是每单位时间产出量级,非精确时薪。
