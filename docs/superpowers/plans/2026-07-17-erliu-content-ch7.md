# Ch7 二流首章内容批 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地主线 Ch7（二流首章·真传位新弧·北派/灰衣人线），挂载 2 孤儿招（千钧坠岳真解 + 烛影摇红残页），补齐全游戏首个二流主线内容。

**Architecture:** 纯内容 + 配置批——`data/stages.yaml` 加 5 关（chapterIndex 7·requiredRealm erLiu）、`data/skills.yaml` 删 2 招 `mount_deferred` + `data/stages.yaml` 加挂载字段、`data/narratives/` 加 chapter_07 + stage 文案、`data/equipment.yaml`+`data/lore/` 补好家伙 tier 掉落。**零 Isar schema / saveVer 改动**（复用现有 `StageDef`/`dropSkillManualId`/`dropSkillFragmentId` 字段）。

**Tech Stack:** Flutter Desktop · YAML 数据层 · Isar · `flutter test`（并发）。**设计源** `docs/superpowers/specs/2026-07-17-erliu-content-ch7-design.md`。

**执行前必读（本项目约定）:**
- YAML key：`data/stages.yaml`/`data/skills.yaml` 用 **camelCase**（`dropSkillManualId`/`chargeSkillId`/`realmTier`），其余 yaml snake_case。
- 中文注释 Edit 前查全/半角（`feedback_edit_chinese_punctuation_pitfall`）。
- 全量测默认并发 `flutter test --no-pub`；compact reporter 首个 `-N` 才是真失败。
- **报「全绿」前必跑验证贴输出**，禁转抄。

---

## 文件结构

| 文件 | 职责 | 任务 |
|---|---|---|
| `data/stages.yaml` | 加 stage_07_01..05（骨架/敌队/掉落/boss chargeSkill/挂载字段） | T1, T2 |
| `data/skills.yaml` | 删 2 招 `mount_deferred: true`（2 行） | T2 |
| `test/tools/progression_playtest_diagnostic_test.dart` | `stages.length` 30→35 | T1 |
| `test/tools/balance_simulator_test.dart` | 30 关 sweep → 含 Ch7（chapterIndex 7） | T1 |
| `test/features/economy/stage_silver_ratio_redline_test.dart` | 30 关口径 → 35（若硬编码） | T1 |
| `test/features/sect/stage_boss_recruit_test.dart` | Ch1-6 → Ch1-7（若 Ch7 boss 配 bossRecruit） | T1 |
| `test/data/wave_b_content_redline_test.dart` 等 3 测 | 复核 + 更新断言 deferred 状态处 | T2 |
| `data/narratives/chapters/chapter_07.yaml` + `data/narratives/stages/stage_07_*.yaml` | 章首尾 + 10 段 stage + defeat | T3 |
| `pubspec.yaml` | 若新 narrative 目录须声明 | T3 |
| `data/equipment.yaml` + `data/lore/*.yaml` | 好家伙 tier 掉落 + 北派信物遗物 | T4 |
| `PROGRESS.md` / `GDD.md` | closeout | T5 |

---

## Task 1: Ch7 五关骨架 + 二流敌队 + boss chargeSkill + 硬编码 count 断言 reconcile

**Files:**
- Modify: `data/stages.yaml`（stage_06_05 末尾后追加 stage_07_01..05）
- Modify: `test/tools/progression_playtest_diagnostic_test.dart:42`
- Modify: `test/tools/balance_simulator_test.dart`（chapterIndex 过滤 / 30 关口径）
- Modify: `test/features/economy/stage_silver_ratio_redline_test.dart`（若硬编码 30）
- Test: `test/data/stage_win_condition_test.dart`, `test/data/mainline_stage_curve_redline_test.dart`, `test/data/stage_skill_drop_redline_test.dart`

**数值锚**：二流敌队 baseHp/Attack/Speed 参照 `data/boss_gauntlets.yaml` 断魂庄二流 boss（苏无咎/石镇岳/闻九针）+ `data/stages.yaml` stage_06_05（三流 boss baseHp 12000/atk 450/spd 270，二流为上一阶，按现有 tier 曲线上抬）。**逐关数值经 T1 步 6 balance_simulator 校准，非拍脑袋。**

