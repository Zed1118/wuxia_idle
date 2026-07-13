# 成长路径与四属性体感体检 · 2026-07-13

## 运行元数据

- evidence commit：`654c317acfca28b2cff492b52f226c299c648c86`
- data tree：`c0c557d1f57dfa97e81ef386eb63bd33042f09e2`（`git rev-parse HEAD:data`）
- Flutter：3.41.5 stable，framework `2c9eb20739`；Dart 3.11.3，DevTools 2.54.2
- 执行时间与时区：2026-07-13 19:35:19 CST（UTC+08:00）
- 战斗种子：0～19；主线矩阵：30 关 × 3 配置 × 20 seed = 1800 observations
- 执行耗时：主线 evidence commit 复跑 6.58 秒；六份专项联合集 18.15 秒
- 本轮主线实际最大 tick：24；这是 evidence commit 的软观察值，不设永久 `<240` 断言，真正未完成的 tick-cap 仍由共享 runner 分类并抛错
- 生产代码修改：否；相对本计划无修改基线 `0b5d4b234f9630b43dfda9ce9b8ed1d81e3e2bbf`，`lib/` 与 `data/` 文件均无变化（`lib/` 文件清单：无）
- 证据测试：主线诊断 1/1 PASS；指定六文件专项 33/33 PASS；额外共享结算行为 4/4 PASS
- 质量复核修订：committed CSV 仍是 evidence commit `654c317a` 的原始字节，SHA-256 为 `dc2308ffd225a1457cbcdb5982d9ee79e6f6bca6cdcf22f8bec4cc11db912316`；本修订只改默认写入边界与统计显示精度，不改原始数据或软观察结论

## 硬契约结论

- **Lv1～Lv490 / 49 层：通过。** `progression_full_path_contract_test.dart` 4/4 PASS：49 个真实层逐层映射 490 个展示等级；48 次相邻层跃迁逐项刷新 `RealmDef` 镜像；锁定溢出留账后只升到下一真实层；武圣·登峰停在 Lv490，不生成第 50 层。
- **七类经验入口：通过。** `experience_source_consistency_test.dart` 4/4 PASS，覆盖 **5 个接线点 / 7 个场景**：主线首通、主线重打、塔首通、塔重打、闭关、普通离线、经验丹。主线和塔的四种场景证据是 AST 策略参数与共享结算调用；`combat_progression_settlement_service_test.dart` 另有 4/4 PASS，证明共享结算按稳定角色 ID 入账、零奖励不变异且事务回滚无部分事件。这里未宣称 `runStageFlow` / `runTowerFlow` 四案 E2E。
- **心魔锁与终境：通过。** 全路径契约中的锁定溢出与终境两案均通过；锁定时 tier/layer 与经验镜像不漂移，经验保留，解锁后按真实下一层门槛结算；终境保留全部经验并维持武圣·登峰/Lv490。
- **四属性职责：通过。** `attribute_role_sensitivity_diagnostic_test.dart` 15/15 PASS：根骨影响血量与新生成重伤时长；悟性影响修炼、熟练度成长、熟练度伤害与领悟；身法影响速度/闪避且不改暴击；机缘影响普通奇遇与显式门槛，不泄漏到血量、闪避、暴击、确定性伤害或掉落。
- **机制专项：通过。** 心魔 05/06 的 5 个测试、心魔 07 的 4 个测试、塔坡度的 1 个测试均在同一 evidence commit 通过；与上述 4 + 4 + 15 个测试合计为指定六文件专项 33/33 PASS。

## 软观察

### 主线三档配置

`undergeared` 与 `nearMax` 是沿用历史诊断的低/高投入**样本名**，不表示“没装备”或“全部拉满”。三档都使用关卡要求境界的化境三人队、对应阶装备与刚猛心法；每个成员都有武器、护甲、饰品与主心法。战斗入场还统一经过 `StageBattleSetup.debugApplyReadableFirstClearTuning`，因此本矩阵是 readable-first-clear 首通调优样本，不代表未调优的正式主线全体玩家分布。

