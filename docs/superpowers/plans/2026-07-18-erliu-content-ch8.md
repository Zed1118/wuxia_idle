# Ch8 二流第2章内容批 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地主线 Ch8（二流第2章·追灰衣人·铜符引路北上），末Boss=灰衣人本人，**新写 1 门二流阴柔真解**（破招首通掉），补齐二流段第 2 章内容并把主线推到 40 关。

**Architecture:** 纯内容 + 配置批——`data/stages.yaml` 加 5 关（chapterIndex 8·requiredRealm erLiu·灰衣人章中Boss + 末Boss）、`data/skills.yaml` **新增 1 门二流阴柔真解**（无孤儿可复用）、`data/narratives/` 加 chapter_08 + stage 文案、`data/equipment.yaml`+`data/lore/` 复用/补好家伙 tier 掉落。**零 Isar schema / saveVer 改动**（复用现有 `StageDef`/`dropSkillManualId`/`chargeSkillId` 字段）。加章 reconcile 面 ~11 测站点 + 6 生产站点（部分 Ch7 已做成 cap-agnostic，仅 verify）。

**Tech Stack:** Flutter Desktop · YAML 数据层 · Isar · `flutter test`（并发）。**设计源** `docs/superpowers/specs/2026-07-18-erliu-content-ch8-design.md`。

**执行前必读（本项目约定）:**
- YAML key：`data/stages.yaml`/`data/skills.yaml` 用 **camelCase**（`dropSkillManualId`/`chargeSkillId`/`realmTier`），其余 yaml snake_case。
- 中文注释 Edit 前 Read 精确字节，查全/半角（`feedback_edit_chinese_punctuation_pitfall`）。
- 全量测默认并发 `flutter test --no-pub`；compact reporter **首个 `-N` 才是真失败**（`feedback_flutter_test_minus1_carryforward`）。
- **报「全绿/0/完成」前必跑验证贴输出**，禁转抄（`reference_anti_hallucination`）。
- progression 级联 Lv 快照 **逐值实测·禁猜**（跑测 fail-fast 读期望值再改）。
- 新招 id 用于 wiring（skills.yaml + stages.yaml ×2 处）——若 T3 narrative 批改名，同步 3 处引用。

---

## 文件结构

| 文件 | 职责 | 任务 |
|---|---|---|
| `data/stages.yaml` | 加 stage_08_01..05（骨架/二流敌队/灰衣人章中Boss/末Boss/dropTable/挂载字段） | T1, T2 |
| `data/skills.yaml` | **新增 1 门二流阴柔真解**（灰衣人本命·末Boss chargeSkill=dropSkillManualId 双用） | T2 |
| `data/narratives/chapters/chapter_08.yaml` + `data/narratives/stages/stage_08_*.yaml` | 章首尾 + 10 段 stage + 2 defeat（13 文件） | T3 |
| `data/equipment.yaml` + `data/lore/*.yaml` | 好家伙 tier 掉落（优先复用）+ 北派本源遗物典故 | T1/T3 |
| `test/tools/progression_playtest_diagnostic_test.dart:16` | `_mainlineStageCount` 35→40 + CSV evidence 重生 | T4 |
| `test/features/mainline/mainline_narrative_completeness_test.dart:58,67` | count 35→40 + 章循环 `i<=7`→`8` | T4 |
| `test/data/stages_boss_enemy_test.dart:41` | isBoss 敌总数 16→+Ch8 | T4 |
| `test/features/battle_record/application/boss_memory_providers_test.dart:50,66` | 主线 boss stage 23→+Ch8 / 总 29→+Ch8 | T4 |
| `test/data/game_repository_test.dart:65+` | mainlineCount / 主线 N 关红线 / prevStageId 单链 | T4 |
| `test/tools/balance_simulator_test.dart:63,72` | 描述文本 35→40（+ 校准 Ch8 敌队） | T1/T4 |
| `test/features/cultivation/application/progression_release_budget_test.dart` | 首通/全内容 Lv 快照逐值实测 | T4 |
| `lib/features/mainline/presentation/chapter_list_screen.dart:30` | `_chapters` `[1..7]`→`[1..8]` | T4 |
| `lib/shared/strings.dart:1340,1352,1363,1370,1429,1443` | 主菜单 hint「8章40关」/ 六章→八章 / chapter8Title+Hint / switch 补 case 8 | T4 |
| `PROGRESS.md` / `GDD.md` | closeout | T5 |

