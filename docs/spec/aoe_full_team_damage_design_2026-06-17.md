# aoe 群体技全体伤害实装 · 设计文档

**日期：** 2026-06-17
**分支：** feat/phase5-battle-experience(承主线一闭环)
**关联：** 主线一战斗 UI 表达 Codex 复验暴露 / GDD §八#4「群体技自动」前瞻落地
**状态：** 设计已拍板,待 writing-plans

---

## 1. 问题陈述

技能系统有 `TargetType { single, aoe }`(`lib/core/domain/enums.dart:135`),production `data/skills.yaml` 有真 aoe 大招(line 233 / 410),主线一 1.3 已让 aoe 可拖招下发。但**战斗结算层从未消费 `TargetType.aoe` 做全体伤害**——`battle_ai.dart:38` 自承「群体技自动为前瞻」,`BattleAI.decide()` 永远返回单一 targetId,`_resolveAction()` 只对单目标结算。结果:玩家拖下发 aoe 群体技,实测只命中单个敌人(Codex 复验 C 项 aoe 不通过)。

这不是 1.3 回归,是 GDD §八#4 既有前瞻占位缺口,被 1.3 暴露。GDD 对群体技全体伤害规则完全空白。

## 2. 设计决策(已拍板)

**伤害规则 = 各自完整伤害·无衰减**:aoe 命中全体时,每个存活敌人各按完整伤害公式独立结算,各目标伤害 = 该技能单体伤害值,无衰减系数、无均摊。

**理由**:符合武侠大招群扫意象 + 爽感主旋律(GDD §5.7 爽感走表现层);技术最简(逐目标独立调 DamageCalculator,无新 yaml 系数);反主流不靠数值抠扣(衰减系数是网游惯例)。aoe 已有耗内 250 + CD 5 + 大招级成本制衡。

**关键副作用 — 红线安全**:A 方案下**单次伤害值不变**(各目标 = 单体值),只是命中数增加。GDD §5.4「不进百万」软红线本质不受冲击(终局极值单目标峰值 13.5-21 万不抬高,只是同 tick 命中多个)。

## 3. 技术设计

### 3.1 目标解析(统一路径)

`BattleAI.decide()` 返回从 `(SkillDef, int targetId)` 改为 `(SkillDef, List<int> targetIds)`:
- single 技:返回 `[单一目标]`(破招锁定 / 手动指定 / HP 最低,逻辑不变)
- aoe 技:返回全体存活敌人 charId,**按 slotIndex 升序**

`_resolveAction()` 统一 loop `targetIds`,消除单体/全体分支(single 即 1 元素 loop,行为与现状等价)。

> callers 确认:plan 阶段 grep `BattleAI.decide` 全部调用点(预计仅 `_resolveAction`),改返回类型后逐个适配。

### 3.2 结算 loop

`_resolveAction()` 对 `targetIds` 逐个:
- 调 `_calculateInBattle` / `DamageCalculator.calculateResolved`(单一真相源,逐目标独立)
- **顺序锚 slotIndex 升序**(rng 闪避/暴击消费顺序确定,防 seed 复现漂移 —— 文档显式锚定)
- 每目标独立 roll 闪避/暴击、独立判流派克制/防御率/震伤/内伤(调研确认 DamageCalculator + 内伤 slot 逐目标自然支持,无单体绑定)
- 每目标扣血后查胜负,敌队全灭则提前结束本 tick(与现 single 死亡中断逻辑一致)

### 3.3 AI 对称

任一方(玩家 / 敌人)选 aoe 技都展开对面全体——production 已有 aoe 技,自动战斗 AI 与手动拖发走同一 loop,消除「自动 vs 手动」结果不一致。balance_simulator 自然覆盖(runToEnd 跑全场景)。

## 4. 红线与测试

- **行为测**:aoe 技结算后,敌队全体存活者各扣血一次(扣血目标计数 = 命中前存活敌人数)。
- **确定性测**:同 seed 跑含 aoe 的战斗,结果可复现(slotIndex 升序锚保证)。
- **红线测**:A 方案单次伤害 = 单体值,`test/balance/full_build_damage_redline_test.dart` 单体断言本质不变;补一条断言「aoe 各目标伤害 = 同条件单体伤害,不额外抬高」,守「不进百万」。
- **顺带(F debuff 验收路由修复)**:`scenarioDragLive`(battle_test_menu.dart)我方现全 gangMeng,内伤(阴柔→灵巧)触发不了 → 给场景加一个阴柔我方角色或调流派搭配,让 Codex 能复验内伤 debuff hover。

## 5. GDD 改动

GDD §八#4「群体技自动」从「前瞻」改「已实装」,补群体技全体伤害规则一节(各目标完整伤害·无衰减·全体存活敌人·slotIndex 升序结算)。属本设计批准范围内的 GDD 改动。

## 6. 范围边界 / 非目标

- **纯战斗结算机制**,A 无衰减系数 → 不新增 numbers.yaml 数值。
- **不改伤害公式本身**(DamageCalculator 单目标计算不动,只在结算层加目标循环)。
- **不做**:aoe 人数衰减 / 范围限定(前排/随机 N)/ aoe 专属视觉特效(表现层另议)。
- 全量 analyze + test 零回归;升 xhigh 实装(战斗结算核心逻辑)。