| profile | 强化比例 | battleCount | 心法修炼层 | 根骨/悟性/身法/机缘 | 属性总和/稀有度 | 祖师 buff |
|---|---:|---:|---|---|---|---|
| undergeared | 0 | 0 | 中成 | 5/5/5/5 | 20/标准 | 否 |
| standard | 0.25 | 150 | 中成 | 5/5/5/5 | 20/标准 | 否 |
| nearMax | 0.50 | 400 | 大成 | 6/5/6/5 | 22/自由 | 是 |

代表 def 按 repository/YAML 插入顺序选取，并在本 commit 绑定如下 ID：

| 境界阶 | 武器 / 护甲 / 饰品 | 刚猛心法 |
|---|---|---|
| 学徒 | `weapon_xunchang_tie_jian` / `armor_xunchang_bu_yi` / `accessory_xunchang_yu_pei` | `tech_gangmeng_jichu` |
| 三流 | `weapon_xiangyang_gang_dao` / `armor_xiangyang_pi_jia` / `accessory_xiangyang_yin_jie` | `tech_gangmeng_changlian` |
| 二流 | `weapon_haojiahuo_qing_feng_jian` / `armor_haojiahuo_jin_pao` / `accessory_haojiahuo_yu_pei_lao` | `tech_gangmeng_mingjia` |
| 一流 | `weapon_liqi_long_quan` / `armor_liqi_xuan_tie_jia` / `accessory_liqi_fei_yu_pei` | `tech_gangmeng_menpai` |
| 绝顶 | `weapon_zhongqi_po_zhen_chui` / `armor_zhongqi_yin_lin_jia` / `accessory_zhongqi_qing_yu_huan` | `tech_gangmeng_jianghu` |
| 宗师 | `weapon_baowu_xuan_tian_fu` / `armor_baowu_jin_si_jia` / `accessory_baowu_yu_long_pei` | `tech_gangmeng_shichuan` |
| 武圣 | `weapon_shenwu_po_jun_dao` / `armor_shenwu_xuan_huang_pao` / `accessory_shenwu_kun_lun_pei` | `tech_gangmeng_chuanshuo` |

聚合统计如下。平均 ticks 由原始 CSV 重算，并按诊断代码的 Dart `toStringAsFixed(3)` 显示；HP 结束比例按每场 `player_hp_end / player_hp_start` 后取平均；HP 与 Qi 原字段名保留计划约定，实际含义均为玩家三人队总量。

| profile | 样本 | leftWin/rightWin/draw | 胜率 | 平均 ticks | 平均 actionRows | 平均 HP 结束比例 | 平均 Qi start/end/delta |
|---|---:|---:|---:|---:|---:|---:|---:|
| undergeared | 600 | 600/0/0 | 100.00% | 9.715 | 6.34 | 93.90% | 135.00 / 168.33 / +33.33 |
| standard | 600 | 600/0/0 | 100.00% | 8.610 | 5.94 | 94.73% | 135.00 / 173.23 / +38.23 |
| nearMax | 600 | 600/0/0 | 100.00% | 6.857 | 4.85 | 97.14% | 135.00 / 185.60 / +50.60 |

下表给出每关可定位数据，单元格依次为 `leftWin/样本 / 平均ticks / 平均actionRows / 平均HP结束比例 / 平均Qi delta`：