---

## Task 1: Ch8 五关骨架 + 二流敌队 + 灰衣人章中Boss + 末Boss骨架 + 好家伙掉落

**Files:**
- Modify: `data/stages.yaml`（stage_07_05 块之后追加 stage_08_01..05）
- Modify: `data/equipment.yaml`（仅当好家伙 tier 掉落不足时新增）
- Test: `test/data/defs/stage_win_condition_test.dart`, `test/data/mainline_stage_curve_redline_test.dart`, `test/data/stage_skill_drop_redline_test.dart`

**数值锚**：二流敌队沿 Ch7 stage_07_01..05 现值（同 tier·实读参照）；末Boss 灰衣人（阴柔）baseHp/Attack 参照 stage_07_05 北派宗匠（刚猛末Boss）同带、阴柔向略降 Hp 升 speed。**逐关数值经 Step 6 balance_simulator 校准，非拍脑袋。**

- [ ] **Step 1: 先跑基线，确认当前 35 关全绿**

Run: `flutter test test/tools/progression_playtest_diagnostic_test.dart --no-pub`
Expected: PASS（`_mainlineStageCount == 35`）。记基线通过数。

- [ ] **Step 2: 实读 Ch7 五关体例做模板**

Run: `sed -n '1590,1810p' data/stages.yaml`（stage_07_01..05 全块）。照抄字段结构（camelCase）：`id`/`name`/`stageType: mainline`/`chapterIndex`/`prevStageId`/`narrativeOpeningId`/`narrativeVictoryId`(/`narrativeDefeatId`)/`requiredRealm: erLiu`/`enemyTeam`(inline 二流敌)/`isBossStage`/`chargeSkillId`/`bossPhases`/`dropTable`。

- [ ] **Step 3: 追加 stage_08_01..05 骨架到 `data/stages.yaml`**

在 stage_07_05 块之后追加。逐关 `chapterIndex: 8`、`requiredRealm: erLiu`、`prevStageId` 链（08_01.prevStageId=stage_07_05；08_02..05 链本章）、`narrative*Id` 指向 T3 文件名。

灰衣人 **章中Boss 置 stage_08_03**（`school: yinRou`·`isBoss: true`·enemy id `enemy_erLiu_huiyi_saibei` 沿 Ch7 `enemy_erLiu_huiyi_beijing` 命名例）。**末Boss stage_08_05 = 灰衣人本人（阴柔·二流）** 示例（数值待 Step 6 校准，chargeSkill 指向 T2 新招）：

```yaml
  # === stage_08_05 · （关名待 T3）章末大 Boss · 灰衣人本人(阴柔·追索终局) ===
  - id: stage_08_05
    name: 关名待定
    stageType: mainline
    chapterIndex: 8
    prevStageId: stage_08_04
    narrativeOpeningId: stage_08_05_opening
    narrativeVictoryId: stage_08_05_victory
    narrativeDefeatId: stage_08_05_defeat
    requiredRealm: erLiu
    enemyTeam:
      - id: enemy_erLiu_huiyi_final
        name: 灰衣人
        realmTier: erLiu
        realmLayer: shuLian
        school: yinRou
        baseHp: 14500        # 待 Step 6 校准（阴柔向·参 stage_07_05 北派宗匠同带略降）
        baseAttack: 540      # 待 Step 6 校准
        baseSpeed: 300       # 阴柔快
        skillIds:
          - skill_yinrou_mingjia_basic   # 占位·Step 2 盘点现有二流阴柔名家功招填真名
          - skill_hui_xiu_hui_feng       # 本命真解 = 末Boss chargeSkill（T2 新写·双用）
        iconPath: assets/enemies/huiyi_final.png   # 缺图走 errorBuilder
        isBoss: true
        chargeSkillId: skill_hui_xiu_hui_feng   # 破招:玩家拦截,首通掉同招真解(T2 加 dropSkillManualId + onEnterMechanic)
        bossPhases:
          - hpThresholdPct: 1.0
          - hpThresholdPct: 0.5
            aiMode: aggressive
            onEnterMechanic: chargeCounter   # 成对配 chargeSkillId(否则 readable_tempo missingBossMechanic)
    isBossStage: true
    dropTable:
      - equipmentDefId: <好家伙 tier·Step 5 盘点>
        dropChance: 1.0
```

