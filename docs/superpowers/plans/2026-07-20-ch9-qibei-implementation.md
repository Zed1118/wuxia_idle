# Ch9「碛北」二流第 3 章 实装 Implementation Plan

> **For agentic workers:** 内容+红线敏感 coupled 批,Claude 主 checkout(worktree)直做,**不派 subagent fan-out**(多站点改共享文件·红线敏感)。立绘走 codex image_gen 并行。

**Goal:** 加主线第 9 章「碛北」(A 案二流收束),5 关 stage_09_01..05,整章一次做完 ~21 reconcile 站点,边塞三章弧(北望/出塞/碛北)闭环,不抬发布上限。

**Architecture:** 沿 Ch8 模板。stages.yaml +5 关(erLiu·Boss 位 {4,5}·单链 prevStageId);叙事 chapter_09 + 10 段 stage + 2 defeat;末 Boss「那一位」= 隐世二流绝顶老者/铜符本主(沉默出手即决·+1 本命真解首通掉+chargeCounter)。生产可见性 4 处章循环边界 + strings 5 处;测试 reconcile 硬编 40→45 / 8→9 / boss 18→20 / catalog 31→33;Lv 快照逐值实测。

**Tech Stack:** Flutter/Dart · Isar · Riverpod codegen · YAML 数值+文案 · flutter test。

**分支:** worktree-ch9-qibei(基 origin/main fef46dce)
**Spec(冻结):** docs/spec/2026-07-20-ch9-qibei-design.md(A 案)

---

## 内容 beats(A 案)

| 关 | 名(暂) | biome | 敌(流派) | Boss | 叙事锚 |
|---|---|---|---|---|---|
| 09_01 | 符引出关 | frontier | 碛北边民/关卡马匪(刚猛) | — | 循符出受降城以北,最后一段有路的路 |
| 09_02 | 瀚海无路 | desert | 瀚海沙盗(灵巧) | — | 真正无路之地,风蚀白骨,符是唯一方向 |
| 09_03 | 蜃楼(章中考验) | desert | 蜃楼幻敌(阴柔·非boss) | — | 海市蜃楼幻境·灰衣人同行点拨·"不追"母题镜像 |
| 09_04 | 黑水绝壁 | frontier | 隘口守卫(刚猛) | **章中 Boss**+defeat | 碛北最深隘口·那一位门槛守卫 |
| 09_05 | 那一位 | frontier | 那一位(末Boss) | **章末 Boss**+defeat+真解 | 符尽头·二流绝顶老者/铜符本主·沉默出手即决 |

- 章首心境「不怕没有路」(承 Ch8 尾);章末拐点「符的那头不是答案,是又一个开始」。
- 铜符物理遗物 hook 贯穿;师父遗言/顿悟回响 3 处;黑名单 14 词 grep 0。
- **末 Boss 真解(默认加·待用户可否决)**:那一位本命 tier3 二流真解,`dropSkillManualId` 首通掉 + 同招 `chargeSkillId` 双用 + bossPhase chargeCounter。

## Reconcile 站点清单(Phase 0 实测 · 现值→新值)

**生产(5 类):**
- [ ] stages.yaml: +stage_09_01..05
- [ ] strings.dart:1379 副标题 八→九章
- [ ] strings.dart +chapter9Title「第九章 · 碛北」+chapter9Hint
- [ ] strings.dart chapterTitle/Hint switch +`9 =>`
- [ ] main_menu.dart:673,691 `<=8→<=9`;main_menu_status_summary_provider.dart:156 `<=8→<=9`
- [ ] chapter_list_screen.dart:30 `_chapters +9` + :19 注释
- [ ] (skills.yaml +1 真解 · 若加)

**Cap-agnostic 自动(无需改·仅验绿):** boss_memory_key(chNum+3→Ch9=12) / progression_red_lines_validator(派生 maxCh) / mainline_stage_curve tier(Ch7+→erLiu)