| stage | undergeared | standard | nearMax |
|---|---:|---:|---:|
| stage_01_01 | 20/20 / 8.750 / 3.55 / 98.29% / +68.15 | 20/20 / 8.750 / 3.55 / 98.31% / +68.15 | 20/20 / 8.500 / 3.35 / 98.54% / +65.50 |
| stage_01_02 | 20/20 / 14.000 / 5.25 / 92.69% / +50.75 | 20/20 / 14.000 / 5.25 / 92.77% / +50.75 | 20/20 / 11.800 / 4.65 / 94.99% / +58.80 |
| stage_01_03 | 20/20 / 14.300 / 6.30 / 91.68% / +28.75 | 20/20 / 14.300 / 6.30 / 91.77% / +28.75 | 20/20 / 13.000 / 5.70 / 93.43% / +40.85 |
| stage_01_04 | 20/20 / 12.950 / 4.75 / 91.86% / +57.95 | 20/20 / 12.950 / 4.75 / 91.95% / +57.95 | 20/20 / 8.500 / 3.55 / 98.07% / +68.15 |
| stage_01_05 | 20/20 / 8.750 / 6.40 / 94.55% / +70.25 | 20/20 / 7.000 / 5.20 / 94.61% / +58.50 | 20/20 / 7.000 / 5.20 / 95.35% / +58.50 |
| stage_02_01 | 20/20 / 12.600 / 7.00 / 91.54% / +5.25 | 20/20 / 12.250 / 6.40 / 91.74% / +19.25 | 20/20 / 11.000 / 5.75 / 92.87% / +34.50 |
| stage_02_02 | 20/20 / 12.900 / 7.10 / 92.96% / +4.00 | 20/20 / 12.500 / 7.00 / 93.13% / +5.25 | 20/20 / 11.250 / 6.15 / 94.08% / +25.50 |
| stage_02_03 | 20/20 / 12.000 / 5.80 / 91.91% / +33.25 | 20/20 / 12.000 / 5.30 / 92.11% / +45.75 | 20/20 / 11.000 / 5.25 / 93.19% / +47.00 |
| stage_02_04 | 20/20 / 12.000 / 5.85 / 92.89% / +32.00 | 20/20 / 12.000 / 5.80 / 93.06% / +33.25 | 20/20 / 11.000 / 5.25 / 94.01% / +47.00 |
| stage_02_05 | 20/20 / 18.900 / 13.60 / 88.38% / -49.75 | 20/20 / 16.750 / 11.80 / 86.77% / -44.25 | 20/20 / 14.250 / 10.45 / 88.58% / -17.25 |
| stage_03_01 | 20/20 / 11.000 / 5.25 / 93.41% / +47.00 | 20/20 / 10.000 / 5.25 / 93.72% / +47.00 | 20/20 / 6.000 / 3.55 / 98.71% / +67.25 |
| stage_03_02 | 20/20 / 11.000 / 5.30 / 94.29% / +45.75 | 20/20 / 10.000 / 5.25 / 94.56% / +47.00 | 20/20 / 8.200 / 4.65 / 96.23% / +56.25 |
| stage_03_03 | 20/20 / 10.250 / 4.75 / 96.13% / +55.25 | 20/20 / 9.250 / 4.75 / 96.31% / +55.25 | 20/20 / 6.000 / 3.55 / 99.09% / +67.25 |
| stage_03_04 | 20/20 / 7.250 / 3.55 / 98.59% / +67.25 | 20/20 / 6.250 / 3.40 / 98.66% / +63.50 | 20/20 / 5.200 / 2.20 / 99.77% / +50.75 |
| stage_03_05 | 20/20 / 10.250 / 7.00 / 99.72% / +44.75 | 20/20 / 9.250 / 7.00 / 99.73% / +44.75 | 20/20 / 6.000 / 5.55 / 99.77% / +66.25 |
| stage_04_01 | 20/20 / 9.200 / 6.00 / 93.17% / +29.75 | 20/20 / 8.000 / 5.85 / 94.24% / +32.00 | 20/20 / 6.400 / 4.85 / 96.09% / +51.00 |
| stage_04_02 | 20/20 / 9.200 / 6.20 / 92.84% / +24.50 | 20/20 / 8.000 / 5.85 / 94.20% / +32.00 | 20/20 / 7.000 / 5.25 / 95.10% / +47.00 |
| stage_04_03 | 20/20 / 9.000 / 5.80 / 93.94% / +33.25 | 20/20 / 8.000 / 5.25 / 94.39% / +47.00 | 20/20 / 6.400 / 4.65 / 96.19% / +56.25 |
| stage_04_04 | 20/20 / 9.000 / 5.25 / 93.44% / +47.00 | 20/20 / 7.400 / 4.95 / 94.81% / +50.00 | 20/20 / 4.750 / 3.55 / 98.75% / +67.25 |
| stage_04_05 | 20/20 / 8.000 / 7.30 / 99.79% / +48.80 | 20/20 / 5.550 / 7.00 / 99.81% / +51.65 | 20/20 / 3.500 / 5.30 / 100.00% / +67.80 |
| stage_05_01 | 20/20 / 8.150 / 6.00 / 94.01% / +41.45 | 20/20 / 6.000 / 5.30 / 95.21% / +53.55 | 20/20 / 4.600 / 3.90 / 100.00% / +56.15 |
| stage_05_02 | 20/20 / 9.050 / 7.80 / 89.13% / +13.45 | 20/20 / 6.750 / 7.20 / 93.23% / +16.95 | 20/20 / 5.150 / 5.30 / 99.73% / +30.50 |
| stage_05_03 | 20/20 / 8.450 / 7.10 / 93.04% / +22.45 | 20/20 / 6.150 / 6.30 / 94.34% / +35.50 | 20/20 / 5.000 / 5.25 / 95.53% / +54.50 |
| stage_05_04 | 20/20 / 8.000 / 5.85 / 93.40% / +43.10 | 20/20 / 6.000 / 5.30 / 94.13% / +53.55 | 20/20 / 4.600 / 4.65 / 96.09% / +61.35 |
| stage_05_05 | 20/20 / 6.000 / 7.30 / 99.75% / +41.00 | 20/20 / 4.700 / 7.00 / 99.79% / +44.75 | 20/20 / 2.500 / 5.30 / 100.00% / +66.00 |
| stage_06_01 | 20/20 / 6.000 / 5.30 / 95.54% / +45.75 | 20/20 / 5.000 / 5.25 / 96.13% / +47.00 | 20/20 / 2.500 / 3.30 / 100.00% / +66.00 |
| stage_06_02 | 20/20 / 6.150 / 6.00 / 94.60% / +29.75 | 20/20 / 5.000 / 5.30 / 95.78% / +45.75 | 20/20 / 3.600 / 3.90 / 100.00% / +50.75 |
| stage_06_03 | 20/20 / 6.750 / 7.60 / 89.44% / -5.25 | 20/20 / 5.300 / 7.00 / 94.28% / +12.75 | 20/20 / 4.000 / 4.85 / 100.00% / +27.00 |
| stage_06_04 | 20/20 / 6.150 / 6.40 / 90.37% / +19.50 | 20/20 / 5.100 / 6.15 / 92.44% / +26.75 | 20/20 / 4.000 / 4.30 / 100.00% / +40.75 |
| stage_06_05 | 20/20 / 5.450 / 8.90 / 95.72% / +4.75 | 20/20 / 4.100 / 7.40 / 100.00% / +16.75 | 20/20 / 3.000 / 6.35 / 100.00% / +39.50 |