其余 08_01/02/04：非 boss 杂兵关（`isBossStage` 省略）；08_03 灰衣人章中Boss。**skillIds 占位招（`skill_*_mingjia_basic`）须 Step 4 换真名**。

- [ ] **Step 4: 盘点现有二流名家功招填 skillIds 占位**

Run: `grep -nE "tier: 3" data/skills.yaml | head -40` 与 `grep -nB2 "style: yinRou" data/skills.yaml | grep -E "id:|tier: 3"`
把 Step 3 各敌 `skillIds` 的 `skill_*_mingjia_basic` 占位换成实读的二流（tier3）对应流派名家功招 id（刚猛/灵巧/阴柔按敌 school）。**不新增招**（真解招在 T2）。

- [ ] **Step 5: 盘点好家伙 tier 掉落，填 dropTable**

Run: `grep -nE "tier: haoJiaHuo" data/equipment.yaml | head -30`
Ch8 dropTable 优先**复用**现有好家伙武器/防具/饰品；**不足才新增**（YAGNI·新增须配 `data/lore/<id>.yaml` 否则 loader 抛错，留 T3）。填各关 `dropTable`。

- [ ] **Step 6: balance 校准 + stage 红线**

Run: `flutter test test/data/stage_win_condition_test.dart test/data/mainline_stage_curve_redline_test.dart test/data/stage_skill_drop_redline_test.dart test/tools/balance_simulator_test.dart --no-pub`
Expected: `mainline_stage_curve` PASS（Ch8 requiredRealm erLiu·已 cap-agnostic 自动过）；`stage_skill_drop_redline` 若报 `stage_08_05 chargeSkillId=skill_hui_xiu_hui_feng` 未定义 → 属 T2（本步先注释掉 chargeSkillId + skillIds 里的新招，或先做 T2）。`balance_simulator` 看 Ch8 五关通关率落 Ch4-7 同带（on-level ~100%/欠配下降·不进百万）。**按输出反复调 baseHp/Attack·贴通关率输出**。

> 注：`stage_08_05` 引用未定义的 `skill_hui_xiu_hui_feng` 会让加载红线炸——**T1 与 T2 有序依赖**，建议 T1 骨架先用现有招占位 chargeSkill、Step 6 只验非 boss 关，末Boss chargeSkill/真解留 T2 一起绿。

- [ ] **Step 7: Commit**

```bash
git add data/stages.yaml data/equipment.yaml
git commit -m "加 Ch8 二流五关骨架 + 二流敌队 + 灰衣人章中/末Boss + 好家伙掉落"
```

---

## Task 2: 新写二流阴柔真解（灰衣人本命）+ 末Boss 挂载 + 红线复核

**Files:**
- Modify: `data/skills.yaml`（新增 `skill_hui_xiu_hui_feng` 招块）
- Modify: `data/stages.yaml`（stage_08_05 加 `dropSkillManualId` + 确认 `chargeSkillId`/`onEnterMechanic`）
- Test: `test/data/skill_source_redline_test.dart`, `test/data/wave_b_content_redline_test.dart`, `test/features/cultivation/wave_b_drop_skill_wiring_test.dart`, `test/data/stage_skill_drop_redline_test.dart`

- [ ] **Step 1: 实读现有二流阴柔真解做锚**