- [ ] **Step 1: 先跑基线，确认当前 30 关全绿**

Run: `flutter test test/tools/progression_playtest_diagnostic_test.dart --no-pub`
Expected: PASS（`stages.length == 30`）。记下基线通过数。

- [ ] **Step 2: 追加 stage_07_01..05 骨架到 `data/stages.yaml`**

在 stage_06_05 块之后追加 5 关。逐关字段沿 stage_06_XX 体例（camelCase）。**stage_07_05 章末 boss 示例**（数值待 Step 6 校准）：

```yaml
  # === stage_07_05 · （关名待 T3）章末大 Boss · 北派重手宗匠 ===
  - id: stage_07_05
    name: 关名待定
    stageType: mainline
    chapterIndex: 7
    prevStageId: stage_07_04
    narrativeOpeningId: stage_07_05_opening
    narrativeVictoryId: stage_07_05_victory
    narrativeDefeatId: stage_07_05_defeat
    requiredRealm: erLiu
    enemyTeam:
      - id: enemy_erLiu_beipai_zongjiang
        name: 北派重手宗匠
        realmTier: erLiu
        realmLayer: shuLian
        school: gangMeng
        baseHp: 16000        # 待 Step 6 balance 校准（stage_06_05=12000 三流→二流上抬）
        baseAttack: 560      # 待 Step 6 校准
        baseSpeed: 250
        skillIds:
          - skill_gangmeng_mingjia_basic   # 占位·二流刚猛招，实值 T1 盘点现有名家功刚猛招
          - skill_qian_jun_zhui_yue        # boss 招牌蓄力技 = 章末真解（双用 canon）
        iconPath: assets/enemies/beipai_zongjiang.png   # 缺图走 errorBuilder
        isBoss: true
        chargeSkillId: skill_qian_jun_zhui_yue   # 破招:玩家拦截,首通掉同招真解(T2 加 dropSkillManualId)
        bossPhases:
          - hpThresholdPct: 1.0
          - hpThresholdPct: 0.5
            aiMode: aggressive
            titleKey: bossPhase_desperate
    isBossStage: true
    dropTable:
      - equipmentDefId: weapon_haojiahuo_qing_feng_jian   # T4 盘点/新增好家伙 tier 掉落
        dropChance: 1.0
```

其余 07_01..04：非 boss 关（`isBossStage` 省略），`enemyTeam` 二流杂兵；**灰衣人置于某章中关**（如 stage_07_03，`school: yinRou`·`isBoss: true`），T2 给其关加 `dropSkillFragmentId`。逐关 `requiredRealm: erLiu`、`prevStageId` 链、`narrative*Id` 指向 T3 文件。

- [ ] **Step 3: reconcile `stages.length` 断言 30→35**

Modify `test/tools/progression_playtest_diagnostic_test.dart:42`：`expect(stages.length, 30);` → `expect(stages.length, 35);`

- [ ] **Step 4: reconcile balance_simulator 关卡范围**

打开 `test/tools/balance_simulator_test.dart`，把 `s.chapterIndex == 6`（line ~416，末章过滤）改为含 Ch7（`s.chapterIndex == 7` 或 `<= 7`，按上下文语义），注释「30 关」口径改 35。若有 `expect(...length, 30)` 同步改 35。

- [ ] **Step 5: 跑 stage 红线测 + count 断言，确认加载不炸**

Run: `flutter test test/data/stage_win_condition_test.dart test/data/mainline_stage_curve_redline_test.dart test/data/stage_skill_drop_redline_test.dart test/tools/progression_playtest_diagnostic_test.dart --no-pub`
Expected: PASS。若报 `stage_07_05 dropSkillManualId` 相关红线 → 属 T2 范围，本步不加该字段。若 `stage_silver_ratio_redline` 硬编码 30 报错 → 同步改 35（`data/stages.yaml` 加关后按现有银两曲线核）。

- [ ] **Step 6: balance 校准二流敌队数值**

