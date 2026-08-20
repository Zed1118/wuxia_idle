# Phase 0A Ch1 真实技能 headless 画像计划

> 日期：2026-08-20
> 分支：`codex/phase0a-ch1-skill-profile-0820`
> 状态：READY（观察基线完成，数值/体验拍板后置）
> 上位：路线 C / 内容迁移 ADR D5「继承曲线 + bot 胜率画像」

## 目标

为鼠标普攻 + 数字 1–6 真实技能版 Phase 0A 建立可重复的 Ch1 五关多 seed 观察基线。输出胜负、耗时、末态 HP/Qi、basic/Q/R/六槽技能使用与伤害占比，区分硬工程红线、headless bot 观察和必须真人判断的体验项。本批不修改 YAML、伤害公式或平衡数值。

## 真实玩家 profile

- 只走 production `OnboardingService.createFoundingMaster(soloStart:true)` → production autoFill → `PlayerCombatantSnapshotAssembler`。
- 三个创建页流派：gang_meng / ling_qiao / yin_rou。
- 控制变量：origin=`mountain_wanderer`、fate=`balanced_seed`、固定装备 roll RNG。
- 禁止用 `Phase2SeedService.seedP3`（名家功/10000 内力/爆量资源）或 `_makeCh1Player` 灰盒快照冒充。
- 当前生产事实：Ch1 初窥解锁池只让主修 basic 进入 main1，`ultimate` 槽为空；画像必须忠实记录，不手填技能。

## 样本与指标

- 3 profiles × 5 stages × 100 seeds = 1500 局；seed manifest 连续且入报告。
- 单局：outcome(victory/defeat/timeout)、ticks/seconds、HP/Qi 起末态与比例、总伤害/暴击/最大单击。
- 动作：basic cast/hit/damage；Q gather 与 R clear cast/damage；数字 1–6 cast/hit/damage 固定槽位不压缩。
- 聚合：win rate、mean/p50/p90 ticks/seconds、mean 末态 HP/Qi%、各技能总 cast/damage。
- 百分位：nearest-rank，报告注明。

## 判据

### 硬红线（测试）

1. 样本/seed/profile/stage 完整，分类总和守恒。
2. canonical seed 重跑 observation 全字段相等。
3. timeout 独立分类，不冒充 defeat；ongoing 不进 settlement。
4. 最大单击伤害 < 1,000,000；现有配置/schema 红线继续全量托底。
5. 默认测试不改 evidence；仅显式 `UPDATE_PHASE0A_CH1_PROFILE_EVIDENCE=1` 重生 CSV/Markdown。

### 观察项（不做脆弱断言）

- 胜率、耗时、HP/Qi 分位、技能占比。
- 三流派差异与关卡坡度。
- bot ready-first 行为不冒充真人操作水平。

### 真人后置

- 走位/锁敌、技能节奏、信息可读、打击感、新手压力与趣味。

## 切片

1. [x] production founder profile helper + 真 Isar 三流派测试。
2. [x] event-driven 单局 observation + aggregate Module。
3. [x] 1500 局 diagnostic、CSV/Markdown evidence 与确定性 Gate。
4. [x] 解读报告，列出可调候选但不改数值。
5. [x] analyze/targeted/全量、文档收账、READY 合并。

## 当前恢复点

- 最后完成：production 三流派 profile、event observation/aggregate、1500 局 CSV/Markdown evidence 与审计解读；修复 Phase 0A numeric Adapter 将 normalAttack 重复映射数字 1 的问题；analyze 0、targeted 36/36、最终全量 **5251 pass / 0 fail**。默认 diagnostic 仅跑 30 局 smoke，显式 UPDATE 才跑 1500 局，降低持续成本。
- 下一步：文档收账并合并；真人三流派 Ch1 小样、起手技能可见性和灵巧 Boss 分叉拍板后置。
- 阻塞：无；数值与真人体验结论明确后置。