Run: `sed -n '3028,3060p' data/skills.yaml`（skill_zhu_ying_yao_hong 烛影摇红 tier3 阴柔 mult 2600）+ `sed -n '3192,3214p' data/skills.yaml`（skill_suo_mai_zhen 结构·proficiency 表体例）。照结构写新招。

- [ ] **Step 2: 新增 `skill_hui_xiu_hui_feng` 到 `data/skills.yaml`**

在 skills.yaml 末（或阴柔真解群附近）追加。**mult 须 > 灰衣人其余 powerSkill**（AI 蓄力自动选中·实装 Step 6 核）：

```yaml
  # ───────────────────────────────────────────
  # Ch8 灰衣人本命真解「灰袖回风」(2026-07-18)
  # ───────────────────────────────────────────
  # Ch7 灰衣人只露烛影摇红(残页)一手,Ch8 追索终局逼出真正本命阴柔绝艺。
  # 末Boss stage_08_05 chargeSkillId 双用 = dropSkillManualId(破招首通掉·沿「破他的招、学他的招」canon)。
  # mult 锚 烛影摇红 2600 / 千钧坠岳 2800,取 2900(tier3 二流真解·守全局 ≤8000)·Step 6 核。
  - id: skill_hui_xiu_hui_feng
    name: 灰袖回风
    description: 灰衣人袖底藏锋,回风一卷,残照沉魄。看似退步收招,杀意已在袖中折返。
    type: powerSkill
    targetType: single
    powerMultiplier: 2900          # tier3 二流真解锚(烛影摇红2600/千钧坠岳2800)·Step 6 balance 核·守 ≤8000
    qiDelta: -35
    cooldownTurns: 4
    requiresManualTrigger: false
    parentTechniqueDefId: null
    visualEffect: sleeve_return_wind   # 缺资源不破(视觉 key)
    source: mainline_drop
    style: yinRou
    tier: 3
    proficiency:        # 真解手工高半档(阴柔向:伤害温和 + CD·沿烛影摇红/斜雨穿帘锚)
      effects:
        shuLian: { damage_pct: 0.08 }
        jingTong: { damage_pct: 0.08, cooldown_delta: -1 }
        huaJing: { cooldown_delta: -1 }
```

- [ ] **Step 3: stage_08_05 加真解挂载字段**

在 stage_08_05 块（T1 Step 3）确认/追加 `dropSkillManualId`（`name` 后，沿 stage_07_05 体例）：

```yaml
    dropSkillManualId: skill_hui_xiu_hui_feng  # 真解(灰袖回风·灰衣人本命·同招为 boss chargeSkillId 双用·破招首通 markUnlocked)
```

并确认 `chargeSkillId: skill_hui_xiu_hui_feng` + bossPhase `onEnterMechanic: chargeCounter` 已在（T1 Step 3 骨架已含）。

- [ ] **Step 4: 跑 skill 加载 + drop 红线**

Run: `flutter test test/data/skill_source_redline_test.dart test/data/stage_skill_drop_redline_test.dart --no-pub`
Expected: PASS。红线④（`dropSkillManualId`→mainlineDrop✓·新招 source=mainline_drop）⑥（drop 招须 style+tier✓）⑦（挂载完备·新招恰 1 挂载点✓·不 deferred）。若报「skill_hui_xiu_hui_feng 缺挂载/重复挂载」→ 查 Step 2 source + Step 3 唯一 dropSkillManualId。

- [ ] **Step 5: 跑 wave_b 3 测，复核新招不进配平池**

Run: `flutter test test/data/wave_b_content_redline_test.dart test/features/cultivation/wave_b_drop_skill_wiring_test.dart --no-pub`
Expected: PASS 不变。**新招是独立末Boss真解，非 wave_b 真解 2/2/2 或残页 3/3/3 池成员**——若某测按「全招集合」遍历断言 style 计数且把新 mainline_drop 招算进阴柔配平（多 1 阴柔真解）→ 更新断言为现状（wave_b 池成员是显式白名单集合，非「所有 mainline_drop 阴柔招」·写集合自洽语义·沿 `feedback_red_line_test_semantics`）。贴通过输出。

