# Ch11「中州·名门之虚」实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development 或 superpowers:executing-plans 逐 task 执行。步骤用 `- [ ]` 追踪。

**Goal:** 加一流第二章 Ch11「中州·名门之虚」——5 关 + 末 Boss 真解 + 13 篇叙事 + ~26 reconcile 站点,承 Ch10 止水旧印 hook,文化弧「名门虚实」之「虚」。

**Architecture:** 数据驱动加章（stages/skills yaml + narratives）+ 全站点 reconcile。敌招/装备零新增复用一流 menpai/liQi,唯一新增=末 Boss 真解 1 招。境界 requiredRealm yiLiu·章内层 shuLian→yuanShu。

**Tech Stack:** Flutter/Dart · Isar · yaml 数据 · flutter test（reconcile 守卫）。基线：main 7793cf1c（Ch10+kimi 合入）·worktree base 同。

**执行前置（fresh worktree 预热·首个 task 前必做）：** `flutter pub get` → `cp <主仓>/libisar.dylib .` → `dart run build_runner build`（否则测试编译失败·见 memory `feedback_subagent_driven_fresh_worktree_env_prep`）。

---

## Phase 1：数据层（stages + 真解）

### Task 1.1：stages.yaml +5 关（stage_11_01..05）

**Files:** Modify `data/stages.yaml`（在 Ch10 stage_10_05 段之后追加）

- [ ] **Step 1** 照 `stage_10_01..05` 结构写 5 关。每关字段：`id: stage_11_0N`·`requiredRealm: yiLiu`·`prevStageId`（11_01 指向 stage_10_05·其余单链）·`enemyTeam`（敌复用 `skill_(gangmeng|lingqiao|yinrou)_menpai_(basic|skill|ult)` 及 fang/nei 变体·`realmLayer` 按梯度 shuLian/shuLian/jingTong/jingTong/yuanShu·`iconPath: assets/enemies/zhongzhou_*.png` 走 errorBuilder 兜底待出图）。流派：11_01 lingQiao / 11_02 gangMeng / 11_03 yinRou / 11_04 混 / 11_05 gangMeng。
- [ ] **Step 2** Boss 位 {4,5}：11_04 `isBossStage: true` 章中 Boss（stat 门槛·**无 bossPhases**·照嵩阳关主 stage_10_04）；11_05 `isBossStage: true` 末 Boss（`chargeSkillId: skill_<真解id>`·`bossPhases` 两相位 1.0/0.5 aggressive `onEnterMechanic: chargeCounter` `titleKey: bossPhase_desperate`·照守拙翁 stage_10_05）。11_03 非 boss 保有敌队。
- [ ] **Step 3** dropTable：Boss 关掉 liQi 装备（复用现有 weapon_liqi_*·照 Ch10）；11_05 首通掉真解（`source: mainline_drop` 在 skill 里）。
- [ ] **Step 4** 敌 stat（baseHp/Attack/Speed）照 Ch10 同 realmLayer 敌就近取值（守拙翁 yuanShu 参考 hp~34000/atk~1000·章中 Boss jingTong 参考嵩阳关主）。**禁超硬红线**（装备攻击≤2000·Boss hp 60000+ 不进 1M）。
- [ ] **Step 5** 运行 `flutter test --no-pub test/data/game_repository_test.dart` — 预期 FAIL（count/prevStageId 红线未同步·Phase 3 修）。这是预期的红,先落数据。

### Task 1.2：skills.yaml +1 末 Boss 真解

**Files:** Modify `data/skills.yaml`

