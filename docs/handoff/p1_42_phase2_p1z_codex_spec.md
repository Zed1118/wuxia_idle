# P1 #42 Phase 2 · §10 P1.z 江湖见闻录·机制百科 spec

> 2026-05-18,Mac + Opus 4.7 xhigh 起草。GDD §10.2 第 3 方式「江湖见闻录百科(永久可查):每条 200-500 字,详细机制说明」首批 8 条机制条目落地。**配合 P1.x(强制引导)+ P1.y(气泡提示)收口 §10 三种引导方式全闭环**。

## 0. 必读清单(开工前)

1. **本 spec**(本文)
2. **GDD §10 完整段**(line 540-595):8 档解锁节奏 + 3 种引导方式 + 设计哲学
3. **既存 P1.x closeout** `p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md`(强制引导落地体例)
4. **既存 P1.y closeout** `p1_42_phase2_p1y_bubble_hint_closeout_2026-05-18.md`(气泡提示落地体例)
5. **既存 BaikeScreen** `lib/features/baike/presentation/baike_screen.dart`(2 tab,DefaultTabController 体例)
6. **既存 lore yaml 体例** `data/lore/accessory_baowu_yu_long_pei.yaml`(`id + default_lore: [{text}]`)
7. **既存 NarrativeLoader** `lib/data/narrative_loader.dart`(yaml 加载体例)
8. memory `feedback_phase0_grep_two_axes` / `feedback_model_selection` / `feedback_opus_xhigh_interactive_duration`

## 1. 任务一句话

新建 `data/codex/` 目录承载 8 条机制百科条目(对应 §10.1 8 档解锁节奏,每条 200-500 字),Mac 端落数据/领域/Application/UI 层 + BaikeScreen 从 2 tab → 3 tab(加「机制」),未达 tutorialStep 的条目灰显占位「待解锁」;文案 DeepSeek 端走 P3 派单。

## 2. Phase 0 Reality Check(已落)

| # | 摸底项 | 现状 |
|---|---|---|
| 1 | BaikeScreen 文件 | `lib/features/baike/presentation/baike_screen.dart` 229 行,2 tab(见闻 GameEvent + 典故装备占位)|
| 2 | data/ baike yaml | **0 命中** ⚠️ P1.z 0→1 全新落地 |
| 3 | GDD §10.2 第 3 方式 | line 555:「永久可查,每条 200-500 字,详细机制说明」 |
| 4 | §10.1 8 档机制锚定 | 战斗+境界+掉落 / 强化+共鸣 / 心法 / 流派 / 闭关 / 师徒 / 奇遇+领悟 / 开锋+结晶+相生 |
| 5 | MainMenu 入口 | 已接 BaikeScreen 按钮(永久可见无灰显),`UiStrings.mainMenuBaike`「江湖见闻录」 |
| 6 | shared/strings baike | 4 const + 2 空态(`baikeScreenTitle/baikeTabFeed/baikeTabLore/baikeFeedEmpty/baikeLoreEmpty`)|
| 7 | yaml 体例参考 | `data/lore/<id>.yaml`:`id + name + default_lore: [{text}]`;`data/events/<id>.yaml`:`id + title + opening + choices` |
| 8 | TutorialService API | `getCurrentStep()` 返回 0-8 已 cover §10.1 8 档,可直接用于解锁判定 |

## 3. Q1-Q6 拍板(2026-05-18)

| # | 问题 | 拍板 | 理由 |
|---|---|---|---|
| Q1 | yaml 载体目录 | `data/codex/`(顶层独立目录)| 与 narratives/lore/events 三大文案目录并列;语义独立(codex=百科);避免污染 narratives 语义 |
| Q2 | BaikeScreen UI 架构 | 加第 3 tab「机制」 | 沿 DefaultTabController 体例改动量最小;与 GDD §10.2 江湖见闻录百科主语一致 |
| Q3 | 解锁触发 + UI 状态 | 永久可见 + 未达 step 灰显占位 | 对齐 §10.2 永久可查 + §10.4 未解锁灰显双约束;玩家能看到「还有 X 条待解锁」激励 |
| Q4 | P1.z 范围拆 | **最小:8 条 × 1**(8 档 × 1 条) | 收口 §10 第 3 方式最小动作;DeepSeek 工作量 3-5h 可控;5.2 扩段留 P2 滚动 |
| Q5 | yaml schema 字段 | 见 §4 | — |
| Q6 | 详情查看交互 | 点击条目 push detail screen / 整段文案 + AppBar 返回 | 列表只显 title + step + 锁/已解锁 chip;详情 screen 沿 NarrativeReaderScreen 体例(无 mandatory 字段)|