Run: `flutter test test/tools/balance_simulator_test.dart --no-pub`
Expected: Ch7 五关通关率落在与 Ch4-6 同带（on-level ~100% / 欠配下降），不进百万红线不破。按输出反复调 stage_07_XX 的 baseHp/Attack，anchor 断魂庄二流 boss。**贴通关率输出**。

- [ ] **Step 7: Commit**

```bash
git add data/stages.yaml test/tools/progression_playtest_diagnostic_test.dart test/tools/balance_simulator_test.dart test/features/economy/stage_silver_ratio_redline_test.dart
git commit -m "加 Ch7 二流五关骨架 + 二流敌队校准 + count 断言 reconcile"
```

---

## Task 2: 两招挂载（千钧坠岳真解 + 烛影摇红残页）+ wave_b 配平复核

**Files:**
- Modify: `data/skills.yaml`（删 2 处 `mount_deferred: true`，line ~2923 千钧坠岳 / ~3046 烛影摇红）
- Modify: `data/stages.yaml`（stage_07_05 加 `dropSkillManualId`；灰衣人关加 `dropSkillFragmentId`）
- Test: `test/data/wave_b_content_redline_test.dart`, `test/data/skill_source_redline_test.dart`, `test/features/cultivation/wave_b_drop_skill_wiring_test.dart`

- [ ] **Step 1: 先跑 wave_b 3 测基线（挂载前·两招仍 deferred）**

Run: `flutter test test/data/wave_b_content_redline_test.dart test/data/skill_source_redline_test.dart test/features/cultivation/wave_b_drop_skill_wiring_test.dart --no-pub`
Expected: PASS（现状 deferred 豁免）。记基线，作对照。

- [ ] **Step 2: stage_07_05 加真解挂载字段**

在 stage_07_05 块顶部（`name` 后，沿 stage_02_05 体例）加：

```yaml
    dropSkillManualId: skill_qian_jun_zhui_yue  # 真解(千钧坠岳·北派重手·同招为 boss chargeSkillId 双用)
```

- [ ] **Step 3: 灰衣人关加残页挂载字段**

在灰衣人所在章中关（T1 Step 2 设定，如 stage_07_03）块顶部加：

```yaml
    dropSkillFragmentId: skill_zhu_ying_yao_hong  # 残页(烛影摇红·灰衣人阴柔本命·重打累加达阈解锁)
```

- [ ] **Step 4: 删 2 招 `mount_deferred`**

`data/skills.yaml`：删 `skill_qian_jun_zhui_yue` 块内 `mount_deferred: true` 整行（连同上方「二流孤儿…」注释可改为「Ch7 北派重手宗匠真解」）；同样删 `skill_zhu_ying_yao_hong` 块内 `mount_deferred: true`（注释改「Ch7 灰衣人残页」）。**删前 Read 精确字节**（半角标点）。

- [ ] **Step 5: 跑 skill_source + game load，验挂载完备（红线⑦）**

Run: `flutter test test/data/skill_source_redline_test.dart --no-pub`
Expected: PASS。红线④（dropSkillManualId→mainlineDrop✓）⑤（dropSkillFragmentId→fragment✓）⑦（每招恰 1 挂载点✓）。若报「skill X 缺挂载」→ 查 Step 2/3 字段拼写。

- [ ] **Step 6: 跑 wave_b 3 测，复核配平 + 更新断言**

Run: `flutter test test/data/wave_b_content_redline_test.dart test/data/skill_source_redline_test.dart test/features/cultivation/wave_b_drop_skill_wiring_test.dart --no-pub`
Expected: 配平测「各流派等量」PASS 不变（千钧坠岳原即刚·真解 2/2/2 成员，烛影摇红原即阴·残页 3/3/3 成员，style 计数零变）。**若** 某测显式断言两招 `mountDeferred==true` 或断言烛影摇红在塔 f15（原设计塔残页，本批改 Ch7 章末重打 stage 残页 = channel 变）→ 更新该断言为现状（stage 残页），断言语义写「阴柔残页 = 3」不写具体挂载位置（沿 `feedback_red_line_test_semantics`）。贴通过输出。

