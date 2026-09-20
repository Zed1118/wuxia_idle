# Phase 0A Ch1 real-skill profile · refreshed 2026-08-21

headless bot ≠ 真人；三个 profile 来自生产创建页，origin=mountain_wanderer，fate=balanced_seed，固定 rngSeed=20260820。
当前 Ch1 autoFill 槽事实由生产 snapshot 生成；本批只调整三本入门心法的招式开放层，不调伤害、敌人与全局门槛。delta=0.1s，maxTicks=3000。

## Production loadout

- `gang_meng`: basic=skill_gangmeng_jichu_basic; main1=skill_gangmeng_jichu_skill; main2=skill_gangmeng_jichu_basic; assist=-; resonance=-; ultimate=-; encounter=-
- `ling_qiao`: basic=skill_lingqiao_jichu_basic; main1=skill_lingqiao_jichu_skill; main2=skill_lingqiao_jichu_basic; assist=-; resonance=-; ultimate=-; encounter=-
- `yin_rou`: basic=skill_yinrou_jichu_basic; main1=skill_yinrou_jichu_skill; main2=skill_yinrou_jichu_basic; assist=-; resonance=-; ultimate=-; encounter=-

| profile | stage | runs | wins | defeats | timeouts | winRate | mean ticks | p50 | p90 | mean HP% | mean Qi% | max damage |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|gang_meng|stage_01_01|100|100|0|0|100.0%|13.6|13.0|13.0|99.8%|0.0%|1245|
|gang_meng|stage_01_02|100|100|0|0|100.0%|20.4|19.0|25.0|95.5%|0.0%|1245|
|gang_meng|stage_01_03|100|100|0|0|100.0%|25.2|25.0|31.0|79.4%|0.0%|1245|
|gang_meng|stage_01_04|100|100|0|0|100.0%|26.6|25.0|31.0|70.6%|0.0%|934|
|gang_meng|stage_01_05|100|100|0|0|100.0%|19.6|19.0|25.0|96.6%|0.0%|2446|
|ling_qiao|stage_01_01|100|100|0|0|100.0%|11.9|13.0|13.0|99.8%|12.5%|2044|
|ling_qiao|stage_01_02|100|100|0|0|100.0%|16.8|19.0|19.0|98.7%|12.5%|2044|
|ling_qiao|stage_01_03|100|100|0|0|100.0%|16.8|19.0|19.0|98.7%|12.5%|2044|
|ling_qiao|stage_01_04|100|100|0|0|100.0%|16.8|19.0|19.0|98.4%|12.5%|1635|
|ling_qiao|stage_01_05|100|4|96|0|4.0%|37.3|36.0|47.0|1.5%|12.5%|920|
|yin_rou|stage_01_01|100|100|0|0|100.0%|19.6|19.0|25.0|93.0%|15.0%|930|
|yin_rou|stage_01_02|100|100|0|0|100.0%|25.2|25.0|31.0|64.6%|15.0%|930|
|yin_rou|stage_01_03|100|98|2|0|98.0%|32.8|31.0|37.0|44.6%|15.0%|930|
|yin_rou|stage_01_04|100|100|0|0|100.0%|19.6|19.0|25.0|97.0%|15.0%|1551|
|yin_rou|stage_01_05|100|98|2|0|98.0%|32.8|31.0|37.0|55.6%|15.0%|1241|

## Skill usage totals

| profile | basic c/d | Q c/d | R c/d | 1 c/d | 2 c/d | 3 c/d | 4 c/d | 5 c/d | 6 c/d |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|gang_meng|2174/1548936|500/0|0/0|500/0|0/0|0/0|0/0|0/0|0/0|
|ling_qiao|1997/1423792|500/0|0/0|0/0|0/0|0/0|0/0|0/0|0/0|
|yin_rou|2580/1490978|500/0|0/0|0/0|0/0|0/0|0/0|0/0|0/0|

## Automatic observations

- timeout: 0/1500.
- numeric 1–6 casts: 500.
- lowest bot win rate: `ling_qiao/stage_01_05` 4.0%.
- max resolved damage: 2446 (< 1,000,000).