## 4. yaml schema 设计

```yaml
# data/codex/codex_combat_basics.yaml(范例,DeepSeek 写)
id: codex_combat_basics          # 必填,与文件名(不含 .yaml)一致;snake_case
step: 1                          # 必填,1-8,对应 GDD §10.1 8 档解锁节奏
title: 战斗与境界                # 必填,UI 列表 + 详情 AppBar
category: combat                 # 必填,枚举之一(见下表)
paragraphs:                      # 必填 list[2-5 段],每段 50-150 字,总 200-500 字
  - 江湖路远,初出茅庐总要先学如何挥剑。每一招都从手腕发力,
    从腰胯送劲,最后落在剑尖。胜了便有所得——或是一件趁手的兵器,
    或是一段未曾领会过的招法。
  - 境界是身上功夫的厚薄。学徒、三流、二流、一流、绝顶、宗师、武圣,
    七阶七层四十九级,每阶都得一招一式地走过去。
    不存在跳级,也不存在速成。
  - 你背上那柄剑会越用越重——不是剑重,是手底见过的事多了。

# CodexCategory enum(8 个,对应 §10.1 8 档)
# combat        档 1:战斗 + 境界 + 装备掉落
# enhancement   档 2:装备强化 + 装备共鸣
# techniques    档 3:心法系统
# schoolCounter 档 4:三流派克制
# seclusion     档 5:闭关 + 时间锚点
# lineage       档 6:师徒系统
# encounter     档 7:奇遇 + 武学领悟 + 辅修心法
# advanced      档 8:开锋 + 心血结晶 + 心法相生
```

**8 条 yaml 锚点**(DeepSeek P3 派单填写):

| step | id | title | category | 机制内容 |
|---|---|---|---|---|
| 1 | codex_combat_basics | 战斗与境界 | combat | 3v3 自动战斗 + 7 阶 49 级 + 装备掉落规则 |
| 2 | codex_equipment_enhancement | 装备强化与共鸣 | enhancement | 强化 +20-49 成功率 + 心血结晶 + 共鸣度被动 |
| 3 | codex_techniques | 心法主修 | techniques | 主修 / 辅修 + 修炼度 9 层 + 散功代价 |
| 4 | codex_school_counter | 三流派相克 | schoolCounter | 刚猛/灵巧/阴柔克制环(0.75/1.0/1.25)|
| 5 | codex_seclusion | 闭关与时间锚点 | seclusion | 5 地图 + 子时正午节气 + 在线=离线 |
| 6 | codex_lineage | 师徒传承 | lineage | 收徒 + 师承遗物 + 飞升机制 |
| 7 | codex_encounter | 奇遇与武学领悟 | encounter | 触发条件 + fortune 属性 + 招式池 |
| 8 | codex_advanced | 开锋·结晶·相生 | advanced | 装备开锋 3 槽 + 心血结晶 + 心法相生 5 组合 |

## 5. Phase 拆解

### Phase 1: 数据层 + 领域层(~30min,Mac 端)