### 心魔 05/06/07

- `stage_inner_demon_05`：窗口臂 A 20/20 胜，平均胜利 tick 9.00，20/20 seed 进入蓄力；剥离窗口的 B 臂 20/20 胜、平均 tick 4.30，A/B=2.09×；高爆发 BiS 17/20 胜、平均胜利 tick 14.65。
- `stage_inner_demon_06`：与 05 的本轮固定 seed 观察相同，A 20/20、平均 9.00、蓄力 20/20；B 20/20、平均 4.30，A/B=2.09×；BiS 17/20、平均 14.65。
- `stage_inner_demon_07`：on-level 20/20 经击败通道在 tick 9 获胜；turtle 20/20 经生存通道在 tick 20 获胜且右队未团灭；高爆发 BiS 13/20，失败 seed 为 0、1、2、8、11、13、14。该固定 seed 形状是机制软观察，不是硬平衡结论。

### 通天塔 24/25/29/30

| floor | profile | 胜率 | 平均 ticks | 平均玩家 HP 结束比例 | phase transitions | total base HP/attack |
|---:|---|---:|---:|---:|---:|---:|
| 24 | floor | 100.0% | 5 | 98.4% | 0 | 13350/2100 |
| 24 | ceiling | 100.0% | 4 | 100.0% | 0 | 13350/2100 |
| 25 | floor | 95.0% | 25 | 44.3% | 40 | 21600/3570 |
| 25 | ceiling | 100.0% | 10 | 76.4% | 40 | 21600/3570 |
| 29 | floor | 100.0% | 4 | 98.2% | 0 | 16050/2400 |
| 29 | ceiling | 100.0% | 3 | 100.0% | 0 | 16050/2400 |
| 30 | floor | 100.0% | 11 | 32.8% | 39 | 59500/4180 |
| 30 | ceiling | 100.0% | 5 | 100.0% | 37 | 59500/4180 |

### 四属性前/中/后 baseline → raised 原始值

