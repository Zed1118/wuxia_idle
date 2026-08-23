# Phase 0A 残页经济只读诊断

基线：`44461288`。本证据只读取生产仓储加载后的配置，不修改 `lib/`、`data/`、玩法数值或现有测试。
塔残页配置：fragmentThreshold=5，towerFragmentDropProb=0.200000。
Monte Carlo：固定 seed 基础值 `20260823`（按塔层偏移）、每项 `20000` 次试验、单次最多 `100` 次重复刷；未在上限内集齐计入未集齐率。P50/P90/P95 使用已集齐样本的 nearest-rank。

## 主线首通真解（必得，非概率残页）

| skill | location | threshold | probability | runs | completed | mean | P50 | P90 | P95 | uncollected |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|斜雨穿帘 (`skill_xie_yu_chuan_lian`)|stage_01_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|青锋绝 (`skill_qingshan_qingfeng`)|stage_02_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|千钧坠岳 (`skill_qian_jun_zhui_yue`)|stage_07_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|灰袖回风 (`skill_hui_xiu_hui_feng`)|stage_08_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|沉沙一诀 (`skill_chen_sha_yi_jue`)|stage_09_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|止水诀 (`skill_zhi_shui_jue`)|stage_10_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|鎏金诀 (`skill_liu_jin_jue`)|stage_11_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|绵里藏针 (`skill_mian_li_cang_zhen`)|stage_12_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|一览众山 (`skill_yi_lan_zhong_shan`)|stage_13_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|十荡十决 (`skill_shi_dang_shi_jue`)|stage_14_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|孤城闭 (`skill_gu_cheng_bi`)|stage_15_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|铁马冰河 (`skill_tie_ma_bing_he`)|stage_16_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|风卷流沙 (`skill_feng_juan_liu_sha`)|stage_17_04|—|必得|1|1|1.0000|1|1|1|0.0000%|
|平沙落雁 (`skill_ping_sha_luo_yan`)|stage_17_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|阳关无故人 (`skill_yang_guan_wu_gu_ren`)|stage_18_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|一镜双照 (`skill_yi_jing_shuang_zhao`)|stage_19_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|孤城开 (`skill_gu_cheng_kai`)|stage_20_05|—|必得|1|1|1.0000|1|1|1|0.0000%|
|山外无山 (`skill_shan_wai_wu_shan`)|stage_21_05|—|必得|1|1|1.0000|1|1|1|0.0000%|

## 塔 Boss 概率残页

| skill | location | threshold | probability | runs | completed | mean | P50 | P90 | P95 | uncollected |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|开碑手 (`skill_kai_bei_shou`)|tower_4|5|0.200000|20000|20000|24.9893|24|38|44|0.0000%|
|燕子三抄 (`skill_yan_zi_san_chao`)|tower_7|5|0.200000|20000|20000|24.8267|23|38|43|0.0000%|
|关山拔戟 (`skill_guan_shan_ba_ji`)|tower_11|5|0.200000|20000|20000|25.0681|24|38|44|0.0000%|
|金刚伏魔 (`skill_jin_gang_fu_mo`)|tower_14|5|0.200000|20000|20000|24.8895|23|38|43|0.0000%|
|马踏飞燕 (`skill_ma_ta_fei_yan`)|tower_32|5|0.200000|20000|19999|25.0282|24|38|44|0.0050%|

## 解释边界

- 主线首通真解单独列为一次首通必得，不与塔残页的重复刷分布混算。
- 塔统计描述按当前配置重复挑战对应 Boss 层的残页经济；不代表普通层奖励、首通经验或其他掉落。
- 本诊断不据此自动调节阈值、概率或任何战斗/经济数值。