| 文件 | 改动 |
|---|---|
| `lib/features/codex/domain/codex_category.dart` | **新建** `CodexCategory` enum 8 值 + `byStep(int) → CodexCategory` 映射 |
| `lib/features/codex/domain/codex_entry.dart` | **新建** `CodexEntry`(id/step/title/category/paragraphs)+ `fromYaml(Map)` |
| `lib/data/codex_loader.dart` | **新建** `CodexLoader.loadAll() → Future<List<CodexEntry>>` 扫 `data/codex/*.yaml`,沿 NarrativeLoader 体例 |
| `lib/data/game_repository.dart` | 加 `Map<String, CodexEntry> codexEntries = {}` 字段 + `_loadCodex()` + 红线校验(8 条 / id 唯一 / step ∈ [1,8] 唯一 / paragraphs 总字数 [200,500])|
| `pubspec.yaml` | assets 段加 `- data/codex/`(若 narratives/lore/events 已有 wildcard 则无需)|
| **test +8 case** | codex_entry_test +3(fromYaml 全字段 / 缺 id 抛 / paragraphs 空抛)/ codex_loader_test +2(8 yaml 扫齐 / fixture override)/ game_repository_test +3(红线 8 条 / step 唯一 / 字数范围)|

### Phase 2: Application 层 + UI 层(~50min,Mac 端)

| 文件 | 改动 |
|---|---|
| `lib/features/codex/application/codex_providers.dart` | **新建** `codexEntriesProvider`(全 8 条)+ `unlockedCodexEntriesProvider`(watch `currentTutorialStepProvider` → 过滤 step ≤ tutorialStep)|
| `lib/features/codex/presentation/codex_tab.dart` | **新建** 第 3 tab 内容:`ListView.builder` 渲染 8 条 / 未达 step 灰显 + 锁图标 + 「待解锁」文案 / 已解锁条目 InkWell push detail |
| `lib/features/codex/presentation/codex_entry_detail.dart` | **新建** detail screen:`AppBar + 整段 paragraphs 渲染`,沿 NarrativeReaderScreen 文字风格 |
| `lib/features/baike/presentation/baike_screen.dart` | 2 tab → 3 tab:`DefaultTabController(length: 3)` + TabBar 加 `Tab(text: UiStrings.baikeTabCodex)` + TabBarView 加 `_CodexTab()` |
| `lib/shared/strings.dart` | +3 const:`baikeTabCodex='机制'` / `codexLockedHint='待解锁'` / `codexEntryReadTime(int min)=阅读约 X 分钟`(可选)|
| **test +10-12 case** | codex_providers_test +3(全 8 / step=0 解锁 0 / step=5 解锁 5)/ codex_tab_test +5(全锁 / 部分解锁 + 灰显 / 全解锁 / 点击 push detail / 锁图标存在)/ codex_entry_detail_test +2(title 渲染 / paragraphs 段数渲染)/ baike_screen_test +1 case 改 length 2→3 + Tab 文案 +1 case 渲染机制 tab |

### Phase 3: DeepSeek 派单 spec(~15min,Mac 端起草)

| 文件 | 改动 |
|---|---|
| `docs/handoff/deepseek_p1_42_phase2_p1z_codex_dispatch_2026-05-18.md` | **新建** 派单 spec(必读清单 / 任务一句话 / 8 yaml 锚点表 / 文学体例红线 / 自审清单 / 范围拆解 / 反例)|

### Phase 4: 收口(~15min,Mac 端)

| 改动 |
|---|
| Mac 端跑 flutter test + analyze 验证 1057 → ~1075-1080 + 0 issues |
| commit + push |
| closeout `docs/handoff/p1_42_phase2_p1z_codex_closeout_2026-05-18.md` 起草 |
| PROGRESS 顶段销账 + 挂账 #42 收口 §10 三种方式完整 |

## 6. 测试增量预估

| Phase | 文件 | 新增 case |
|---|---|---|
| 1 | codex_entry_test | +3 |
| 1 | codex_loader_test | +2 |
| 1 | game_repository_test | +3 |
| 2 | codex_providers_test | +3 |
| 2 | codex_tab_test | +5 |
| 2 | codex_entry_detail_test | +2 |
| 2 | baike_screen_test | +2 改 1 |
| **合计** | — | **+20** |

baseline 1057 → 预估 1077 pass + 1 skip。

## 7. 验收红线 R1-R12