根骨（5→8）同时走政策公式与真实 `InjuryService.applyBattleInjuries` 硬仗战败入口：

| 阶段 | policy 重伤小时 | InjuryService 重伤小时 | 最大 HP |
|---|---:|---:|---:|
| 前期 | 8.0→7.52 | 8.0→7.52 | 3597→4797 |
| 中期 | 8.0→7.52 | 8.0→7.52 | 6873→8073 |
| 后期 | 8.0→7.52 | 8.0→7.52 | 10149→11349 |

悟性（5→8）全部原始字段：

| 阶段 | effective usage | progress delta | boundary raw uses | boundary effective uses | encounter probability | CultivationService progress | proficiency damage | insight triggered |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 前期 | 100→106 | 50→53 | 29→29 | 29→30 | 0.5→0.5599999999999999 | 29→30 | 1519→1595 | 0→1 |
| 中期 | 100→106 | 50→53 | 29→29 | 29→30 | 0.5→0.5599999999999999 | 29→30 | 3712→3898 | 0→1 |
| 后期 | 100→106 | 50→53 | 29→29 | 29→30 | 0.5→0.5599999999999999 | 29→30 | 7731→8118 | 0→1 |

身法（5→8）全部原始字段：

| 阶段 | speed | evasion | critical |
|---|---:|---:|---:|
| 前期 | 140→164 | 0.015→0.024 | 0.075→0.075 |
| 中期 | 155→179 | 0.015→0.024 | 0.075→0.075 |
| 后期 | 200→224 | 0.015→0.024 | 0.075→0.075 |

机缘（5→8）全部原始字段；掉落为同 seed 真实 `BattleResolutionService.resolve` 完整结果快照比较：

| 阶段 | encounter probability | event triggered | 门槛8选项 | HP | evasion | critical | damage | drop count |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 前期 | 0.625→0.70 | 0→1 | 0→1 | 3597→3597 | 0.015→0.015 | 0.075→0.075 | 1519→1519 | 3→3 |
| 中期 | 0.625→0.70 | 0→1 | 0→1 | 6873→6873 | 0.015→0.015 | 0.075→0.075 | 3712→3712 | 3→3 |
| 后期 | 0.625→0.70 | 0→1 | 0→1 | 10149→10149 | 0.015→0.015 | 0.075→0.075 | 7731→7731 | 3→3 |

## 问题分级

- **P0：无。** 没有硬契约失败、加载失败、1800 场执行异常或 tick cap。
- **P1：无。** 没有确定性的职责串线、等级显示错误、经验落库错误或结算部分写入。
- **P2-1 候选：readable-first-clear 首通样本的胜负区分不足，可能偏宽松。** 复现范围为全部 `stage_01_01`～`stage_06_05`、三个 profile、seed 0～19；1800/1800 均为 leftWin。多配置、多 seed 支持“该首通调优夹具看不到失败压力”，但 undergeared 仍是同阶三件装备的低投入样本，nearMax 也不是全满；不能据此推导正式主线全体玩家过易或直接要求提高难度。本批不修改。
- **P2-2 候选：`stage_02_05` 相邻节拍与资源断崖。** 对 `stage_02_04 → stage_02_05 → stage_03_01`，undergeared / standard / nearMax 的平均 `ticks` 分别为 `12.000→18.900→11.000` / `12.000→16.750→10.000` / `11.000→14.250→6.000`；`actionRows` 为 `5.85→13.60→5.25` / `5.80→11.80→5.25` / `5.25→10.45→3.55`；HP 结束比例为 `92.89%→88.38%→93.41%` / `93.06%→86.77%→93.72%` / `94.01%→88.58%→98.71%`；Qi delta 为 `+32.00→-49.75→+47.00` / `+33.25→-44.25→+47.00` / `+47.00→-17.25→+67.25`。seed 级一致性核对：02_05 的 actionRows 峰值与 Qi delta 谷值在三档均为 20/20；ticks 峰值为 20/20、19/20、13/20，HP 谷值为 18/20、20/20、20/20。它可能是有意 Boss 峰值，现有证据不足以判定要削弱。本批不修改。
- **观察项：** 心魔 07 的 BiS 固定失败 seed 形状与塔 25 floor 的 95% 胜率保留为机制观察；未把单 seed 或单 profile 瞬时值升级为 P1/P2。