- [ ] **Step 6: balance 校准末Boss（真解威胁 + AI 蓄力选中）**

Run: `flutter test test/tools/balance_simulator_test.dart --no-pub`（含 readable_tempo 若同套）
Expected: stage_08_05 灰衣人蓄力时 AI 选中 `skill_hui_xiu_hui_feng`（mult 2900 > 其余 powerSkill）；通关率落 Ch4-7 同带。**若 AI 不选新招 → mult 未压过其余招，上调（守 ≤8000）**。贴输出。

- [ ] **Step 7: Commit**

```bash
git add data/skills.yaml data/stages.yaml test/data/wave_b_content_redline_test.dart test/data/skill_source_redline_test.dart test/features/cultivation/wave_b_drop_skill_wiring_test.dart
git commit -m "新写灰袖回风二流真解 + 灰衣人末Boss 挂载 + wave_b 复核"
```

---

## Task 3: Ch8 叙事文案（章首尾 + 10 段 stage + 2 defeat）+ 好家伙/遗物典故

**Files:**
- Create: `data/narratives/chapters/chapter_08.yaml`
- Create: `data/narratives/stages/stage_08_01_opening.yaml` … `stage_08_05_victory.yaml`（10 段）+ `stage_08_04_defeat.yaml` + `stage_08_05_defeat.yaml`
- Create/Modify: `data/lore/<id>.yaml`（仅 T1 Step 5 新增装备时）
- Test: `test/features/mainline/mainline_narrative_completeness_test.dart`, `test/tools/asset_audit_test.dart`, `test/data/pubspec_asset_declaration_test.dart`

**体例锚**（沿 `project_wuxia_idle_ch4_cultural_arc` + 实读 chapter_07.yaml）：
- chapter_08 章首尾 = **第三人称「新掌门」**（无固定名），李寒作太祖第三人称。章首承 Ch7 尾「怀里铜符指着更北·主动北追」；章末「听懂另半句」顿悟 + 灰衣人败中吐露北派本源 → Ch9 hook。
- stage 段 = 第二人称「你」。~4-6k 字总量。
- **师父遗言 motif 3 处贯穿**：章首承上（铜符指更北）/ 章末启下（听懂另半句）/ defeat 回响。
- 地理弧：漠南草原 → 大漠/瀚海 → 关外孤城 → 更北北派根脉（真北方地名·非臆造 biome）。
- **Tier 风格词**（二流·略进 Ch7）：笃定/独行/追索/自立。**黑名单词扫 0 命中**。

- [ ] **Step 1: 实读 chapter_07.yaml + 2-3 段 Ch7 stage 文案做体例模板**

Run: `cat data/narratives/chapters/chapter_07.yaml` + `cat data/narratives/stages/stage_07_05_opening.yaml data/narratives/stages/stage_07_05_victory.yaml data/narratives/stages/stage_07_05_defeat.yaml`。照 `id`/`title`/`prologue`/`epilogue`（chapter）与 `id`/`title`/`paragraphs`（stage）结构。

- [ ] **Step 2: 写 chapter_08.yaml（章首尾）**

prologue 承 Ch7 铜符北追心境；epilogue 章末拐点（听懂另半句）+ 灰衣人败露北派本源 + Ch9 hook。

- [ ] **Step 3: 写 10 段 stage opening/victory + 2 段 defeat**

每 stage 一 `*_opening.yaml` + `*_victory.yaml`；stage_08_04/05 各一 `*_defeat.yaml`。id 严格对应 T1 的 `narrative*Id`。灰衣人章中(08_03)/末战(08_05)文案呼应「烛影→本命回风」的揭示。

- [ ] **Step 4: 若 T1 新增装备，补 lore 典故**

仅当 T1 Step 5 新增好家伙装备：每件配 `data/lore/<id>.yaml`（`_validatePresetLoreReferences` 强校验·缺则加载抛错）。北派本源遗物 = 叙事物件（lore 承载·非数值）。narrative 沿用现有 `chapters/`+`stages/` 目录（Ch7 已 pubspec 声明）→ **无需改 pubspec**。

