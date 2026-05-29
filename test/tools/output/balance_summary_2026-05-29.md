# Balance Simulation Summary · 2026-05-29

5h 挂机 Batch A3 · 50 seed × 30 mainline = 1500 runs · maxTicks=200

## 通关率(玩家胜率 = leftWin / total)

| stage_id | requiredRealm | isBoss | chap | leftWin | rightWin | draw | timeout | winRate | avgTicks |
|---|---|---|---|---|---|---|---|---|---|
| stage_01_01 | xueTu | — | 1 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_01_02 | xueTu | — | 1 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_01_03 | xueTu | — | 1 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_01_04 | xueTu | Boss | 1 | 50 | 0 | 0 | 0 | 100.0% | 7.1 |
| stage_01_05 | xueTu | Boss | 1 | 33 | 17 | 0 | 0 | 66.0% | 19.3 |
| stage_02_01 | sanLiu | — | 2 | 50 | 0 | 0 | 0 | 100.0% | 5.9 |
| stage_02_02 | sanLiu | — | 2 | 50 | 0 | 0 | 0 | 100.0% | 5.9 |
| stage_02_03 | sanLiu | — | 2 | 50 | 0 | 0 | 0 | 100.0% | 5.9 |
| stage_02_04 | sanLiu | Boss | 2 | 50 | 0 | 0 | 0 | 100.0% | 5.9 |
| stage_02_05 | sanLiu | Boss | 2 | 50 | 0 | 0 | 0 | 100.0% | 5.9 |
| stage_03_01 | erLiu | — | 3 | 50 | 0 | 0 | 0 | 100.0% | 4.7 |
| stage_03_02 | erLiu | — | 3 | 50 | 0 | 0 | 0 | 100.0% | 4.7 |
| stage_03_03 | erLiu | — | 3 | 50 | 0 | 0 | 0 | 100.0% | 4.7 |
| stage_03_04 | erLiu | Boss | 3 | 50 | 0 | 0 | 0 | 100.0% | 4.7 |
| stage_03_05 | erLiu | Boss | 3 | 50 | 0 | 0 | 0 | 100.0% | 4.7 |
| stage_04_01 | yiLiu | — | 4 | 50 | 0 | 0 | 0 | 100.0% | 3.4 |
| stage_04_02 | yiLiu | — | 4 | 50 | 0 | 0 | 0 | 100.0% | 3.4 |
| stage_04_03 | yiLiu | — | 4 | 50 | 0 | 0 | 0 | 100.0% | 3.4 |
| stage_04_04 | yiLiu | Boss | 4 | 50 | 0 | 0 | 0 | 100.0% | 3.4 |
| stage_04_05 | yiLiu | Boss | 4 | 50 | 0 | 0 | 0 | 100.0% | 5.5 |
| stage_05_01 | jueDing | — | 5 | 50 | 0 | 0 | 0 | 100.0% | 2.4 |
| stage_05_02 | jueDing | — | 5 | 50 | 0 | 0 | 0 | 100.0% | 3.9 |
| stage_05_03 | jueDing | — | 5 | 50 | 0 | 0 | 0 | 100.0% | 3.9 |
| stage_05_04 | jueDing | Boss | 5 | 50 | 0 | 0 | 0 | 100.0% | 4.1 |
| stage_05_05 | jueDing | Boss | 5 | 50 | 0 | 0 | 0 | 100.0% | 6.2 |
| stage_06_01 | zongShi | — | 6 | 50 | 0 | 0 | 0 | 100.0% | 2.2 |
| stage_06_02 | zongShi | — | 6 | 50 | 0 | 0 | 0 | 100.0% | 2.9 |
| stage_06_03 | zongShi | — | 6 | 50 | 0 | 0 | 0 | 100.0% | 3.1 |
| stage_06_04 | zongShi | Boss | 6 | 50 | 0 | 0 | 0 | 100.0% | 3.3 |
| stage_06_05 | zongShi | Boss | 6 | 50 | 0 | 0 | 0 | 100.0% | 4.5 |

## 卡点 / 秒杀点诊断

- **卡点**(winRate < 30%):玩家难过 → 数值上调候选

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

- **玩家走真 build**(2026-05-29 升级):`BattleCharacter.fromCharacter` derived_stats 生产路径 · 活跃玩家模型(tier-cap 真装备 midpoint base + 中等强化 ½ 上限 + 共鸣默契 ×1.20 解锁人剑合一 + 主修 daCheng + founder buff)
- **单一代表 build**:只跑「活跃玩家」一档,不验欠配置 floor / 满配 ceiling 区间(留 C 方案双 build 对照扩展)
- **不含辅修 synergy**(心法相生):只主修单本,SynergyService 未注入
- 流派固定刚猛 gangMeng · 不验阴柔/灵巧分布
- **playerTier = requiredRealm + 1**(既有校准偏移「玩家超阶挑战」):真 build 下可能与超阶叠加偏易 → 校准复核候选(本批只换 build 真实性不动偏移)
- maxTicks=200 兜底(timeout = 不分胜负)

**用途**:卡点 / 秒杀点 **方向性**诊断 · 真 build 后数值更贴近活跃玩家实战。
