# 可玩性 P1a · 养成内核 实施 spec

> 日期:2026-06-09
> 目的:给后续 Claude 拆 plan / code review 用的可执行规划。实装前以代码现状为准(spec §八)。
> 上游:`docs/spec/playability_upgrade_master_spec_2026-06-09.md`(P1 段 + §2.4/2.5/三/11/16)
> 二期 backlog:`docs/spec/playability_phase2_backlog.md`(P1a 砍掉/默认拍板项汇总)
> 范围拆分:P1 = P1a 养成内核(本 spec) + P1b 表现层(藏经阁/进度展示/装配 UI,留后)

## TL;DR

P1a = **技能解锁来源统一(+Boss 真解/残页新来源) + 熟练度阶段效果应用(A3 混合) + 最小验证内容(C1)**。三个独立单元,纯 domain/data,**不碰 presentation 层**(与 Codex 战斗 UI 零冲突)。

## 硬约束(红线)

- §5.4 数值红线:普伤 ≤8000 / 内力 ≤15000 / 装备攻击 ≤2000。熟练满阶 + 真解 + per-skill 效果叠加后任何招不得破线。
- §5.3 三系锁死:高阶真解/残页低境界/心法不达标可**解锁/收藏但不可装配**(复用现有 canEquip 模式)。
- §5.6 不硬编码:数值进 yaml(numbers/proficiency/skills/stages),文案走占位 key(§八,中文后补)。
- §2.5 综合加成上限 130% 当 cap;群体技单体倍率仍 < 同阶单体。
- domain 不做表现(既定红线)。
- 碰伤害公式 → balance_simulator 必跑。

## 一 · 单元 A:技能解锁进度(B2 轻量,账号级)

- **数据**:`SaveData` 新增 `skillUnlockProgress`。Isar 嵌入类 `SkillUnlockEntry { skillId; fragmentCount; unlocked }`(沿现有 `SkillUsageEntry` / `MapLikeOnSkillUsage` 体例)+ MapLike extension。**saveVersion bump**(实装查准当前 save_version 再 +1;注意 numbers.yaml 与 Isar schema 版本口径,以代码为准)。
- **domain** `SkillUnlockService`:
  - `grantManual(skillId)` → unlocked=true(主线真解首通)
  - `addFragment(skillId, n)` → fragmentCount += n;达 numbers 阈值自动 unlocked=true(幂等:集齐后再掉不重复解锁、不超阈值)
  - `isUnlocked(skillId)` / `fragmentProgress(skillId) → (current, threshold)`
- **不并入奇遇旧池**:奇遇技能 `equippedEncounterSkillId` + EncounterProgress 保留不动,新结构只管 Boss 来源,两套并存(避免大改;统一留二期 backlog)。

## 二 · 单元 B:Boss 掉技能书 wire

- **`stages.yaml` Boss 可选字段**:`dropSkillManualId`(主线,首通必给)/ `dropSkillFragmentId` + 掉率(爬塔,概率掉残页)。schema 三重校:仅 isBossStage 可配 / id 存在性 / 概率 ∈ [0,1]。
- **wire 点**:胜利结算后,沿 `stage_entry_flow` 既有 hook 链(在 `runEncounterHookAfterVictory` 之后,与 P4.1 stageBossRecruit 同段顺序)。首通判定复用现有 `clearedStageIds` / `highestTowerLayer`:真解仅首通给,重复挑战改掉残页/无(防刷)。→ 调 `SkillUnlockService`。
- **numbers.yaml**:`skill_unlock.fragment_threshold: 5` / `skill_unlock.tower_fragment_drop_prob: 0.20`(默认值,沿现有 drop 段;实玩后可调)。

## 三 · 单元 C:熟练度阶段效果(A3 混合)