| # | 红线 | 实测点 |
|---|---|---|
| R1 | 8 yaml 全部存在 | game_repository_test 红线校验 8 条 |
| R2 | step ∈ [1,8] 唯一 | game_repository_test step 唯一性 |
| R3 | paragraphs 总字数 ∈ [200,500] | codex_entry_test fromYaml 范围验证 |
| R4 | id 与文件名一致 | codex_loader_test 一致性 |
| R5 | category 与 step 映射一致 | codex_entry_test byStep 验证 |
| R6 | 未达 step 灰显 + 锁图标 | codex_tab_test 锁状态 5 case |
| R7 | 已解锁条目可 push detail | codex_tab_test 点击导航 |
| R8 | provider 不返回 closure 持 ref | codexEntriesProvider 顶级函数(memory `feedback_riverpod_closure_ref_disposed`)|
| R9 | 0 中文 literal | grep codex_tab.dart / codex_entry_detail.dart 0 中文 |
| R10 | 1057 pass + 0 issues 不退步 | flutter test + analyze |
| R11 | BaikeScreen 3 tab AppBar / TabBar 渲染正确 | baike_screen_test 长度 3 |
| R12 | MainMenu 永久可见(无解锁条件)| 既存 main_menu_test 0 改动 |

## 8. 风险与处置

| 风险 | 处置 |
|---|---|
| R1: codex_entry 段落字数 200-500 校验严格化导致 DeepSeek 频繁返工 | 校验改 warn 不 fail;红线 test 用 `lessThanOrEqualTo(550)` + `greaterThanOrEqualTo(180)` 留 10% 弹性 |
| R2: BaikeScreen 3 tab 在低分辨率宽度截断 | TabBar 默认 isScrollable=false,3 tab 文案各 2 字,1280×800 实测无截断 |
| R3: tutorialStep=0(新玩家)8 条全锁 → 玩家进 BaikeScreen 看不到任何条目 | 永久可见 8 条「待解锁」占位条目可见,激励玩家推进 §10.1 解锁;Q3 已拍板 |
| R4: Phase 5 收徒 Phase 6 触发后 step 不递增的旧存档 | TutorialService 已落 advanceForXxx 4 method,本批 0 schema bump 兼容现有存档 |

## 9. 估时

| Phase | 时长(opus xhigh 同会话 vs spec sonnet baseline)|
|---|---|
| Phase 1 数据/领域 | ~30min vs sonnet 60-90min |
| Phase 2 Application/UI | ~50min vs sonnet 90-120min |
| Phase 3 DeepSeek 派单 spec | ~15min vs sonnet 30min |
| Phase 4 收口 | ~15min vs sonnet 30min |
| **Mac 端合计** | **~1h50min** vs sonnet baseline 3.5-5h |
| DeepSeek 端 P3 文案 | 3-5h(8 yaml × 200-500 字)|

memory `feedback_opus_xhigh_interactive_duration` 锚点:本批预估 opus xhigh 实测 1h30min-2h(快 2-3×)。

## 10. 硬约束沿用

- GDD §5.4 数值红线(本批 0 数值改动)
- 不硬编码数值 / 中文文案 / test 断言不写死具体数字
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md
- Riverpod provider 不返回 closure 持 ref
- service 多 caller inline `new XxxService(isar)` 体例(本批 0 service,纯 loader)
- Phase 0 reality check 已落,Q1-Q6 拍板齐
- closeout 数字必 grep 实测
- 复杂任务开工前升档 opus xhigh(已升)
- spec 时长按 sonnet baseline 给

## 11. 反例(开工前自检)

- ❌ data/codex/ yaml 文案中出现具体数值(违反 CLAUDE.md §5.6)
- ❌ codex_tab.dart 写中文 literal(走 UiStrings)
- ❌ provider 返回 closure 持 ref(memory `feedback_riverpod_closure_ref_disposed`)
- ❌ 8 条用 Dart const 写死(200-500 字 × 8 条 = 2400 字以上,违反 §5.6)
- ❌ 未达 step 条目直接 invisible(违反 Q3 灰显+占位拍板)
- ❌ BaikeScreen Tab 不一致(2 tab → 3 tab 必须改 length + TabBar + TabBarView 同步)
- ❌ DeepSeek 端文案出现招式名 / 网游词 / 大场面(沿 W18-A3 lore 派单纪律)
- ❌ Phase 1 不跑 build_runner 就动 codex_entry domain(若用 @riverpod 注解需 build_runner)

