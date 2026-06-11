# 波A · P1 机制深度全收口 · 设计 spec（2026-06-11）

> 上游：`playability_phase2_backlog.md` §二/§五/§六 + `P0_手动Boss战破招_落地方案_2026-06-09.md` §9.1。
> 拍板已收：interrupt_power_pct 走 **b 方向**（机制向：加深减防）。模式 xhigh。
> 原则：长线打磨（CLAUDE v1.19 §7）——一次做全面，backlog 只留依赖/待拍板。

## 0 · 现状锚（Phase 0 实测）

- 破招技全游戏仅 `skill_po_shi`（破势，canInterrupt=true，无心法归属），硬编码注入
  `battle_state.dart:302-311`（teamSide==0 末位 append）= P0「广发」简化。
- `interrupt_power_pct`：schema 已解析（`skill_def.dart:106,130`），yaml 0 配置，0 消费。
- per-skill proficiency effects 仅破势（cooldown_delta/interrupt_window_bonus_ticks）+
  青锋绝（damage_pct 三阶）。effects 词汇表 4 key。
- skills.yaml **168** 招（55 ultimate / 57 powerSkill）、encounter_skills.yaml **40** 招。
- 来源双池并存：旧 `EncounterProgress.unlockedSkillIds`（写点 encounter_service.dart:298-300）
  + 新 `SaveData.skillUnlockProgress`（SkillUnlockService，**isUnlocked 无人消费**）。
- 装配 6 槽 + 5 槽全空 fallback 主修全招（`battle_state.dart:275-290`，旧档保护不可破）。
- SkillDef 无 style 字段；Character 有 school（正午阳刚已用）。saveVersion 0.17.0。

## 1 · A1 破招 build gate（§9.1）

**设计**：破招技从「广发」改为**按流派装配**。

1. SkillDef 加可空 `style` 字段（enum 沿 Style{rigid,agile,sinister} 对应刚猛/灵巧/阴柔）。
   红线：canInterrupt=true 的招**必须**有 style（loader 校验）。
2. 新增 2 招破招技（yaml+文案我产）：灵巧系、阴柔系各 1，与破势（补 style: gangMeng）
   同构（canInterrupt + aiUsePolicy: saveForInterrupt + powerSkill），数值差异化见 §2。
3. Character 加第 7 装配槽 `keySkillId`（破招槽）+ saveVersion 0.17→0.18。
   - 装配 gate：只能装 `canInterrupt && skill.style == character.school` 的招。
   - autoFill：keySkillId 空 → 自动填本流派破招技（保 P0 手感不倒退）。
   - 藏经阁：6 槽区 +1 破招槽（沿既有 slot tile 体例），picker 灰显非本流派。
4. 拆 `battle_state.dart:302-311` 硬编码注入 → fromCharacter 读 keySkillId 槽；
   5 槽全空 fallback 路径**同步自动带本流派破招技**（旧档行为等价，不破 e2e）。
5. 敌方不变（敌人无装配概念，蓄力技走既有 chargeSkillId）。

**为什么独立第 7 槽而非挤主修槽**：破招是 P0 已上线的核心交互，挤主修槽会让旧档迁移
把输出招顶掉（手感倒退）；战斗 UI 关键技按钮本就是独立位，槽位与按钮一一对应。
**gate 的 build 相关性**：换流派 → 破招技跟换（效果/手感不同，见 §2）；为后续
装备/奇遇来源的高阶破招技留扩展位（picker 池按 style 过滤天然支持）。

## 2 · A2 interrupt_power_pct 实装（b：加深减防）

1. 语义：破招成功时，目标踉跄期减防 = `stagger_defense_down × (1 + interrupt_power_pct)`，
   按放招者该技当阶 proficiency 取值。
2. 实装：BattleCharacter 加 `staggerDefenseDownActive: double`（打断结算时写入
   `default_ground_strategy.dart:360-383`；减防消费点 `:470-475` 改读该字段；
   踉跄结束归零）。非破招路径不受影响。
3. 数值（进 skills.yaml proficiency.effects，红线 cap 见 4）：
   - 破势（刚猛）：jingTong 0.15 / huaJing 0.30 —— 减防深度型
   - 灵巧破招技：interrupt_window_bonus_ticks 为主（窗口型），power_pct 低配 0.10
   - 阴柔破招技：power_pct 0.20 + cooldown_delta —— 均衡型