- [ ] **Step 7: Commit**

```bash
git add data/skills.yaml data/stages.yaml test/data/wave_b_content_redline_test.dart test/data/skill_source_redline_test.dart test/features/cultivation/wave_b_drop_skill_wiring_test.dart
git commit -m "挂载千钧坠岳真解 + 烛影摇红残页 + wave_b 配平复核"
```

---

## Task 3: Ch7 叙事文案（章首尾 + 10 段 stage + defeat）

**Files:**
- Create: `data/narratives/chapters/chapter_07.yaml`
- Create: `data/narratives/stages/stage_07_01_opening.yaml` … `stage_07_05_victory.yaml`（10 段 opening/victory）+ `stage_07_04_defeat.yaml` + `stage_07_05_defeat.yaml`
- Modify: `pubspec.yaml`（仅当上述文件落新目录时）
- Test: `test/features/mainline/mainline_narrative_completeness_test.dart`, `test/tools/asset_audit_test.dart`, `test/data/pubspec_asset_declaration_test.dart`

**体例锚**（沿 `project_wuxia_idle_ch4_cultural_arc` + chapter_06.yaml）：
- chapter_07 章首尾 = 第三人称，称「新任掌门 / 大弟子」（**无固定名**），李寒作太祖第三人称。章首承李寒飞升；章末「独当一面」顿悟。
- stage 段 = 第二人称「你」。~4-6k 字总量。
- 遗物 hook：末 Boss / 灰衣人留北派信物（作 Ch8 hook）。
- **Tier 风格词**（二流，取 `feedback_collab_mode_single_lore_workflow`）：青涩/锐进/担当/初立。**黑名单词扫 0 命中**（legendary/epic/神器/传说级/无敌/血溅/刀光剑影…）。

- [ ] **Step 1: 写 chapter_07.yaml（章首尾）**

沿 chapter_06.yaml 结构（`id`/`title`/`prologue`/`epilogue`）。prologue 承飞升+继位心境；epilogue 章末拐点+北派信物 hook。

- [ ] **Step 2: 写 10 段 stage opening/victory + 2 段 defeat**

每 stage 一个 `*_opening.yaml` + `*_victory.yaml`（`id`/`title`/`paragraphs`）；stage_07_04/05 各一 `*_defeat.yaml`。id 严格对应 T1 的 `narrative*Id`。

- [ ] **Step 3: 若落新目录，补 pubspec 声明**

narrative 现有目录（`data/narratives/chapters/`、`data/narratives/stages/`）已在 pubspec；**若沿用则无需改**。仅当新建子目录时在 `pubspec.yaml` `assets:` 下逐个声明（Flutter 目录声明不递归）。

- [ ] **Step 4: 跑叙事完整性 + asset audit**

Run: `flutter test test/features/mainline/mainline_narrative_completeness_test.dart test/tools/asset_audit_test.dart test/data/pubspec_asset_declaration_test.dart --no-pub`
Expected: PASS（Ch7 每关 narrative id 有对应文件，无 placeholder 兜底）。

- [ ] **Step 5: 黑名单词自查**

Run: `grep -rniE "legendary|epic|神器|传说级|无敌|血溅|刀光剑影|史诗|神话" data/narratives/chapters/chapter_07.yaml data/narratives/stages/stage_07_*.yaml`
Expected: 0 命中。

- [ ] **Step 6: Commit**

```bash
git add data/narratives/chapters/chapter_07.yaml data/narratives/stages/stage_07_*.yaml pubspec.yaml
git commit -m "写 Ch7 二流首章叙事文案(章首尾 + 10 段 stage + defeat)"
```

---

## Task 4: 好家伙 tier 掉落 + 北派信物遗物

**Files:**
- Modify: `data/equipment.yaml`（Ch7 dropTable 引用的好家伙装备；不足则新增）
- Create/Modify: `data/lore/<equipment_id>.yaml`（新增装备须配典故，`_validatePresetLoreReferences` 强校验）
- Test: `test/data/*`（equipment/lore 引用红线）, `test/features/loot_preview/loot_data_integrity_test.dart`