- [ ] **Step 5: 跑叙事完整性 + asset audit + 黑名单扫描**

Run: `flutter test test/features/mainline/mainline_narrative_completeness_test.dart test/tools/asset_audit_test.dart test/data/pubspec_asset_declaration_test.dart --no-pub`
> 注：`mainline_narrative_completeness` 会因 count 35→40 + 章循环 `i<=7` 而红 → 属 **T4** reconcile（本步聚焦文件存在性/id 自洽/无 placeholder，count 断言留 T4）。若只想验文案存在，先看 fail 是 count 断言还是缺文件。

Run: `grep -rniE "legendary|epic|神器|传说级|无敌|血溅|刀光剑影|史诗|神话|究极|霸气|逆天" data/narratives/chapters/chapter_08.yaml data/narratives/stages/stage_08_*.yaml`
Expected: 0 命中。

- [ ] **Step 6: Commit**

```bash
git add data/narratives/chapters/chapter_08.yaml data/narratives/stages/stage_08_*.yaml data/lore/
git commit -m "写 Ch8 二流第2章叙事文案(章首尾 + 10 段 stage + 2 defeat)"
```

---

## Task 4: 加章 reconcile 全站点（count 断言 + 生产可见性 + Lv 快照）

> memory `feedback_wuxia_add_mainline_chapter_reconcile`：Ch7 实证 ~11 测站点 + 6 生产站点·**先全 Phase-0 grep·别打地鼠**。部分站点 Ch7 已做 cap-agnostic（仅 verify）。

**Files:** 见下逐 Step。

- [ ] **Step 1: Phase-0 grep 扫全部硬编码章数/count 站点**

Run（枚举·防漏）:
```bash
grep -rnE "\b35\b|\b23\b|\b29\b|\b16\b|<= ?7|== ?7|1, ?7|七章|7 章|六章|Ch1-7|Ch4-7" lib/ test/ | grep -viE ":[0-9]+:[[:space:]]*//"
```
对照下列已知站点核对，补任何本 grep 新暴露的硬编码点。

- [ ] **Step 2: 生产可见性——章列表 + 主菜单文案（否则 Ch8 不显示=死内容）**

- `lib/features/mainline/presentation/chapter_list_screen.dart:30`：`_chapters = [1, 2, 3, 4, 5, 6, 7]` → `[1, 2, 3, 4, 5, 6, 7, 8]`
- `lib/shared/strings.dart:1340`：`'7 章 35 关,按章节顺序解锁'` → `'8 章 40 关,按章节顺序解锁'`
- `lib/shared/strings.dart:1352`：`'六章江湖路 · 每章五关，朱印为 Boss'` → `'八章江湖路 · 每章五关，朱印为 Boss'`（**Ch7 遗留 stale·顺手订正**）
- `lib/shared/strings.dart:1363` 后加：`static const String chapter8Title = '第八章 · <T3 章名>';`
- `lib/shared/strings.dart:1370` 后加：`static const String chapter8Hint = '<Ch8 一句 hint·如 漠南追影、瀚海孤城、灰袖回风>';`
- `lib/shared/strings.dart:1429`（chapterTitle switch）加 `8 => chapter8Title,`
- `lib/shared/strings.dart:1443`（chapterHint switch）加 `8 => chapter8Hint,`

- [ ] **Step 3: 生产可见性——主菜单/摘要章循环上界（grep 定位）**

Run: `grep -rnE "<= ?7|chapterIndex|循环|for .*ch" lib/features/*/presentation/main_menu*.dart lib/features/*/presentation/*status_summary*.dart 2>/dev/null`
若有硬编码章上界 `<= 7`（或 `< 8`）→ 改 8（或 `<= 8`）。**boss_memory_key.dart 已 cap-agnostic（`chNum >= 7 → chNum+3`·Ch8→11 自动）→ 无需改·仅 verify**。