- [ ] **Step 1** 照 `skill_zhi_shui_jue`/`skill_chen_sha_yi_jue` 加 `skill_<中州名门真解id>`：`name`（中州名门刚猛华丽绝学·如「XX剑法·某式」）·`description`（华而不实意象·文案体例）·`type: powerSkill`·`targetType: single`·`powerMultiplier: 3600`（守 ≤8000）·`qiDelta: -30`·`cooldownTurns: 4`·`style: gangMeng`·`tier: 4`·`source: mainline_drop`·`chargeSkill`/`dropSkillManual` 双用 canon·`proficiency` 真解手工高半档（照沉沙一诀）。
- [ ] **Step 2** 回填 stage_11_05 的 `chargeSkillId` + 末 Boss `skillIds` 含此真解（gangMeng menpai basic/skill + 真解）。
- [ ] **Step 3** `flutter test --no-pub test/data/skill_qi_redline_test.dart test/data/skill_count_contract_test.dart` — 预期 FAIL（count 210→211 未同步·Phase 3.2 修）。

### Task 1.3：真解白名单登记

**Files:** Modify `test/data/wave_b_content_redline_test.dart`

- [ ] **Step 1** 在 `standaloneBossManualIds` 白名单加 `skill_<真解id>`（注释「Ch11 末 Boss 独立真解·wave_b 配平排除」）。
- [ ] **Step 2** `flutter test --no-pub test/data/wave_b_content_redline_test.dart` — 预期 PASS（配平 2/2/2 不破）。

---

## Phase 2：生产可见性（否则章不可达/不显示）

### Task 2.1：chapter_list 章列表

**Files:** Modify `lib/features/mainline/presentation/chapter_list_screen.dart`

- [ ] **Step 1** `:30` `_chapters = [1..10]` → `[1, 2, ..., 11]`；`:19` 注释加「中州名门」为 Ch11 名（拟定章名，实装定）。
- [ ] **Step 2** `flutter test --no-pub test/features/mainline/presentation/chapter_list_screen_test.dart` — 章卡计数 10→11（widget 测 viewport 若不足扩容 setSurfaceSize）。

### Task 2.2：strings 章数（顺修 stale drift）

**Files:** Modify `lib/shared/strings.dart`

- [ ] **Step 1** `:1367` `mainMenuMainlineHint = '8 章 40 关…'` → `'11 章 55 关,按章节顺序解锁'`（**当前 stale·Ch8 后漏更新·Ch11 一并订正到真值**）。
- [ ] **Step 2** grep `UiStrings` 的 `chapterTitle`/`chapterHint` switch（若有 per-章 case）补 Ch11 case。

### Task 2.3：main_menu / status_summary 章循环

**Files:** Modify `lib/features/main_menu/application/main_menu_status_summary_provider.dart`、`lib/features/main_menu/presentation/main_menu.dart`

- [ ] **Step 1** grep `<= 10`/`10`/章循环上界 → 11（照 Ch10 加 11 时的改动点）。
- [ ] **Step 2** `boss_memory_key` group index：grep 新章 chNum 与心魔/轻功/群战偏移（**持久化字段不重排旧值**·memory 警告）。

---

## Phase 3：reconcile 测试站点

### Task 3.1：count 50→55

