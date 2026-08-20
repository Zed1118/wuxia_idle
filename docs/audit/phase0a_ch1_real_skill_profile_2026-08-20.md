# Phase 0A Ch1 真实技能 headless 画像审计

> 日期：2026-08-20
> 基线：`bf2ed846`（鼠标左键 + 数字 1–6 合入态）
> 样本：3 个 production 创建页流派 × Ch1 五关 × 100 seeds = 1500 局
> 性质：观察报告，不是平衡拍板；本批零 YAML/伤害公式/数值调整
> 原始证据：[`test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.csv`](../../test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.csv)
> 聚合表：[`test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.md`](../../test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.md)

## 1. 口径

- 玩家不是 debug seed：每个 profile 都走 `OnboardingService.createFoundingMaster(soloStart:true)`，统一 `mountain_wanderer + balanced_seed`，只改变 school（刚猛/灵巧/阴柔）。
- 入战前走 production autoFill 与 `PlayerCombatantSnapshotAssembler`；关卡走真实 `stage_01_01..05`、同一 0A mapper/reducer/DamageCalculator/headless bot。
- 每关独立使用同一新档起手 build，不模拟关间奖励、经验、自动换装；因此本报告观察“静态起手 build 对五关”的坡度，不冒充完整 Ch1 连续成长体验。
- headless bot 是 ready-first 确定性策略，不等于真人走位和技能判断。

## 2. 硬结果

- 1500 局全部分类完成：timeout **0**。
- 最大单次 resolved damage **2446**，远低于“不进百万”软线。
- canonical seed 全字段重跑一致；seed/profile/stage 组合完整。
- 排除 Phase 0A 数字栏中的 `normalAttack` 后，鼠标 basic 不再与数字 1 重复结算。

## 3. 关键观察

### 3.1 新档 1–6 实际全空

三个 production profile 的 snapshot 都是：主修 basic 同时落 `main1`，其余 main2/assist/resonance/ultimate/encounter 为空。Phase 0A 按正式控制约定排除 numeric `normalAttack` 后，数字 1–6 cast 总数为 **0**。

原因不是 UI：Ch1 初窥解锁池当前只给 basic；且起手 ultimate 的倍率 1500 低于全局 ultimate threshold 5000，不能进入 ultimate 槽。若希望新玩家在 Ch1 体验数字技能，需要另拍“起手技能解锁/autoFill/threshold”方案，不能由表现层伪装已有技能。

### 3.2 Q/R 当前循环没有成立

每个 profile 共 500 场，Q gather 恰释放 500 次、伤害为 0；R clear 释放 **0** 次。起手真气在 Q 后不足以进入 R，末态 Qi 均值仅约 12.5%–30%。

这进一步支持既有后置项：Q pull/R stagger 需要显式 `Phase0aSkillBehavior`/geometry 与真实技能资源设计，不能长期作为两枚独立固定战术印维持。

### 3.3 流派差异过大

- 刚猛：五关全为 100% bot 胜率。
- 阴柔：`stage_01_03` 为 98%，其余 100%。
- 灵巧：前四关 100%，`stage_01_05` 仅 **53%**，平均末态 HP 比例 17.3%。

Boss 关出现“灵巧接近掷硬币、另外两系全胜”的明显分叉。现阶段不能直接据 bot 把 Boss 统一削弱；优先真人复核灵巧 starter gear/闪避节奏/贴身时间，再判断是流派起手 build、bot 策略还是 Boss 单体曲线问题。

### 3.4 战斗节奏很短且非单调

各 profile/stage 的 p50 约 **13–43 ticks**，即 **1.3–4.3 秒**。刚猛 Boss 的 p50 19 ticks，反而短于 stage_01_04 的 25 ticks；灵巧 Boss 43 ticks，形成另一极端。

bot 会每拍请求普攻与 ready 技能，不能单凭该秒数断言真人必然过短；但它足以证明当前 Ch1 坡度不是稳定递增，需要进入真人试玩观察。

## 4. 建议顺序（均未执行）

1. **先做真人 Ch1 三流派小样**：至少各跑一次 stage_01_01/03/05，记录体感耗时、受击、是否理解空技能槽与 Q/R。
2. **拍板起手技能可见性**：A 提前解锁一门 powerSkill（推荐评估）/ B 保持空槽并明确成长预告 / C 调整 ultimate threshold（影响全局，风险最高）。
3. **单独设计 Q/R behavior schema**：真实技能携带 pull/stagger/geometry 后再删除迁移 Adapter。
4. **最后才调 Ch1 数值**：优先局部处理灵巧 Boss 分叉，禁止为 53% 单点全局削弱所有敌人。

## 5. 不能从本报告推出的结论

- 不能判定真人难度、走位手感、技能爽感和信息可读性。
- 不能判定连续五关成长曲线（本批未发奖励/经验/换装）。
- 不能把 100% bot 胜率直接解释为“玩家一定觉得简单”。
- 不能据此修改 GDD/CLAUDE 或宣布六人/Windows Gate 通过。
