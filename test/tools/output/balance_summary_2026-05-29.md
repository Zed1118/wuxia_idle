# Balance Simulation Summary · 2026-05-29

50 seed × 30 mainline × 2 profile(floor/ceiling) = 3000 runs · maxTicks=200

## 通关率 bracket(floor 欠配置 — ceiling 活跃玩家)

| stage_id | requiredRealm | isBoss | chap | floor winRate | ceiling winRate |
|---|---|---|---|---|---|
| stage_01_01 | xueTu | — | 1 | 100.0% | 100.0% |
| stage_01_02 | xueTu | — | 1 | 100.0% | 100.0% |
| stage_01_03 | xueTu | — | 1 | 100.0% | 100.0% |
| stage_01_04 | xueTu | Boss | 1 | 100.0% | 100.0% |
| stage_01_05 | xueTu | Boss | 1 | 0.0% | 0.0% |
| stage_02_01 | sanLiu | — | 2 | 100.0% | 100.0% |
| stage_02_02 | sanLiu | — | 2 | 98.0% | 100.0% |
| stage_02_03 | sanLiu | — | 2 | 86.0% | 100.0% |
| stage_02_04 | sanLiu | Boss | 2 | 74.0% | 100.0% |
| stage_02_05 | sanLiu | Boss | 2 | 10.0% | 100.0% |
| stage_03_01 | erLiu | — | 3 | 76.0% | 100.0% |
| stage_03_02 | erLiu | — | 3 | 70.0% | 100.0% |
| stage_03_03 | erLiu | — | 3 | 24.0% | 100.0% |
| stage_03_04 | erLiu | Boss | 3 | 12.0% | 100.0% |
| stage_03_05 | erLiu | Boss | 3 | 0.0% | 100.0% |
| stage_04_01 | yiLiu | — | 4 | 100.0% | 100.0% |
| stage_04_02 | yiLiu | — | 4 | 96.0% | 100.0% |
| stage_04_03 | yiLiu | — | 4 | 84.0% | 100.0% |
| stage_04_04 | yiLiu | Boss | 4 | 72.0% | 100.0% |
| stage_04_05 | yiLiu | Boss | 4 | 0.0% | 100.0% |
| stage_05_01 | jueDing | — | 5 | 100.0% | 100.0% |
| stage_05_02 | jueDing | — | 5 | 76.0% | 100.0% |
| stage_05_03 | jueDing | — | 5 | 12.0% | 100.0% |
| stage_05_04 | jueDing | Boss | 5 | 2.0% | 100.0% |
| stage_05_05 | jueDing | Boss | 5 | 0.0% | 30.0% |
| stage_06_01 | zongShi | — | 6 | 100.0% | 100.0% |
| stage_06_02 | zongShi | — | 6 | 100.0% | 100.0% |
| stage_06_03 | zongShi | — | 6 | 0.0% | 100.0% |
| stage_06_04 | zongShi | Boss | 6 | 4.0% | 100.0% |
| stage_06_05 | zongShi | Boss | 6 | 0.0% | 100.0% |

## 难度诊断(bracket 解读)

- **过难**(连 ceiling 活跃玩家都 < 50%):满配玩家都难过 → 数值偏高,上调候选
  - stage_01_05:floor 0% / ceiling 0%
  - stage_05_05:floor 0% / ceiling 30%

- **过易**(连 floor 欠配置玩家都 > 90%):欠配置玩家都碾压 → 数值偏低,下调候选(尤其 Boss)
  - stage_01_01:floor 100% / ceiling 100%
  - stage_01_02:floor 100% / ceiling 100%
  - stage_01_03:floor 100% / ceiling 100%
  - stage_01_04:floor 100% / ceiling 100%
  - stage_02_01:floor 100% / ceiling 100%
  - stage_02_02:floor 98% / ceiling 100%
  - stage_04_01:floor 100% / ceiling 100%
  - stage_04_02:floor 96% / ceiling 100%
  - stage_05_01:floor 100% / ceiling 100%
  - stage_06_01:floor 100% / ceiling 100%
  - stage_06_02:floor 100% / ceiling 100%

- **健康**:floor 偏低-中 + ceiling 中高-高 = 配装/投入有意义(欠配置有挑战、满配顺畅)。

## 期望区间(参考)

- 普通关:floor ∈ [40%, 75%] · ceiling ∈ [75%, 95%]
- Boss 关:floor ∈ [20%, 55%] · ceiling ∈ [55%, 85%]

## 数据局限

- **玩家走真 build**(`BattleCharacter.fromCharacter` derived_stats 生产路径)· **C 方案 floor+ceiling bracket**:floor 欠配置(0 强化/生疏共鸣/无 founder buff/zhongCheng/属性 20)— ceiling 活跃玩家(½ 强化/默契 ×1.20/founder buff/daCheng/属性 22),隔离配装/投入轴
- **不含辅修 synergy**(心法相生):只主修单本,SynergyService 未注入
- 流派固定刚猛 gangMeng · 不验阴柔/灵巧分布
- **playerTier = requiredRealm**(on-level 诚实基线 · 2026-05-29 去 +1 confound):玩家恰在 required 阶 · 过度练级(挂机/grind)只会更易,这是「能否在达标阶通关」的下限读数
- maxTicks=200 兜底(timeout = 不分胜负)

**用途**:难度 bracket **方向性**诊断 · floor/ceiling 区间判断配装是否有意义、何处过易(连 floor 都碾压)/过难(连 ceiling 都难过)。