- [ ] **Step 4: count 断言 reconcile（跑测 fail-fast 逐个改）**

逐文件改（值已实读·fail-fast 复核）：
- `test/tools/progression_playtest_diagnostic_test.dart:16`：`const _mainlineStageCount = 35;` → `40`
- `test/features/mainline/mainline_narrative_completeness_test.dart:58`：`35` → `40`；`:67`：`for (var i = 1; i <= 7; i++)` → `i <= 8`；`:59-62` 覆盖数断言按 fail 值改
- `test/data/stages_boss_enemy_test.dart:41`：`expect(total, 16);` → Ch8 isBoss 敌数（灰衣人章中1 + 末Boss1 = +2 → `18`·按实际 enemyTeam isBoss 计数）
- `test/features/battle_record/application/boss_memory_providers_test.dart`：`:50` `hasLength(29)` → `31`；`:66/69` 主线 boss stage `23` → `25`；reason 串同步（`主线 25 + 塔 6 = 31`）
- `test/data/game_repository_test.dart:65+`：跑测，按 fail 改 mainlineCount（35→40）/ 主线 N 关红线（含 4-5 Boss）/ R3 prevStageId 单链断言
- `test/tools/balance_simulator_test.dart:63,72`：描述文本 `35`→`40`、reason「Ch7 二流首章 = 35 关」→「+ Ch8 = 40 关」（+ 顺手订正残留 `30 关` stale 注释 line 5/146/147/152）

Run（改后逐个验）: `flutter test test/tools/progression_playtest_diagnostic_test.dart test/features/mainline/mainline_narrative_completeness_test.dart test/data/stages_boss_enemy_test.dart test/features/battle_record/application/boss_memory_providers_test.dart test/data/game_repository_test.dart --no-pub`
Expected: PASS。

- [ ] **Step 5: CSV evidence byte-lock 重生（progression_playtest）**

Run: `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1 flutter test test/tools/progression_playtest_diagnostic_test.dart --no-pub`
Expected: `updated evidence: ...` 打印；再跑一次（不带 env）应 PASS（40 关 × 3 × seed 行数对齐）。

- [ ] **Step 6: progression 级联 Lv 快照逐值实测（禁猜）**

Run: `flutter test test/features/cultivation/application/progression_release_budget_test.dart --no-pub`
Expected: 加 Ch8 exp 推高全局 Lv → 首通/全内容 Lv + cumExp 位移。**fail-fast 停首个错值 → 读期望值 → 改断言 → 再跑单文件**（逐值·守 `reference_anti_hallucination`·`feedback_progression_release_budget` 体例）。贴最终值。

- [ ] **Step 7: readable_tempo（末Boss 机制 + 章 ratchet）**

Run: `grep -rln "readable_tempo\|readableTempo" test/` → 定位文件；`flutter test <该文件> --no-pub`
Expected: PASS。若 `missingBossMechanic` 报 stage_08_05 → 查 T1/T2 `chargeSkillId` + bossPhase `onEnterMechanic: chargeCounter` 成对（已配）。若章 ratchet 循环硬编码 `<=7`/名单 → 补 Ch8。

- [ ] **Step 8: Commit**

```bash
git add lib/features/mainline/presentation/chapter_list_screen.dart lib/shared/strings.dart test/
git commit -m "Ch8 加章 reconcile：count 35→40 + 生产可见性 + Lv 快照逐值实测"
```

---

## Task 5: 全量验证 + closeout

**Files:**
- Modify: `PROGRESS.md`（顶段加 Ch8 批·四态）
- Modify: `GDD.md`（主线章数/二流内容口径同步·标 `[GDD]`）

- [ ] **Step 1: 全仓 analyze**

Run: `flutter analyze --no-pub`
Expected: `No issues found`。

- [ ] **Step 2: 全量测（并发）**

Run: `flutter test --no-pub`
Expected: 全绿。**首个 `-N` 才是真失败**；对照基线 4283，新增 = Ch8 相关测。贴通过/失败数。

- [ ] **Step 3: macOS build 冒烟**