---

## 12. 方案 B 调整(2026-05-18 Phase 0 reality check #2)

**Phase 0 漏看发现**:`data/narratives/codex/` 已存 18 md 文件(2026-05-10 早期 Phase 1 落,assets 段已注册),字数 317-543 字完美对齐 §10.2「200-500 字」范围,**7/8 档现成内容已有**,Phase 3 DeepSeek 工作量从 3-5h 砍到 30min。

### 12.1 18 md → §10.1 8 档映射

| step | md(复用) | 字数 | 内容定位 |
|---|---|---|---|
| 1 战斗+境界+掉落 | `realm.md`(境界)| 317 | 7 阶 49 级 + 进阶节奏 |
| 2 强化+共鸣 | `strengthening.md`(强化与磨剑石)| 329 | **Q5b 二选一**(或合并)|
| 2 强化+共鸣 | `resonance.md`(共鸣度·人剑合一)| 423 | 同上 |
| 3 心法 | `techniques_and_styles.md`(心法与流派)| 371 | 主修+辅修+流派概览 |
| 4 三流派 | `three_styles_detail.md`(三流派详解)| 543 | 刚猛/灵巧/阴柔克制环(略超 500 字 OK)|
| 5 闭关 | `retreat.md`(闭关与时辰)| 426 | 时辰+地点+节气 |
| 6 师徒 | `master_disciple.md`(师徒传承)| 337 | 收徒+师承遗物+传承哲学 |
| 7 奇遇+领悟 | `encounter_system.md`(奇遇与机缘)| 396 | fortune 属性+触发条件+招式池 |
| 8 开锋+结晶+相生 | **缺**,DeepSeek 补 1 篇(`combat_advanced.md` 或类似 id)| — | 开锋 3 槽 + 心血结晶 + 心法相生 5 组合 |

**扩展条目**(P2 滚动):equipment_tiers / weapon_forging / battle_taboos / famous_battles / hidden_weapons / jianghu_medicine / jianghu_ranks / jianghu_rules / lost_techniques / major_sects(共 10 篇)— 江湖背景文,不绑 §10.1 8 档,P1.z 不收录。

### 12.2 spec 方案 B 改动撤销/调整

