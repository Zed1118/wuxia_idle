# Phase 0A Ch1 起手 powerSkill 画像复核

> 日期：2026-08-21
> 基线：`699f61a8` + D1-A 实现工作区
> 样本：production 三流派 × Ch1 五关 × 100 seeds = 1500 局
> 性质：工程与画像复核，不替代真人试玩

## 1. 实现边界

- `TechniqueDef.skillUnlockLayers` 提供逐招式、显式、可审计的修炼层覆盖；
  未配置心法继续沿第 1 招初窥、第 2 招小成、第 3 招起大成。
- 仅三本创建页入门心法把第 2 招 `powerSkill` 覆盖为初窥开放。
- 祖师仍是初窥，大招仍需大成；全局 ultimate threshold、伤害、敌人、
  真气、CD 和存档 schema 均未调整。
- 覆盖引用悬空技能或未知修炼层时 loader fail-fast。

## 2. 结果

- 三流派 production snapshot 均为：`basic` 保留鼠标普攻，`main1` 装入
  本流派真实 `powerSkill`，`main2` 保留旧 basic，ultimate 为空。
- Phase 0A 数字映射排除重复 basic 后，数字 1 只剩真实 powerSkill；数字
  2–6 为空。D1“第一章可见且可按真实主动技能”的工程目标成立。
- 1500 局全部完成，timeout 0，最大单击 2446，未触伤害软线。
- numeric 1–6 总出手 500 次，全部来自刚猛，且该 bot 样本命中伤害为 0；
  灵巧/阴柔没有 numeric 出手。Q 仍每场先释放一次、R 仍为 0。
- 最低 bot 胜率为灵巧 `stage_01_05` 4%。本轮基线已包含后续 Boss phase
  能力，不能把它与 08-20 的 53% 差值全部归因于 D1；禁止据此顺手调敌人。

## 3. 结论

`D1_ENGINEERING_PASS / HUMAN_AND_BEHAVIOR_PENDING`。

起手技能已真实进入数字栏，但 ready-first bot 与现有固定 Q/R 资源顺序没有
形成稳定技能循环。这不是继续微调开放层能解决的问题，下一批应按已拍
D2-A / D3-A / D4-A 建立真实技能 behavior schema；真人 Ch1 小样仍是产品
替换 Gate，不能由本报告代签。

原始证据沿既有稳定路径刷新：

- `test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.csv`
- `test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.md`

文件名保留 08-20 是为了不改诊断入口；文件正文已标注 08-21 refresh。
