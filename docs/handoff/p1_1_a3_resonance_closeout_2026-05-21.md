# P1.1 A3 共鸣度满级体验 closeout(2026-05-21 四段)

> **会话总览**:2026-05-21 主对话候选 1+2 收口后续 · Mac opus xhigh ~3h · 1.0 路线图 P1.1 系统纵深第 3 项 A3 共鸣度满级体验完整闭环(4 子任务 3a/3b/3d/3c)
>
> **HEAD**:`225ee8e` → 待 push origin/main(5 commit:audit `e7176c9` + 3a `3cb9918` + 3b `15ff8aa` + 3d `9e54cf9` + 3c `225ee8e`)
> **测试基线**:1147 → **1170 pass**(净 +23)+ 1 skip + 0 fail / analyze 0 issues
> **saveVersion**:0.12.0(不动,无 SaveData schema 变化)
> **实测时长**:实装 ~3h(audit 已留 §3 估 5.5-9h xhigh,实测 ~1.7× 提速,memory `feedback_opus_xhigh_interactive_duration` 锚点之一)

---

## §1 Phase 0 reality check(audit doc `p1_1_a3_resonance_phase0_audit_2026-05-21.md` 已落,本 closeout 仅 ref)

四维:
- A schema:numbers.yaml `resonance.stages` 4 stage + `reference_multipliers.joint_skill.base: 4500` + `SkillType.jointSkill` enum 已配,但 yaml 内 `unlocks_joint_skill` / `has_sword_song_effect` **2 字段未被 Dart 读取**(本批补 ResonanceStageConfig 字段)
- B caller:joint_skill / jointSkill / sword_song 全仓 **0 战斗内 caller**(本批 0→1 新增)
- C 邻近目录:battle/equipment feature 内扩,**不新建 resonance/ 目录**
- D UI:equipment_detail_screen 已有 chip,但 victory dialog / battle 内 / 拆分提示 全 0 → 3 处新建

判定:**半完成 + 0→1 大块新增**(50% schema + 50% caller/UI)。

---

## §2 设计决议(grill §2.1-§2.5 五点)

| 题号 | 选项 | 决议 | 实装位置 |
|---|---|---|---|
| §2.1 释放方式 | a/b/c | **a** 第 4 招挂 BattleCharacter | `battle_state.dart:fromCharacter` |
| §2.2 trigger stage | yes/no | **yes** battle setup 一次性算 | `battle_state.dart:fromCharacter`(stage 战斗内 fixed) |
| §2.3 拆分提示 UI | a/b/c | **c**(语义校正后)→「共鸣度晋升信息透明」 | `equipment_detail_screen.dart:_ResonanceDetailsSection` |
| §2.4 sword_song | a/b/c | **a** 纯文字浮字(VFX 留 Phase 5+) | `damage_popup.dart:_PopupContent` |
| §2.5 banner 位置 | a/b/c | **a** victory dialog 加 sub-row | `stage_victory_dialog.dart:ResonanceUpgradeBanner` |

**§2.3 语义校正**:用户拍板「选项 c 拆分加成来源」后,Phase 0 grep 发现共鸣加成本质只来自这件装备 battleCount 一条路径,无其他叠加来源(师承遗物 +5% 内力是独立 buff 不混)。校正为「共鸣度晋升信息透明」(当前 bonus + 已解锁 joint_skill/sword_song 状态 + 距下一阶 N 战),与 3-b/3-c 形成回路。用户在 grill 确认环节追认校正。

---

## §3 实装详情(4 子任务串行,各独立 commit)

### 3-a banner 共鸣度晋阶提示(commit `3cb9918`,~30min)

**改 4 文件**(无新文件):
1. `lib/features/mainline/presentation/stage_victory_dialog.dart`:新增 `ResonanceUpgradeNotice` class + `ResonanceUpgradeBanner` widget + `showStageVictoryDialog` / `StageVictoryContent` 加可选 `resonanceUpgrades` 参数
2. `lib/features/mainline/presentation/stage_entry_flow.dart`:`_applyVictoryResolution` 返回 record 加 `resonanceUpgrades` 字段;原 `recordResonanceUpgraded` for 循环同步 cache notice
3. `lib/features/tower/presentation/tower_entry_flow.dart`:`_applyTowerVictoryResolution` 返回类型 `List<AdvancementEntry>` → record(advancements + resonanceUpgrades);`_showVictoryDialog` + `_FirstClearContent` 同步加参数 + banner
4. `lib/shared/strings.dart`:`stageVictoryResonanceLabel` + `stageVictoryResonanceUpgrade(name, stage)`