**测试 reconcile:**
- [ ] progression_playtest_diagnostic_test.dart:16 `40→45` + 重生 CSV(`UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1`)
- [ ] mainline_narrative_completeness_test.dart:58 `40→45` +:66 章循环 `i<=8→9`
- [ ] game_repository_test.dart mainlineCount `40→45` + 循环 [1..9] + bossIdxByChapter `9:{4,5}`(:80/:676/:677/:684/:694) (+ skill 248→249 若加真解 :55)
- [ ] stages_boss_enemy_test.dart:41 boss `18→20`
- [ ] boss_memory_providers_test.dart:50 `31→33` :68 `25→27`
- [ ] progression_release_budget_test.dart Lv 快照**逐值实测**(:47 843→? :49 57→? :64 1750→? :65 79→? :74-99 84/86/91 级联·守<100)
- [ ] balance_simulator_test.dart:63,72 cosmetic 40→45
- [ ] readable_first_clear_tempo_diagnostic_test.dart:91 `<=8→9` + :110 终章 `stage_07_05→stage_09_05`(既有 drift 一并订正)
- [ ] chapter_list_screen_test.dart:107 锁 `6→7` :110 `40→45`/[1..9]/findsNWidgets `8→9`(viewport 或需扩)
- [ ] (可选)boss_memory_key_test.dart +Ch9→12 测例

**叙事(~5.5k 字):** chapter_09.yaml(卷首尾)+ stage_09_01..05_{opening,victory} + 09_04/09_05_defeat
**GDD:** §8.1 章表 +Ch9(+招式池若加真解)
**立绘(codex 并行):** 5-6 新敌 image_gen + iconPath + 透明注册 + 脚底 fraction 校准

## Phase 切分(6 phase · commit 粒度)

1. **P1 spec/GDD**:spec 已冻结;GDD §8.1 章表 + route subtitle 同步。
2. **P2.1 stages+数值+红线层**:stages.yaml +5 关 + (skills.yaml 真解) + 全测试 reconcile 硬编改;跑 targeted 红绿。
3. **P2.3① 10 段 stage narrative** ~4k 字。
4. **P2.3② 章首尾 + 2 defeat** ~1.5k 字;narrative completeness 转绿。
5. **P2.4 生产可见性 reconcile**:strings/main_menu/chapter_list/status_summary + widget 测。
6. **P2.5 R5 压测 + Lv 快照实测 + CSV 重生 + closeout**:progression/balance/tempo 逐值实测回填 + 批末全量 + PROGRESS/BACKLOG。
- 并行:codex image_gen Ch9 立绘(派单书显式写死禁区 PROGRESS/BACKLOG/NEXT)。

## 验收标准(§8.2 Gate)
- analyze 0;批末全量 `flutter test --no-pub` 全绿(增 ~15+ 用例:5 关×3 progression + boss + narrative)。
- 硬红线:敌 HP≤60000/攻≤2000;真解 mult≤8000;erLiu 不越发布上限;Lv 快照 <解锁线 Lv100。
- 黑名单 14 词 grep 0;无中文散写进 Dart(走 narratives/strings);Boss 关 defeat⟹isBoss。
- Lv 快照、exp、boss 计数、catalog 数**逐值实测禁猜**。

## 当前恢复点
- **状态:** P2.1-2.5 全落地。stages/skills/13 叙事/~21 reconcile/GDD §8.1/allowlist 全改;Lv 快照实测(首通 Lv63/全内容 Lv94<100)。commit bddd5603(P2.1/2.4)+48a29d31(P2.3)+P2.5 待提交。批末全量运行中。
- **下一步:** 全量绿→commit P2.5+PROGRESS/BACKLOG→push→draft PR;codex 出 Ch9 立绘(follow-up·11 图 allowlist 兜底)。
- **已跑验证:** analyze 0;targeted 全绿(game_repo/boss_enemy/图鉴/tier曲线/chapter_list/tempo/narrative/progression_budget/playtest CSV);那一位 avgHpEndRatio 0.9394 命中 §6 血线带。
- **阻塞:** 无(末 Boss 真解按 Ch7/8 先例默认加,用户可否决)。
