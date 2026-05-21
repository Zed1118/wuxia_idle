# P1.1 A3 共鸣度满级体验 Phase 0 audit(2026-05-21)

> 候选 1+2 收口会话末段产出 · audit 类不动代码 · **本 audit 暂停,下次新会话续推**
> Mac opus xhigh Phase 0 四维 grep ~10min · 留新会话开局参考

---

## §1 Phase 0 四维 grep 结果

### 维度 A — schema/字段层(已落)
- `numbers.yaml combat.skills.reference_multipliers.joint_skill.base = 4500` + `note: "共鸣度 +20% 后解锁,不分心法阶"`
- `numbers.yaml equipment.resonance.stages` 4 stage 配齐:
  - shengShu(生疏)`bonus_multiplier: 1.0` + `unlocks_joint_skill: false` + `has_sword_song_effect: false`
  - chenShou(趁手)`1.10` + `false` + `false`
  - moQi(默契)`1.20` + `true` + `false` ← **joint_skill 解锁锚**
  - xinJianTongLing(心剑通灵)`1.30` + `true` + `true` ← **sword_song 暴击特效锚**
- `enum SkillType.jointSkill` 已存在(`lib/core/domain/enums.dart:120`)
- `EnumL10n SkillType.jointSkill => '人剑合一'`(`enum_localizations.dart:57`)

### 维度 B — caller / 生产路径(0)
- `joint_skill` / `jointSkill` / `unlocksJointSkill` 全仓 **0 战斗内 caller**
- `reference_multipliers.joint_skill` 数值 **0 消费**
- `swordSong` / `sword_song` / `has_sword_song_effect` 全仓 **0 caller**
- 共鸣度晋阶 trigger:`game_event_service.dart:198 recordResonanceUpgraded`(event 写入) + tower / mainline entry flow 已 caller(战胜后 event banner notify)

### 维度 C — 邻近目录
- `lib/features/battle/` 已建战斗体例完整 + `damage_calculator`(test-only) + `BattleEngine` + `default_ground_strategy._calculateInBattle`
- `lib/features/equipment/` 已建共鸣度相关:`ResonanceStageConfig` / `Equipment.resonanceBonus` / `Equipment.battleCount`
- 无独立 `lib/features/resonance/` 目录

### 维度 D — UI widget
- ✅ `equipment_detail_screen.dart` 已显共鸣度阶 chip(stage 名 + bonus 倍率)
- ❌ 战斗内 joint_skill 释放表现层 widget **不存在**
- ❌ 共鸣度晋阶 banner widget **不存在**(只有 game_event 写入)
- ❌ sword_song 暴击剑鸣特效 widget **不存在**
- ❌ 拆分提示 UI **未明定义**(closeout §6.1 描述模糊,设计需 grill)

### §1.5 维度结论矩阵

| 维度 | 状态 | 工作量含义 |
|---|---|---|
| A schema | 80% 已落 | 数值 + enum + event 体例完整;仅缺 `JointSkillDef` def 实例 |
| B caller | 0 | battle_engine joint_skill 释放路径完全 0→1 新增 |
| C 邻近目录 | feature 内部扩 | 不需要新 feature 目录 |
| D UI | 0(3 处新建) | banner + sword_song + 拆分提示 全 0→1 |

**判定**:**半完成 + 0→1 大块新增**(50% schema 已落 + 50% caller+UI 0)。

---

## §2 设计冲突点(下次会话起 spec 前必须 grill)

### §2.1 joint_skill 在 battle 内如何释放?
- **选项 a**:作为第 4 招挂在 `BattleCharacter.availableSkills`(同 encounter skill 体例)
- **选项 b**:作为「特殊触发」每 N 次主修招式后自动释放 1 次
- **选项 c**:作为「装备触发」每件武器单独算共鸣阶 → 武器命中时按 joint_skill 释放(GDD §6.4「人剑合一」语义)
- 推荐 **选项 c**(GDD 直译,但 trigger 复杂)— 留 grill

