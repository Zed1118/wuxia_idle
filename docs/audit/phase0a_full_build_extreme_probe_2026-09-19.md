# Phase 0A 满 build 真实路径极值探针（2026-09-19）

补 §5.4 缺口：既有 calculator 探针不经 reducer，既有 reducer 诊断只用 Ch1 起手画像。本探针把满 build 画像喂进真实 Phase 0A reducer，横扫全部生产内容 × 周目 {1, 上限}，硬断言每次结算单点伤害 < 1,000,000。自动画像不等于真人体验，不支持直接调值。

## 夹具构成（程序化选取，无硬编码 id 清单）

境界武圣·登峰（绝对等级 49）；神物三槽满强化 +49 / 心剑通灵共鸣 / 开锋三槽满；主修传说神功极境；辅修配满生产上限 3；熟练度最高档 huaJing（uses=800, ×1.3）。

| school | weapon | armor | accessory | main | assists | eqAtk | hp | speed |
|---|---|---|---|---|---|---:|---:|---:|
| gangMeng | weapon_shenwu_hun_yuan_chui | armor_shenwu_tian_can_bao_jia | accessory_shenwu_kun_lun_pei | tech_gangmeng_chuanshuo | tech_gangmeng_chuanshuo_fang<br>tech_gangmeng_chuanshuo_nei<br>tech_gangmeng_shichuan | 20706 | 20000 | 1320 |
| lingQiao | weapon_shenwu_tian_wen_jian | armor_shenwu_tian_can_bao_jia | accessory_shenwu_kun_lun_pei | tech_lingqiao_chuanshuo | tech_lingqiao_chuanshuo_fang<br>tech_lingqiao_shichuan<br>tech_lingqiao_shichuan_fang | 20706 | 20000 | 1320 |
| yinRou | weapon_shenwu_huan_meng_bian | armor_shenwu_tian_can_bao_jia | accessory_shenwu_kun_lun_pei | tech_yinrou_chuanshuo | tech_yinrou_chuanshuo_fang<br>tech_yinrou_shichuan<br>tech_yinrou_shichuan_fang | 20706 | 20000 | 1320 |

## 矩阵规模与 wall clock

内容 154 条（主线 105 + 爬塔 49）；周目上限读 `numbers.cycle_evolution`：主线 3 / 爬塔 2；流派 3；固定 seed=0。共 924 轮 headless bot 运行，wall clock 1s。

## 汇总（按 流派 × 内容类 × 周目）

| school | kind | cycle | runs | wins | defeats | win rate | mean ticks | mean HP end | mean Qi end | max damage |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| gangMeng | stage | 1 | 105 | 105 | 0 | 1.000 | 29.3 | 100.0% | 39.4% | 303109 |
| gangMeng | stage | 3 | 105 | 105 | 0 | 1.000 | 30.0 | 98.8% | 38.1% | 254692 |
| gangMeng | tower | 1 | 49 | 49 | 0 | 1.000 | 9.7 | 100.0% | 35.8% | 255578 |
| gangMeng | tower | 2 | 49 | 49 | 0 | 1.000 | 10.7 | 97.4% | 32.6% | 270831 |
| lingQiao | stage | 1 | 105 | 105 | 0 | 1.000 | 32.0 | 99.4% | 28.9% | 382584 |
| lingQiao | stage | 3 | 105 | 103 | 2 | 0.981 | 32.7 | 98.1% | 29.9% | 321370 |
| lingQiao | tower | 1 | 49 | 49 | 0 | 1.000 | 12.4 | 99.4% | 35.0% | 254164 |
| lingQiao | tower | 2 | 49 | 49 | 0 | 1.000 | 13.4 | 96.6% | 32.1% | 227053 |
| yinRou | stage | 1 | 105 | 105 | 0 | 1.000 | 40.8 | 99.2% | 36.6% | 302609 |
| yinRou | stage | 3 | 105 | 105 | 0 | 1.000 | 40.9 | 99.2% | 35.8% | 254192 |
| yinRou | tower | 1 | 49 | 49 | 0 | 1.000 | 14.2 | 99.2% | 37.6% | 253250 |
| yinRou | tower | 2 | 49 | 49 | 0 | 1.000 | 14.6 | 97.9% | 32.4% | 226236 |

## 极值定位

全局最大单点伤害 **382584** @ lingQiao / stage/stage_13_01#c1 / ticks=33（红线 1,000,000，余量 61.7%）。