## 第一批处置

- P0/P1 均为无，因此第一批为**零生产代码修改**；没有改 `lib/`、`data/`、`numbers.yaml`、schema 或 save version。
- **第二批候选 P2-1：** 可能需要调整，是因为当前三档只体现 ticks、HP、Qi 差异而没有胜负差异；不调整则该测试矩阵继续无法识别主线失败压力过低。还需补真实存档在首通时的境界层、装备阶/强化、心法与属性分布，以及玩家首通失败率、重试率和退出点，才能决定是改数值还是扩充更真实的低投入 profile。当前暂无足够证据执行调整。
- **第二批候选 P2-2：** 可能需要调整，是因为 02_05 在三档 60 场都同时拉高节拍、动作并压低 Qi；不调整可能保留一处突兀资源耗尽感，但也可能正是章节 Boss 所需峰值。还需补真实玩家 02_04～03_01 连续首通录像/战报、主动招式使用和战后 Qi 可读性反馈，并与其他章节 Boss 的相邻关数据对比。当前暂无足够证据执行调整。

## 已知覆盖限制

- Task 3 的 AST 契约是语法级守卫，不做完整 scope/type resolution；当前对指定生产路径的 `.level` / `.levelExp` 成员访问采用零容忍，未来若同路径合法访问其他对象同名成员，仍需显式审查契约。
- 主线首通/重打与塔首通/重打四案只覆盖 AST 策略参数和共享结算行为，未覆盖 `runStageFlow` / `runTowerFlow` 四案 E2E。
- 主线 profile 的代表装备/心法受 repository/YAML 插入顺序影响；本报告同时绑定当前具体 def ID，YAML 重排后必须重新生成证据。
- CSV 的 `player_hp_start`、`player_hp_end`、`player_qi_start`、`player_qi_end` 沿用计划字段名，实际均为玩家三人队总量，不是单角色值。
- seed 0～19 是确定性诊断样本，不是玩家群体分布；profile 也不是实际存档遥测。
- 30 关均为每关独立重建、cycle 1、满入场资源的 readable-first-clear 横截面模拟；不覆盖连续闯关、装备实际获取时点、伤势或 Qi 跨关延续、战后结算。`stage_02_05` 的 Qi 负 delta 只表示该独立单场的资源谷值，不能外推连续流程中的战后 Qi 状态。

## 复现命令与 CSV

原始 CSV：`test/tools/output/progression_attribute_playtest_2026-07-13.csv`。默认测试只在系统临时目录验证生成内容，并保证 tracked CSV 的字节与 mtime 不变；只有显式设置更新变量时才原子更新 evidence 文件。

默认验证（CI/日常开发）：

```bash
shasum -a 256 test/tools/output/progression_attribute_playtest_2026-07-13.csv
stat -f '%m %Sm' test/tools/output/progression_attribute_playtest_2026-07-13.csv
flutter test --no-pub test/tools/progression_playtest_diagnostic_test.dart
shasum -a 256 test/tools/output/progression_attribute_playtest_2026-07-13.csv
stat -f '%m %Sm' test/tools/output/progression_attribute_playtest_2026-07-13.csv
git diff --exit-code -- \
  test/tools/output/progression_attribute_playtest_2026-07-13.csv
```

显式更新 evidence（人工操作）：

```bash
UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1 \
  flutter test --no-pub \
  test/tools/progression_playtest_diagnostic_test.dart
shasum -a 256 test/tools/output/progression_attribute_playtest_2026-07-13.csv
git diff --exit-code -- \
  test/tools/output/progression_attribute_playtest_2026-07-13.csv
```

其他专项：

```bash
flutter test --no-pub \
  test/tools/inner_demon_vulnerability_diagnostic_test.dart \
  test/tools/inner_demon_survive_diagnostic_test.dart \
  test/tools/tower_boss_feel_diagnostic_test.dart \
  test/features/cultivation/application/progression_full_path_contract_test.dart \
  test/features/cultivation/application/experience_source_consistency_test.dart \
  test/tools/attribute_role_sensitivity_diagnostic_test.dart

flutter test --no-pub \
  test/features/battle/application/combat_progression_settlement_service_test.dart
```