| 原 spec 条目 | 方案 B 调整 |
|---|---|
| Q1 yaml 载体目录 `data/codex/` | **撤销**,复用 `data/narratives/codex/`(已有 18 md,DeepSeek 领地)|
| §4 yaml schema 设计 | **撤销**,内容载体保持 .md(首行 `# 标题` + 段落空行切分,沿 NarrativeLoader md 体例) |
| §5 Phase 1 文件:`lib/data/codex_loader.dart` | **保留**,但解析 md 不解析 yaml(读 md → title 首行 # + paragraphs 按 \n\n 切分) |
| §5 Phase 1 文件:`lib/features/codex/domain/codex_entry.dart` | **保留**,字段不变(id/step/title/category/paragraphs),`fromMd(String raw)` 替代 `fromYaml(Map)` |
| §5 Phase 1 文件:`lib/features/codex/domain/codex_index.dart` | **新增**,Dart const map `idToStep` + `idToCategory`(8 条绑定 + 扩展空间),Mac 端写,**不含中文文案,只含 id 字符串 + step int + category enum** 符合 CLAUDE.md §5.6 |
| §5 Phase 1 文件:`lib/data/game_repository.dart` 红线校验 | **保留 + 简化**,8 条 entry 全在 + step 唯一 + paragraphs 总字数 ∈ [200,550](放宽 +50 因 three_styles_detail 543)|
| §5 Phase 1 文件:`pubspec.yaml` | **0 改动**(`data/narratives/codex/` 已注册)|
| §5 Phase 3 DeepSeek 派单 | **大幅缩水**:只派 1 篇 md(档 8 开锋+结晶+相生),~30min;不重写 7 现成 |
| §6 测试增量 | 从 +20 调整为 **+12-15**:codex_entry md 解析 +3 / codex_loader md scan +2 / game_repository 红线 +3 / codex_providers +3 / codex_tab +5 / codex_entry_detail +2 / baike_screen 改 1 = +18 实际(放宽估计)|
| §9 估时 | Mac 端从 1h50min → **~1h**(opus xhigh 同会话);DeepSeek 端从 3-5h → **~30min**;总 ~1.5h |

### 12.3 新增 Q5b 拍板

**档 2 强化+共鸣**:strengthening.md(329 字)+ resonance.md(423 字)如何处理?

- 选项 1:**只收 resonance.md**(更深的机制 + 文学性强 + 423 字最贴 200-500 范围) — **推荐**
- 选项 2:只收 strengthening.md(强化是 §10.1 档 2 直接落点)
- 选项 3:两篇合并成 1 条 `enhancement_and_resonance` 新 md(让 DeepSeek 合 → DeepSeek 端 30min)

**Mac 端默认选 1**(resonance.md 收档 2,strengthening.md 留 P2 扩段),DeepSeek 端 P3 只需补档 8 即可。strengthening.md 内容不浪费,留 P2 第 2 批扩段时入库。

### 12.4 lib/features/codex/domain/codex_index.dart 设计预览

```dart
// lib/features/codex/domain/codex_index.dart
//
// P1.z 8 档机制百科条目绑定(对齐 GDD §10.1 8 档解锁节奏)。
// 仅含 id 字符串 + step int + CodexCategory enum,无中文文案。
// 文案存于 data/narratives/codex/<id>.md(DeepSeek 领地)。

import 'codex_category.dart';

class CodexIndex {
  CodexIndex._();

  /// P1.z 首批 8 条机制百科条目(对齐 §10.1 8 档)。
  ///
  /// 扩展条目(equipment_tiers / weapon_forging / battle_taboos 等)留 P2 滚动。
  static const List<({String id, int step, CodexCategory category})> entries = [
    (id: 'realm',                  step: 1, category: CodexCategory.combat),
    (id: 'resonance',              step: 2, category: CodexCategory.enhancement),
    (id: 'techniques_and_styles',  step: 3, category: CodexCategory.techniques),
    (id: 'three_styles_detail',    step: 4, category: CodexCategory.schoolCounter),
    (id: 'retreat',                step: 5, category: CodexCategory.seclusion),
    (id: 'master_disciple',        step: 6, category: CodexCategory.lineage),
    (id: 'encounter_system',       step: 7, category: CodexCategory.encounter),
    (id: 'combat_advanced',        step: 8, category: CodexCategory.advanced), // DeepSeek P3 补
  ];
}
```

### 12.5 md 解析规范(CodexEntry.fromMd)

```
input:
  # 境界
  
  武学一道，自古以来便有「九品」之分。然江湖人言粗犷，
  不问九品而论「流」——三流、二流、一流，再上去就是...
  
  每一阶又分七层：启蒙、入门、熟练、精通、圆熟、化境、登峰。
  若按老镖师的话讲...

output:
  CodexEntry(
    id: 'realm',                    // 从文件名(不含 .md)
    step: 1,                        // 从 CodexIndex.entries 反查
    title: '境界',                  // 首行 `# 标题` 去 `# `
    category: CodexCategory.combat, // 从 CodexIndex.entries 反查
    paragraphs: [
      '武学一道，自古以来便有「九品」之分。然江湖人言粗犷，\n不问九品而论「流」——三流、二流、一流，再上去就是...',
      '每一阶又分七层：启蒙、入门、熟练、精通、圆熟、化境、登峰。\n若按老镖师的话讲...',
    ],
  )
```

切段规则:连续 2+ 换行(`\n\s*\n`)分段,段内单换行保留。

### 12.6 调整后估时

| Phase | 时长(opus xhigh 同会话)|
|---|---|
| Phase 1 数据/领域(md loader + index + entry + repository hook) | ~25min |
| Phase 2 Application/UI | ~50min |
| Phase 3 DeepSeek 派单 spec(1 篇 md)| ~10min |
| Phase 4 收口 | ~15min |
| **Mac 端合计** | **~1h40min** vs 原 spec sonnet baseline 3.5-5h |
| DeepSeek 端 P3 文案 | **~30min**(1 篇 md × 300-500 字)|