Run: `flutter build macos --debug`
Expected: `✓ Built`（新 asset 引用/errorBuilder 兜底不破构建）。缺美术图入 `test/fixtures/known_missing_assets.txt`（灰衣人 final 立绘/章封面/5 剧情背景/新 biome·errorBuilder 兜底）。

- [ ] **Step 4: 更新 PROGRESS 顶段（四态：已完成/已验证/已知风险/下批建议）**

Ch8 批：已完成（5 关 + 灰袖回风新招 + 灰衣人末Boss + 13 叙事 + 生产可见性）/已验证（analyze 0 + 全量数 + build·**本会话实测非转抄**）/已知风险（美术缺走 errorBuilder 待拍 / Ch9 hook 北派本源留续章）/下批建议（Ch9 或塔二流段·承 Ch8 北派本源 hook）。**未 push（push 是用户的活）**。

- [ ] **Step 5: GDD 同步**

主线章数 Ch1-7 → Ch1-8、二流段口径含 Ch8 → 改（GDD §8.1 主线章表 + 二流 note）。标题加 `[GDD]`。

- [ ] **Step 6: Commit（不 push）**

```bash
git add PROGRESS.md GDD.md
git commit -m "Ch8 二流第2章批 closeout（全量绿 + 进度四态）"
```

---

## Self-Review（spec 覆盖核对）

- ✅ spec §1 定位主角 → T1（stages requiredRealm erLiu）+ T3（角色化「新掌门」文案）
- ✅ spec §2 叙事弧（铜符北追/灰衣人/师父遗言/更北地理/风格词/黑名单）→ T3
- ✅ spec §3 关卡结构（5 关 + 灰衣人章中 + 末战）→ T1
- ✅ spec §4 末Boss=灰衣人 + 新写二流阴柔真解 + chargeSkill/onEnterMechanic 成对 → T1（骨架）+ T2（新招 + 挂载 + wave_b 复核）
- ✅ spec §5 红线（挂载④⑥⑦ / 二流 tier lock / pubspec / 语义化）→ T2 + T3
- ✅ spec §6 内容产物验收（narrative 13 文件 / lore / 新招 / 测试 / errorBuilder）→ T3 + T5
- ✅ spec §7 加章 reconcile 全站点 → T4（Phase-0 grep + count + 生产可见性 + Lv 快照）
- ✅ spec §8 非目标 → 计划不含 Ch9/塔段/断魂庄/抬 cap/gauntlet 简化

**依赖顺序**：T1 → T2（末Boss chargeSkill 依赖 T2 新招·见 T1 Step 6 注）→（T3 ∥ T4）→ T5。T3/T4 均依赖 T1+T2 的 stage/skill 骨架，之后可并行；T4 count 断言依赖 T1 五关落地。

**已知取舍**：新招 id `skill_hui_xiu_hui_feng`（暂名「灰袖回风」）——T3 narrative 批若改名，同步 skills.yaml + stages.yaml（chargeSkillId + dropSkillManualId）3 处引用。章名/逐关关名/biome 由 T3 narrative 批定（沿 Ch7 章名后定例）。

---

## 恢复点（终态 2026-07-18）

- **状态**：T1-T5 全部完成，PR #43 draft 已开（https://github.com/Zed1118/wuxia_idle/pull/43）
- **最后完成**：全量 4383/0 + build macos ✓ + GDD/PROGRESS 同步 + push 分支
- **计划偏差实录**：① defeat 位随 Boss 位挪 08_03（validator defeat⟹Boss 逮出 plan 笔误）；② `stage_win_condition_test.dart` 不存在（plan 臆造文件名·等价覆盖=curve/drop 红线+load 链）；③ T1+T2 合一 commit（yaml 联结红线要求招定义与挂载原子到位）；④ 追加站点：skill_count 契约(208/248+GDD 表双向 lock)/skill_qi/chapter_list UI 测/supply 语义线 2→3 件
- **下一步**：用户审 PR #43 → 合并 → Ch9 或塔二流段
