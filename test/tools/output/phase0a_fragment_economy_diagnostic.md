# Phase 0A 残页经济只读诊断

基线：`44461288`；固定 Monte Carlo seed：`20260823`；试验次数：`100000`；未集齐率观察窗口：`100` 次重复刷。

生产读取值：`fragment_threshold=5`，`tower_fragment_drop_prob=0.2`。
来源：`GameRepository.loadAllDefs()` → `data/numbers.yaml`、`data/towers.yaml`、`data/stages.yaml`。

## 主线首通真解

主线 Boss 首通真解是必得，不进入概率 Monte Carlo；重复刷均值、分位数和未集齐率不适用。

| 技能 ID | 名称 | 来源 |
|---|---|---|
| `skill_chen_sha_yi_jue` | 沉沙一诀 | 主线 Boss 首通真解 |
| `skill_feng_juan_liu_sha` | 风卷流沙 | 主线 Boss 首通真解 |
| `skill_gu_cheng_bi` | 孤城闭 | 主线 Boss 首通真解 |
| `skill_gu_cheng_kai` | 孤城开 | 主线 Boss 首通真解 |
| `skill_hui_xiu_hui_feng` | 灰袖回风 | 主线 Boss 首通真解 |
| `skill_liu_jin_jue` | 鎏金诀 | 主线 Boss 首通真解 |
| `skill_mian_li_cang_zhen` | 绵里藏针 | 主线 Boss 首通真解 |
| `skill_ping_sha_luo_yan` | 平沙落雁 | 主线 Boss 首通真解 |
| `skill_qian_jun_zhui_yue` | 千钧坠岳 | 主线 Boss 首通真解 |
| `skill_qingshan_qingfeng` | 青锋绝 | 主线 Boss 首通真解 |
| `skill_shan_wai_wu_shan` | 山外无山 | 主线 Boss 首通真解 |
| `skill_shi_dang_shi_jue` | 十荡十决 | 主线 Boss 首通真解 |
| `skill_tie_ma_bing_he` | 铁马冰河 | 主线 Boss 首通真解 |
| `skill_xie_yu_chuan_lian` | 斜雨穿帘 | 主线 Boss 首通真解 |
| `skill_yang_guan_wu_gu_ren` | 阳关无故人 | 主线 Boss 首通真解 |
| `skill_yi_jing_shuang_zhao` | 一镜双照 | 主线 Boss 首通真解 |
| `skill_yi_lan_zhong_shan` | 一览众山 | 主线 Boss 首通真解 |
| `skill_zhi_shui_jue` | 止水诀 | 主线 Boss 首通真解 |

## 爬塔残页

每个技能按其映射塔 Boss 的重复胜利次数统计；每次胜利以生产概率独立投掷，集齐阈值从生产配置读取。

| 技能 ID | 名称 | 均值 | P50 | P90 | P95 | 未集齐率 |
|---|---|---:|---:|---:|---:|---:|
| `skill_guan_shan_ba_ji` | 关山拔戟 | 25.05091 | 24.0 | 38.0 | 44.0 | 0.0 |
| `skill_jin_gang_fu_mo` | 金刚伏魔 | 24.97111 | 23.0 | 38.0 | 44.0 | 0.0 |
| `skill_kai_bei_shou` | 开碑手 | 24.99511 | 23.0 | 38.0 | 44.0 | 0.0 |
| `skill_ma_ta_fei_yan` | 马踏飞燕 | 24.96716 | 24.0 | 38.0 | 44.0 | 0.0 |
| `skill_yan_zi_san_chao` | 燕子三抄 | 24.97158 | 23.0 | 38.0 | 43.0 | 0.0 |

### 全部塔残页技能集齐

| 均值 | P50 | P90 | P95 | 未集齐率 |
|---:|---:|---:|---:|---:|
| 37.52778 | 36.0 | 50.0 | 54.0 | 0.00002 |

“全部集齐”按每个塔残页技能分别刷其映射 Boss，并取所有技能完成所需刷数的最大值；不是把不同 Boss 的掉落池错误合并为一个池。