**Files:** `test/data/game_repository_test.dart`（`:82` mainlineCount 50→55 + reason 文字更新「11 章 × 5 关」·`:671` 主线红线行同步）、`test/features/mainline/mainline_narrative_completeness_test.dart`（count + 章循环 1→11）、`test/tools/output/progression_attribute_playtest_2026-07-13.csv`（**byte-lock**·`UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生）、`test/tools/progression_playtest_diagnostic_test.dart`、`test/data/mainline_stage_curve_redline_test.dart`、readable_tempo 测。

- [ ] **Step 1** 逐文件改 count 50→55·跑单文件确认（`flutter test --no-pub <file>`）。
- [ ] **Step 2** readable_tempo 终章：grep `stage_10_05` 在 tempo 测 → `stage_11_05`（既有 drift 高发·Ch8 加时漏更新过）。

### Task 3.2：skill 210→211（命中 3 处）

**Files:** `test/data/skill_count_contract_test.dart`（`:28` `hasLength(210)`→211 + 交叉核对 GDD「N 招」字串）、`test/data/game_repository_test.dart`（skillDefs 总池 hasLength）、`test/data/skill_qi_redline_test.dart`（skillDefs hasLength）。

- [ ] **Step 1** 三处 210→211·跑三文件确认全绿。

### Task 3.3：catalog 35→37

**Files:** `test/features/battle_record/application/boss_memory_providers_test.dart`（`:50` `hasLength(35)`→37·reason「主线 isBossStage 31 + 塔 6」·主线 29→31 因 Ch11 +2 boss 关）。

- [ ] **Step 1** 改·跑确认。

### Task 3.4：progression Lv 逐值实测（**禁猜·fail-fast 迭代**）

**Files:** `test/features/cultivation/application/progression_release_budget_test.dart`（`:22` 首通 Lv69/cumExp1289·`:52/99` 全内容 Lv98·`:75/84` displayLevel 91/92）、`test/tools/progression_idle_horizon_simulation_test.dart`（同口径缺口/里程碑）。

- [ ] **Step 1** 跑测·读 fail-fast 报的首个错值·改成实测值·再跑·迭代到绿（守 memory `reference_anti_hallucination`·禁转抄猜值·守终态 < Lv100）。
- [ ] **Step 2** idle_horizon 同口径重校（缺口/里程碑 exp 多锚全位移）。

### Task 3.5：material / tier

**Files:** `test/tools/enhancement_material_supply_test.dart`（结晶掉落 +Ch11 关·守「不足 3 件」软线·放宽记 PR）、`test/data/mainline_stage_curve_redline_test.dart`（Ch11→境界映射·**cap-agnostic** 按 requiredRealm.index·不硬编快照）。

- [ ] **Step 1** 改·跑确认。

---

## Phase 4：叙事 + GDD

### Task 4.1：叙事 13 篇

**Files:** Create `data/narratives/chapters/chapter_11.yaml` + `data/narratives/stages/stage_11_0N_{opening,victory}.yaml`（×10）+ `stage_11_04_defeat.yaml`、`stage_11_05_defeat.yaml`

- [ ] **Step 1** 照 Ch10 体例写：章首（入中州名门世界·带凉铜符+止水印）+ 章尾（看透名门之虚·承 Ch12 求「实」hook·呼应守拙翁「江湖走到哪一步」）+ 10 段 stage（每关 opening/victory 扣「虚」主题）+ 2 defeat。母题「名≠本事」·守拙翁「守」vs 名门「虚」。字数参考 Ch10（~6500 字）。
- [ ] **Step 2** grep 守则：黑名单词 + 现代词 + 网文腔 **0 命中**（照 Ch10 收尾 grep 清单·用 `wuxia-content` skill 体例）。
- [ ] **Step 3** `flutter test --no-pub test/features/mainline/mainline_narrative_completeness_test.dart` — PASS（13 篇齐·章循环含 11）。

### Task 4.2：GDD §8.1 同步

**Files:** Modify `GDD.md`（§8.1 章表 +Ch11 行·招式池 210→211·发布边界不变仍一流 24）

- [ ] **Step 1** 加 Ch11 章表行·招式池数同步·与 skill_count_contract 的 GDD 字串核对一致。

---

## Phase 5：批末验证

- [ ] **Step 1** `flutter analyze` — 0 issue。
- [ ] **Step 2** `flutter test --no-pub`（全量·默认并发）— 全绿（基线 4586+5关+新测·多处旁支 fail-fast 单测测不出·**必全量**·memory reconcile 条）。
- [ ] **Step 3** 破坏证红：真解 `powerMultiplier` 临改 9000（>8000）→ 跑 `skill_qi_redline`/encounter 红线 EXPECT FAIL EXIT=1 → 还原 3600 → 复绿（**commit 后做**·memory `feedback_break_red_after_commit`）。
- [ ] **Step 4** commit（分批·每 Phase 一 commit·tip [READY]）。

---

## Reconcile 站点总账（Phase 0 grep 实证 + memory ~26 站点）

count(6+)·skill(3)·catalog(1)·chapter_list·strings(含 stale 顺修)·main_menu·boss_memory_key·progression Lv(2 文件逐值)·tier·material·readable_tempo 终章·narrative count·GDD——批末全量兜底旁支 fail-fast 测不出的漏网（Ch9 实证批末逮 5 处）。
