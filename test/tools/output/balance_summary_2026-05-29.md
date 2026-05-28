# Balance Simulation Summary · 2026-05-29

5h 挂机 Batch A3 · 50 seed × 30 mainline = 1500 runs · maxTicks=200

## 通关率(玩家胜率 = leftWin / total)

| stage_id | requiredRealm | isBoss | chap | leftWin | rightWin | draw | timeout | winRate | avgTicks |
|---|---|---|---|---|---|---|---|---|---|
| stage_01_01 | xueTu | — | 1 | 50 | 0 | 0 | 0 | 100.0% | 8.3 |
| stage_01_02 | xueTu | — | 1 | 50 | 0 | 0 | 0 | 100.0% | 8.3 |
| stage_01_03 | xueTu | — | 1 | 50 | 0 | 0 | 0 | 100.0% | 8.3 |
| stage_01_04 | xueTu | Boss | 1 | 50 | 0 | 0 | 0 | 100.0% | 8.3 |
| stage_01_05 | xueTu | Boss | 1 | 0 | 50 | 0 | 0 | 0.0% | 13.1 |
| stage_02_01 | sanLiu | — | 2 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_02_02 | sanLiu | — | 2 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_02_03 | sanLiu | — | 2 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_02_04 | sanLiu | Boss | 2 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_02_05 | sanLiu | Boss | 2 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_03_01 | erLiu | — | 3 | 50 | 0 | 0 | 0 | 100.0% | 6.1 |
| stage_03_02 | erLiu | — | 3 | 50 | 0 | 0 | 0 | 100.0% | 6.1 |
| stage_03_03 | erLiu | — | 3 | 50 | 0 | 0 | 0 | 100.0% | 6.1 |
| stage_03_04 | erLiu | Boss | 3 | 50 | 0 | 0 | 0 | 100.0% | 6.1 |
| stage_03_05 | erLiu | Boss | 3 | 50 | 0 | 0 | 0 | 100.0% | 6.1 |
| stage_04_01 | yiLiu | — | 4 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_04_02 | yiLiu | — | 4 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_04_03 | yiLiu | — | 4 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_04_04 | yiLiu | Boss | 4 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_04_05 | yiLiu | Boss | 4 | 50 | 0 | 0 | 0 | 100.0% | 8.1 |
| stage_05_01 | jueDing | — | 5 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_05_02 | jueDing | — | 5 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_05_03 | jueDing | — | 5 | 50 | 0 | 0 | 0 | 100.0% | 4.9 |
| stage_05_04 | jueDing | Boss | 5 | 50 | 0 | 0 | 0 | 100.0% | 7.4 |
| stage_05_05 | jueDing | Boss | 5 | 50 | 0 | 0 | 0 | 100.0% | 8.8 |
| stage_06_01 | zongShi | — | 6 | 50 | 0 | 0 | 0 | 100.0% | 4.1 |
| stage_06_02 | zongShi | — | 6 | 50 | 0 | 0 | 0 | 100.0% | 4.6 |
| stage_06_03 | zongShi | — | 6 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_06_04 | zongShi | Boss | 6 | 50 | 0 | 0 | 0 | 100.0% | 7.0 |
| stage_06_05 | zongShi | Boss | 6 | 50 | 0 | 0 | 0 | 100.0% | 7.8 |

## 卡点 / 秒杀点诊断

- **卡点**(winRate < 30%):玩家难过 → 数值上调候选
  - stage_01_05:0.0%

- **秒杀点**(winRate > 95%):玩家无脑过 → 数值下调候选(若是 Boss)
  - stage_01_01:100.0%
  - stage_01_02:100.0%
  - stage_01_03:100.0%
  - stage_01_04:100.0%
  - stage_02_01:100.0%
  - stage_02_02:100.0%
  - stage_02_03:100.0%
  - stage_02_04:100.0%
  - stage_02_05:100.0%
  - stage_03_01:100.0%
  - stage_03_02:100.0%
  - stage_03_03:100.0%
  - stage_03_04:100.0%
  - stage_03_05:100.0%
  - stage_04_01:100.0%
  - stage_04_02:100.0%
  - stage_04_03:100.0%
  - stage_04_04:100.0%
  - stage_04_05:100.0%
  - stage_05_01:100.0%
  - stage_05_02:100.0%
  - stage_05_03:100.0%
  - stage_05_04:100.0%
  - stage_05_05:100.0%
  - stage_06_01:100.0%
  - stage_06_02:100.0%
  - stage_06_03:100.0%
  - stage_06_04:100.0%
  - stage_06_05:100.0%

## 期望区间

- 普通关 winRate ∈ [60%, 90%](玩家上手有挑战不卡死)
- Boss 关 winRate ∈ [40%, 70%](章末压力 + 留余裕)

## 数据局限

- 玩家合成模型简化:1 角色 vs 1-3 敌(不 3v3)· 数值按 RealmTier 线性 scale
- 不接 Isar(无装备 / 心法搭配 / 师徒 / 共鸣度 / founder buff)
- 流派固定刚猛 gangMeng · 不验阴柔/灵巧分布
- maxTicks=200 兜底(timeout = 不分胜负)

**用途**:卡点 / 秒杀点 **方向性**诊断,精确 tune 需接真玩家路径(Isar 体例)。