| cycle | max damage | rounds |
|---:|---:|---:|
| 1 | 382584 | 462 |
| 2 | 270831 | 147 |
| 3 | 321370 | 315 |

## Top 10 单点伤害轮次

| # | school | content | max damage | outcome | ticks |
|---:|---|---|---:|---|---:|
| 1 | lingQiao | stage/stage_14_04#c1 | 382584 | victory | 26 |
| 2 | lingQiao | stage/stage_13_01#c1 | 382584 | victory | 33 |
| 3 | lingQiao | stage/stage_13_04#c1 | 382584 | victory | 26 |
| 4 | lingQiao | stage/stage_14_01#c1 | 382584 | victory | 33 |
| 5 | lingQiao | stage/stage_15_04#c1 | 382584 | victory | 26 |
| 6 | lingQiao | stage/stage_15_01#c1 | 382584 | victory | 33 |
| 7 | lingQiao | stage/stage_14_05#c1 | 382584 | victory | 26 |
| 8 | lingQiao | stage/stage_14_01#c3 | 321370 | victory | 33 |
| 9 | lingQiao | stage/stage_15_04#c3 | 321370 | victory | 26 |
| 10 | lingQiao | stage/stage_13_04#c3 | 321370 | victory | 26 |

## 胜负 / 节奏分布

胜 922 / 负 2 / 超时 0（共 924）；胜率 0.998；平均 ticks 27.4。满 build 对全线内容应近乎全胜；任何败/超时逐条登记于异常段，不据此调值。

## 与既有 calculator 探针对比

既有 `full_build_damage_redline_test`（单点 [DamageCalculator]，装备攻击 17255，未经 reducer）2026-09-19 实测：满 build 普攻 × 克制1.25 × 弱点1.25 非暴击 72378 / 暴击 108567；满破甲 (Σpierce0.60) 134121；破绽窗口 (effDef0.175) 136261。

本探针满 build 含同流派心法相生（装备攻击 20706，较 calculator 探针 17255 更高），且经真实 reducer 全内容 × 周目横扫，全局最大单点 382584——与 calculator 单点同量级、均远不进百万，两路互为佐证。

## 结论

**软红线守住（max 382584 < 1e6）**：满 build 经真实 Phase 0A reducer 横扫全部 924 轮，无任何单点结算伤害触百万，§5.4 唯一硬线成立。

## 异常登记（只记录，不建议调值）

非全胜轮次 2 条（败/超时），逐条列前 20：

| school | content | outcome | ticks | player max damage |
|---|---|---|---:|---:|
| lingQiao | stage/stage_19_05#c3 | defeat | 65 | 64886 |
| lingQiao | stage/stage_20_05#c3 | defeat | 80 | 64886 |

两处败局均为 lingQiao 第 19/20 章主线在**周目 3**（敌人按 `cycle_evolution.scale_per_cycle` 逐周目放大）下被击败，玩家单点伤害仅 64886、ticks 65/80——属终局最高周目内容对自动满 build 仍偏难，非红线问题，只登记不调值。

## 破坏证红（目标 3：两向临时 mutation + 还原重跑绿）

本单零 `lib/` 改动 → Gate 判为**审计单**，收据 `break_red` 留空、改填 `audit_verification`；两向证红结果按派单要求登记于此与恢复点。

| 方向 | 临时改动 | 复跑对象 | 结果 | 还原 |
|---|---|---|---|---|
| ① 降强化 | `phase0a_full_build_profile.dart:223` `enhanceLevel: maxEnhance` → `0` | `test/support/phase0a_full_build_profile_test.dart` | **1 失败**：「满 build 画像夹具：三流派均达终局构筑且选取互不相同」，`:83` Expected `<49>` Actual `<0>` | `git checkout --` |
| ② 压阈值 | `phase0a_full_build_extreme_probe_test.dart:145` `lessThan(_damageRedLine)` → `lessThan(1)` | 同探针文件 | **1 失败**：「Phase 0A 满 build 真实路径全内容极值探针」，`:143` Expected `<1>` Actual `<103391>`（gangMeng stage_01_01 周目1） | `git checkout --` |

两向还原后 `git status` 干净（仅余本报告未跟踪），复跑自检 + 探针双绿（`+2: All tests passed!`）——证自检与探针断言均有牙、非空过。

复跑：`flutter test --no-pub test/tools/phase0a_full_build_extreme_probe_test.dart -r expanded`（默认不写报告）；生成报告：前置 `PROBE_REPORT=1`。