- [ ] **Step 1: 盘点现有好家伙装备够不够 Ch7 dropTable**

Run: `grep -nE "tier: haoJiaHuo|haojiahuo" data/equipment.yaml | head -30`
盘点现有好家伙 tier 武器/防具/饰品数量。Ch7 dropTable 优先复用；**不足才新增**（YAGNI）。

- [ ] **Step 2: 若新增装备，配数值 + 典故**

新增装备 `tier: haoJiaHuo`，`attack_power ≤ 2000`（硬红线）；每件必配 `data/lore/<id>.yaml`（缺则 loader 抛错）。北派信物遗物 = 叙事物件（lore 承载），非数值装备。

- [ ] **Step 3: 跑 equipment/lore 红线 + loot 完整性**

Run: `flutter test test/data/ test/features/loot_preview/loot_data_integrity_test.dart --no-pub`
Expected: PASS（equipment↔lore 双向引用自洽，dropTable 引用存在，attack ≤2000）。

- [ ] **Step 4: Commit**

```bash
git add data/equipment.yaml data/lore/
git commit -m "补 Ch7 好家伙 tier 掉落 + 北派信物典故"
```

---

## Task 5: 全量验证 + closeout

**Files:**
- Modify: `PROGRESS.md`（顶段加 Ch7 批·四态）
- Modify: `GDD.md`（若主线章数/二流内容口径需同步）

- [ ] **Step 1: 全仓 analyze**

Run: `flutter analyze --no-pub`
Expected: `No issues found`。

- [ ] **Step 2: 全量测（并发）**

Run: `flutter test --no-pub`
Expected: 全绿。**首个 `-N` 才是真失败**；对照基线 4282，新增 = Ch7 相关测。贴通过/失败数。

- [ ] **Step 3: macOS build 冒烟**

Run: `flutter build macos --debug`
Expected: `✓ Built`（新 asset 引用/errorBuilder 兜底不破构建）。

- [ ] **Step 4: 更新 PROGRESS 顶段（四态：已完成/已验证/已知风险/下批建议）**

写 Ch7 批：已完成（5 关 + 2 招挂载 + 叙事 + 装备）/已验证（analyze 0 + 全量数 + build）/已知风险（美术素材缺走 errorBuilder 待拍 / Ch8-9 后续）/下批建议（Ch8 或塔二流段）。

- [ ] **Step 5: GDD 同步（按需）**

若 GDD 主线章数（Ch1-6）或「唯一二流内容=断魂庄」口径需更新为含 Ch7 → 改，标题加 `[GDD]`。

- [ ] **Step 6: Commit（不 push——push 是用户的活）**

```bash
git add PROGRESS.md GDD.md
git commit -m "Ch7 二流首章批 closeout（全量绿 + 进度四态）"
```

---

## Self-Review（spec 覆盖核对）

- ✅ spec §1 定位主角 → T1（stages requiredRealm erLiu）+ T3（角色化称呼文案）
- ✅ spec §2 叙事弧 → T3（章首尾/顿悟/遗物 hook/风格词/黑名单）
- ✅ spec §3 关卡结构 → T1（5 关骨架 + 二流敌队 + 掉落）
- ✅ spec §4 末 Boss & 两招挂载 → T1（boss chargeSkill）+ T2（dropSkillManualId/dropSkillFragmentId + wave_b 复核）
- ✅ spec §5 红线 → T2（挂载红线④⑤⑥⑦）+ T3（pubspec/asset）+ T4（equipment/lore 红线）
- ✅ spec §6 内容产物验收 → T3（narrative 测）+ T4（loot）+ T5（全量/build）
- ✅ spec §7 非目标 → 计划不含 Ch8-9/塔段/gauntlet 简化
- ✅ 硬编码 count 断言 reconcile（30→35 / chapterIndex）→ T1 Step 3-5（易漏，`feedback_version_bump_test_assert_sync`）

**依赖顺序**：T1 →（T2 ∥ T3 ∥ T4）→ T5。T2/T3/T4 均依赖 T1 的 stage 骨架（关名/boss/narrative id），T1 后可并行。