**test +4**:`stage_victory_dialog_test.dart` 1 notice / 多 notice 三段共存 / empty(默认 default empty)。

### 3-b joint_skill battle 释放路径(commit `15ff8aa`,~1.2h)

**改 4 文件 + 0 新**:
1. `data/skills.yaml`:新增 `skill_joint_skill`(type=jointSkill / mult=4500 / cost=250 / cd=4 / 不绑心法);**注**:numbers.yaml `reference_multipliers.joint_skill.base: 4500` 0 Dart caller(文档参考值),`data/skills.yaml.powerMultiplier` 是 single source of truth
2. `lib/data/numbers_config.dart`:`ResonanceStageConfig` 加 `unlocksJointSkill` + `hasSwordSongEffect` 字段(yaml 2 字段之前未读取)+ `_parseResonanceStages` 解析
3. `lib/features/battle/domain/battle_state.dart`:`fromCharacter` 加注入逻辑(`equipped.any(weapon && cfg.unlocksJointSkill)` → `skills.add(skill_joint_skill)`);test fixture 缺 `skill_joint_skill` 时 silent skip(containsKey 守护)
4. `lib/features/battle/domain/battle_ai.dart`:`_pickSkill` step 1.5 加 jointSkill 分支(first found + _canUse;优先级 pending > jointSkill > powerSkill > normalAttack)

**test +9**(+1 fix):
- `test/combat/battle_state_test.dart`:+5 case(候选 3-b group:shengShu 不含 / moQi 含 / xinJianTongLing 含 / 无武器不含 / 去重)
- `test/combat/battle_engine_test.dart`:+4 case(BattleAI 优先级 joint_skill 自动放 / 内力不够 fall through / cd>0 fall through / pendingUlt > jointSkill);_mkBC 加 `weaponBattleCount` 参数
- `test/data/game_repository_test.dart`:skillDefs.length 103 → 104(skills.yaml +1)

### 3-d equipment_detail 共鸣度晋升信息透明 section(commit `9e54cf9`,~25min)

**改 2 文件**:
1. `lib/features/inventory/presentation/equipment_detail_screen.dart`:`_InfoCard` 加 `_ResonanceDetailsSection`(bonus +X% / ✦ 已解锁人剑合一 / ✦ 暴击附带剑鸣 / 距下一阶 N 战)+ 私有 helper `_findStageCfg` / `_findNextStageCfg`(用 ResonanceStage.values 序号定位下一阶)
2. `lib/shared/strings.dart`:+4 串(equipmentDetailResonanceBonus/JointSkill/SwordSong/NextHint)

**test +3**:`equipment_detail_screen_test.dart` 候选 3-d group:shengShu(battleCount=0)→ 无加成 + 100 hint;moQi(500)→ +20% + 解锁人剑合一 + 1500 hint;xinJianTongLing(2000)→ +30% + 两招全 + 无 next hint。

**额外**:battle_state_test 3-b group local helper 改名(`_player`→`mkPlayer` 等)消 `no_leading_underscores_for_local_identifiers` info。

### 3-c sword_song 暴击剑鸣浮字(commit `225ee8e`,~40min)

**改 5 文件 + 1 新**:
1. `lib/features/battle/domain/battle_state.dart`:`BattleCharacter` 加 `swordSongResonanceActive` 字段;`fromCharacter` 同 3-b 同段查 weapon resonanceStage cfg.hasSwordSongEffect;`copyWith` 加同字段
2. `lib/features/battle/presentation/damage_popup.dart`:`DamagePopupData` 加 `hasSwordSong` 字段;`_PopupContent` 在 counter 后追加「✦剑鸣」小红字(0.65× fontSize,WuxiaColors.popupCritical,w700)
3. `lib/features/battle/presentation/battle_screen.dart`:`_spawnPopup` 加 attacker 参数;`_buildPopupData` 根据 `result.isCritical && attacker.swordSongResonanceActive` 设 hasSwordSong=true
4. `lib/shared/strings.dart`:+`swordSongHint = '✦剑鸣'`
5. **新 1 文件**:`test/features/battle/presentation/damage_popup_test.dart`(5 case)

**test +8**:
- `test/combat/battle_state_test.dart`:+3 case(候选 3-c group:xinJianTongLing → true / moQi → false / 无武器 → false)
- `test/features/battle/presentation/damage_popup_test.dart`:5 case(普通 → 不显 / critical+swordSong=true → 显 / critical+swordSong=false → 不显 / counter+swordSong 共存 / 闪避 → 不显)