4. 红线：`stagger_defense_down × (1+pct) ≤ 0.5`（loader 校验 + 红线测，写约束语义
   非瞬时事实）；numbers.yaml 加 `interrupt_power_cap: 0.5`。

## 3 · A3 per-skill 熟练度效果铺广

**范围**：55 ultimate 全配 + 3 破招技（§2）+ 真解/招牌维持手工值 = ~58 招。
normalAttack/powerSkill 留全局阶段倍率（设计立场：个性化集中在 signature 招，
非偷懒砍量——4 key 词汇表对普攻无意义差异可做）。

**体例**：流派模板 + 真解手工。
- 刚猛 ult：damage_pct 阶梯（shuLian .05/jingTong .10/huaJing .15，沿青锋绝锚）
- 灵巧 ult：cooldown_delta（jingTong -1/huaJing -2，下限既有 clamp 保护）
- 阴柔 ult：damage_pct 减半阶梯 + huaJing cooldown_delta -1（混合）
- 真解 3 招 + 青锋绝：手工精修（高于模板半档）
**平衡验证**：balance_simulator proficiencyUses 维度焦点扫（沿 `ce2ebdba` 体例）
floor/ceiling 各流派抽 1 关 + 3 真解关，130% cap 红线维持（cap 在 combinedMult 已有）。

## 4 · A4 来源模型统一

1. **迁移**：saveVersion 0.18 启动迁移（IsarSetup）：`EncounterProgress.unlockedSkillIds`
   全量 → `skillUnlockProgress` entries（unlocked=true，幂等）。旧字段保留只读 deprecated
   （头注 unused 体例，memory `feedback_yaml_config_unused_field`）。
2. **写路径单一化**：encounter_service.dart:298-300 改调 `SkillUnlockService.grantManual`；
   equipEncounterSkill 的解锁校验改读 `isUnlocked`（新池单一真相源）。
3. **消费收口**：藏经阁奇遇槽 picker 候选池（cangjingge_screen.dart:423-432 encounter
   分支现返回 []）改为 `encounter_skills 中 isUnlocked` 列表；残页收集区已读新池不动。
4. **source tag**：SkillDef 加 `source` 必填字段（enum：`technique` 心法招 /
   `encounter` 奇遇 / `mainline_drop` 真解 / `tower_fragment` 残页 / `special` 破招等），
   skills.yaml 168 + encounter_skills.yaml 40 全量回填（脚本批产+抽查），loader 红线：
   无 source 或非法值 fail-fast；encounter_skills 全=encounter；canInterrupt 招=special。

## 5 · A5 对账 + 闸门

- backlog §一/§三 勾销 P1b 已完成项（藏经阁/装配 UI/解锁态消费=本批 §4.3 真收口）。
- 全仓 analyze 0 / 全量测全绿 / balance 焦点扫过 / 红线测族新增：style gate、
  interrupt cap、source 枚举、迁移幂等。
- saveVersion 迁移用真旧档 fixture 测（0.17 档读入 → 装配/解锁/破招全可用）。

## 6 · 拍板点（实装前需用户确认）

1. **破招第 7 槽**（§1.3，推荐）vs 破招技挤主修 2 槽之一——影响藏经阁 UI 与旧档手感。
2. **A3 流派模板 + 真解手工**（§3，推荐）vs 55 ultimate 全手工个性化（工期 ×3，
   4 key 词汇表下差异化空间有限，不推荐但如实列出）。
3. 新破招技命名/文案默认我产（古风克制沿 content_guide），无需逐条过目——异议请提。

## 7 · 实装序（TDD，每步全测）

T1 schema（style/source/keySkillId/saveVersion+迁移）→ T2 loader 红线 → T3 新 2 破招技
yaml+文案 → T4 fromCharacter 拆硬编码+fallback 等价 → T5 autoFill+藏经阁第 7 槽 UI →
T6 interrupt_power_pct 结算+红线 → T7 A3 58 招 effects 批产+焦点扫 → T8 来源迁移+写路径
单一化+picker 收口 → T9 对账+全量闸门。预计 1-1.5 天。