### §2.2 joint_skill 触发 stage 门槛?
- yaml `unlocks_joint_skill: true` 出现在 moQi(默契) + xinJianTongLing(心剑通灵)2 stage
- battle 内武器 stage **战斗中变化吗**?(`battleCount` 战后才加,所以 battle 内 stage 是 fixed)
- 但 `reference_multipliers.joint_skill.base: 4500` 是固定值,不分 stage

### §2.3 拆分提示 UI 究竟是什么?
- closeout §6.1 写「joint_skill 释放表现层 + banner 时机 + **拆分提示 UI**」
- 「拆分」语义不明:
  - 选项 a:玩家"拆"装备到不同角色时提示共鸣度损失
  - 选项 b:joint_skill 表现层把 4500 倍率"拆"分为 (装备攻击 × X + 内力 × Y)
  - 选项 c:UI 显示 "+1.20" 共鸣阶来源拆分(装备 共鸣 vs 心法 vs 师承)
- 需 grill 用户决定

### §2.4 sword_song 暴击剑鸣特效
- yaml `has_sword_song_effect: true` 仅 xinJianTongLing 阶
- 「暴击附带剑鸣特效」 — 是音效?VFX?widget animation?
- VFX 风险:Flutter 内做剑鸣特效需 AnimationController + CustomPainter,VFX 风险

### §2.5 共鸣度晋阶 banner
- 现状 `recordResonanceUpgraded` 写 GameEvent ✅
- 缺 UI:玩家在 battle 结束 victory dialog 内看到「装备 X 共鸣度晋至 Y 阶」(`showStageVictoryDialog` 体例扩)

---

## §3 工作量重估

closeout §6.1 估 sonnet 2-4h。实际:

| sub-task | 估时 | 模型 | 风险 |
|---|---|---|---|
| §2.1 joint_skill battle 释放路径 | 1.5-2h | opus xhigh | battle_engine 改动 |
| §2.2 trigger stage 门槛公式接入 | 0.5h | opus | 设计明确 |
| §2.3 拆分提示 UI | 1-2h | sonnet 或 opus | 设计 grill 待定 |
| §2.4 sword_song 特效 | 1.5-3h | opus xhigh | VFX 风险 |
| §2.5 晋阶 banner | 0.5-1h | sonnet | 体例对齐 victory dialog |
| audit + spec doc + closeout | 0.5h | opus | 文档 |
| **合计** | **5.5-9h** | opus xhigh 主导 | |

**结论**:候选 3 实际工作量 5.5-9h opus xhigh,**不是 closeout §6.1 估的 2-4h**。

---

## §4 推荐路径(下次新会话开局参考)

### §4.1 起步方案
1. **必跑** §2.1-2.5 grill 5 设计点拍板(opus xhigh ~30 min,纯对话不动代码)
2. 拆 4 子任务串行(3a banner / 3b release / 3c sword_song / 3d 拆分提示),**每子任务独立 commit**
3. 每子任务前 mini-grep 再 check 状态(防设计点遗漏 caller)

### §4.2 可控范围(spec 风险评估)
- **3a banner**(0.5-1h sonnet):最快收口,体例对齐 `showStageVictoryDialog`,无 VFX 风险
- **3b release**(1.5-2h opus xhigh):battle_engine 改动,需 grill 设计点 §2.1+§2.2
- **3c sword_song**(1.5-3h opus xhigh):VFX 风险,可能 fail 推 Phase 5+
- **3d 拆分提示**(1-2h opus):需 grill §2.3 设计

### §4.3 若 sword_song VFX 风险高 → 缩减方案
- 3a + 3b + 3d(无 VFX 路径)→ 3.5-5.5h
- 3c sword_song 留挂账(Phase 5+ 美术阶段一并出图 + VFX)

---

## §5 当前 git 状态

- HEAD `a0eae82` 候选 2 commit 已 push origin/main
- 1147 pass / 1 skip / 0 fail / analyze 0 issues
- 本 audit doc 即将 commit(纯文档)
- 候选 3 实装暂停,下次新会话续推

---

**audit 文档结束。下次新会话开局读本 audit + 候选 1/2 closeout,起 grill §2.1-2.5,拍板后 spec + 实装。**