---

## §4 测试覆盖矩阵(本批 +23 case)

| 子任务 | commit | 新 case | 新 test 文件 |
|---|---|---|---|
| 3-a | `3cb9918` | +4 | 0(扩 stage_victory_dialog_test) |
| 3-b | `15ff8aa` | +9(含 +1 fix skill count) | 0(扩 battle_state_test + battle_engine_test + game_repository_test) |
| 3-d | `9e54cf9` | +3 | 0(扩 equipment_detail_screen_test) |
| 3-c | `225ee8e` | +8 | 1 新(damage_popup_test) |
| 累计 | 4 commit | **+23** | 1 新 |

1147 pass → **1170 pass**(+23)+ 1 skip / analyze 0 issues。

---

## §5 红线点检

| 红线 | 检验 | 状态 |
|---|---|---|
| GDD §5.4 普通伤害 ≤ 8,000 | joint_skill 不是普通伤害 | n/a |
| GDD §5.4 大招暴击 < 100,000 | joint_skill 4500 × crit_max 2.5 × cult_max 3.0 × school_max 1.25 × def_min 0.65 = **27,421** | ✅ |
| GDD §5.4 玩家血量 ≤ 20,000 | 本批未碰 maxHp | n/a |
| GDD §5.4 内力 ≤ 15,000 | 本批未碰 maxIf | n/a |
| GDD §5.4 装备攻击 ≤ 2,000 | 本批未碰装备数值 | n/a |
| GDD §5.3 三系锁死 | joint_skill 不绑流派(共鸣度系统统管,GDD §6.4 直译) | ✅ 显式不绑 |
| §6.4 共鸣度阶段不可破 | numbers.yaml stages 不动数值,只补 2 字段读取 | ✅ |
| §6.4 reference_multipliers.joint_skill.base 锁 4500 | skills.yaml powerMultiplier=4500 一致 | ✅ |
| §6.4 战斗中 battleCount 不增,stage 固定 | fromCharacter 内一次性算,battle 内不重算 | ✅ |
| 不硬编码数值 | unlocksJointSkill / hasSwordSongEffect 走 numbers.yaml,不靠 enum index | ✅ |
| 不硬编码文案 | 全走 UiStrings | ✅ |

---

## §6 1.0 路线图进度

P1.1 系统纵深 ⭐4 项:
- ✅ 候选 1 A1 E.1 收徒弹窗(commit `86618f1`)
- ✅ 候选 2 A1 E.5 祖师爷 buff(commit `a0eae82`)
- ✅ 候选 3 A3 共鸣度满级体验(commit 3a/3b/3d/3c)← 本批
- ⏳ 候选 4 A4 开锋 build 内容扩(35 件装备开锋方案 audit 待跑)

P1.1 加权 3/4 项 ✅(75%)。

---

## §7 下一步候选(下次会话主菜单)

| # | 任务 | 模型 | 估时 | 备注 |
|---|---|---|---|---|
| **4** ⭐ | 候选 4 A4 开锋 build 内容扩 | sonnet 或 opus | 2-3h | Phase 0 audit 35 件装备开锋方案,可能需要 grill 设计 |
| 5 | P1.1 全收口 closeout + 更新 CLAUDE.md §12.2 | opus | 0.5h | §12.2 #11 founder_ancestor_buff Demo 不实装 → 已激活,需更新表述 |
| 6 | Demo §8.4 14/14 stage_audit 复跑 | opus | 25min | P1.1 全完成后审 1.0 路线图位置 |

**推荐**:候选 4 起手。如 audit 发现 35 件方案已落不动,可直接跳候选 5。

---

## §8 总时长 vs audit 估算

| 子任务 | audit 估 | 实测 |
|---|---|---|
| 3-a banner | 0.5-1h sonnet | 30min xhigh |
| 3-b joint_skill | 1.5-2h xhigh | 1.2h xhigh |
| 3-d 拆分提示(信息透明) | 1-2h opus | 25min xhigh |
| 3-c sword_song | 1.5-3h xhigh(纯文字降级版 0.5-1h) | 40min xhigh |
| **合计** | 5.5-9h spec / 3-5h 实际 | **~3h xhigh** |

实测 vs audit 估算 ~1.7× 提速,锚点入 memory `feedback_opus_xhigh_interactive_duration`(同 context xhigh 实测 1.7-5×)。

---

**closeout 文档结束**。