- **`data/proficiency.yaml`(新)**:5 阶 `min_uses [0,30,100,300,800]`(初识/顺手/熟练/精通/化境)+ 全局阶段倍率 `[1.00,1.05,1.12,1.20,1.30]`。
- **`skills.yaml` 可选 `proficiency.effects`**(只配真解/招牌/破招技):per 阶段字段 `cooldown_delta` / `damage_pct` / `interrupt_power_pct` / `interrupt_window_bonus_ticks`。
- **domain** `SkillProficiency`(纯 Dart):从 `Technique.skillUsageCount.countOf(skillId)` 派生当前阶段(0 改计数逻辑,计数已在 `battle_resolution.dart` 累积)。
- **战斗接入**(`lib/core/combat/formulas.dart` / damage 路径):
  - 全局倍率:所有招(含普攻)最终伤害 × `proficiencyStageMult`(统一底)
  - per-skill 效果:有配的招额外应用(cooldown 在技能可用性判定处减;interrupt_power / window 在破招判定处加 — 复用 P0 canInterrupt/踉跄链路)
  - **叠加与 cap**:同一招的伤害向加成 = 全局阶段倍率 × (1 + per-skill `damage_pct`),**综合后必须 ≤ §2.5 的 130% 当阶 cap**(即 per-skill damage_pct 不得把综合顶破 cap),且绝对值不破 §5.4。红线测试双守(相对 cap + 绝对线)。
- **来源**:只由战斗放招累积(含挂机自动战斗 AI 放招),闭关不给(§16 #3 定否)。

## 四 · 最小验证内容(C1)

- 166 招补技能级 source tag(沿 techniques.yaml `acquireSourceTags` 体例)。
- 3 主线章末 Boss(stage_01_05 / 02_05 / 03_05)各 1 本真解;**02_05 青锋绝(skill_qingshan_qingfeng)已存在,复用作真解来源演示**。
- 1-2 套爬塔残页(集齐 5 片解锁 1 招)。
- per-skill `proficiency.effects` 只配这几本真解 + 破势(skill_po_shi)+ 青锋绝。
- 文案全占位 key。

## 五 · 红线 / 测试

- **schema 校验**:Boss 掉落字段三重校 + proficiency 阶段 min_uses 单调递增 + 全局倍率 cap ≤1.30。
- **红线测试**:熟练满阶 + 真解 + per-skill 效果叠加后(相对 ≤130% cap + 绝对不破 §5.4)任何招守线;装配 gate 守 §5.3(高阶真解低境界不可装配);残页幂等(集齐后再掉不重复解锁)。
- **balance_simulator 必跑**(碰伤害公式);失败的平衡测逐个确认是预期变化才调断言(别硬改掩盖)。
- 计数复用 `skillUsageCount`,0 改。

## 六 · P1a 不做(详 backlog)

技能装配限制 UI(§2.6)/ 藏经阁 screen / 统一进度展示组件 wiring / 24 招全内容 / 战报诊断规则(§11.4→P3)/ per-skill 效果铺广。详 `playability_phase2_backlog.md`。

## 七 · 默认拍板(可推翻,已记 backlog)

- §16 #4 数量:真解 1 本即解锁 / 残页 5 片一套(进 numbers.yaml)。
- 奇遇旧 unlock 池不并入新结构(两套并存)。
- 战报诊断规则不在 P1a(归 P3)。

## 八 · 实装注意

- **等 Codex 战斗 UI 收工再实装**(单元 C 接 damage 路径,避免与战斗 presentation 改动间接撞车;A/B 纯 domain/data 可早动但建议整波一起)。
- **bg 写守卫**:实装走 feat 分支 + subagent implementer(有写权限)+ Bash heredoc 写文档。
- **合 main 前 Claude 过闸**:analyze 0 + 全量测试 + §5.4 红线 + 硬编码扫 + balance_simulator。
- **Phase 0 先行**:实装前对"0 存在/0 引用"结论做三维 grep 复核(本 spec 中 canInterrupt/aiUsePolicy/破势/青锋绝 字段已确认存在于 data/skills.yaml:1948+;skillUsageCount 计数已确认存在)。
- 估时:单元 A ~4-5h / B ~3-4h / C ~5-7h / 最小内容 ~2-3h ≈ 14-19h xhigh。
