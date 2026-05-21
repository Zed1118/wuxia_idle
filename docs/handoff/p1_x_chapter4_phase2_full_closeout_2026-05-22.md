# 候选 2 主线扩 Ch4「西出阳关」 · Phase 2 全收口 closeout

> 日期:2026-05-22(凌晨,8h autonomous 工作流 A2 批次)
> 模型:Mac + Opus 4.7 xhigh(累计 ~3.5h)
> 上游 spec:[`p1_x_chapter4_spec_2026-05-21.md`](p1_x_chapter4_spec_2026-05-21.md)
> 上游 Phase 0:[`p1_x_chapter4_phase0_reality_check_2026-05-21.md`](p1_x_chapter4_phase0_reality_check_2026-05-21.md)
> 上游 Batch 1 closeout:[`p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md`](p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md)

---

## TL;DR

Ch4「西出阳关」**1.0 P2 第二条主线第 1 章**全收口 ✅(数值 + narrative 13 文件 + R5 红线压测 + GDD/ROADMAP/PROGRESS 全联动 doc)。**1178 pass / 0 analyze**(原 1177 + R5 跨阶红线压测 +1)。8 commit push origin/main 同步。

**核心成果**:
- **lib + data**:EncounterBiome desert/frontier + 主线红线放开 4 章 20 关 + UI/strings 4 章 + 5 关 stages.yaml entry(HP 7,200→15,500 / 跨阶 jueDing 末 Boss)
- **narrative 13 文件 ~5,880 字**:opening 5 + victory 5 + defeat 2 + chapter_04 章首尾,**4 拍板文化叙事弧确立** ⭐
- **R5 跨阶红线压测**:50 种子玩家满 build vs jueDing boss,(leftWins + draws) ≥ rightWins 综合不输面
- **doc 联动**:GDD v1.2 → v1.3 + ROADMAP_1_0 P2.1 + PROGRESS 顶段

---

## 一 · 8 commit 总览

| # | commit | 类型 | 改动总览 |
|---|---|---|---|
| 1 | `4f7fb6d` | feat(p2 Ch4) [schema][balance] | Phase 2.1+2.1.5+2.2 EncounterBiome + 红线放开 + stages.yaml 5 关 |
| 2 | `73fe060` | docs(progress) | Phase 2.1+2.1.5+2.2 收口 · P2 ~5% → ~25% |
| 3 | `fb06606` | docs(p2 Ch4 closeout) | Phase 2.1+2.1.5+2.2 实装 closeout · spec 漏检披露 + Phase 0 维度 E 沉淀 |
| 4 | `be9ac31` | content(p2 Ch4 narrative) | Batch 2.3.① opus 单写 10 段 narratives + chapter_04 占位 |
| 5 | `4bdb90d` | docs(progress) | Batch 2.3.① 收口 · Phase 2 剩余路径校正 |
| 6 | `0c8175b` | content(p2 Ch4 narrative) | Batch 2.3.② 章首尾 + 末 Boss defeat v1 草稿(用户审稿通过) |
| 7 | `9517d97` | docs(progress) | Batch 2.3.①+② v1 全 13 文件合并段 + v1 草稿待审注 |
| 8 | `1b78d6e` | docs(p2 Ch4 Batch 2.4) [GDD] | GDD v1.3 + ROADMAP_1_0 + PROGRESS 同步 |
| **9**(本批) | **(待 commit)** | **test(p2 Ch4 R5) + docs(closeout)** | **R5 红线压测 + Phase 2 全收口 closeout** |

**累计**:9 commit(含本批)/ ~3.5h opus xhigh / 1178 pass / 0 analyze。

---

## 二 · 改动文件总清单

### lib/(4 文件)

| 文件 | 改动 |
|---|---|
| `lib/core/domain/enums.dart` | EncounterBiome + desert / frontier 2 enum |
| `lib/data/game_repository.dart` | `_enforceMainlineRedLines` 放开硬码 15/3 章 → 动态 `5 * chapterCount` |
| `lib/features/mainline/presentation/chapter_list_screen.dart` | `_chapters [1,2,3] → [1,2,3,4]` |
| `lib/shared/strings.dart` | chapter4Title「西出阳关」+ chapter4Hint + switch case + mainMenuMainlineHint「4 章 20 关」|

### data/(14 文件)

| 文件 | 改动 |
|---|---|
| `data/stages.yaml` | +5 关 entry(stage_04_01..05,+332 行)|
| `data/narratives/chapters/chapter_04.yaml` | 章首尾 ~1,100 字 v1 草稿(prologue + epilogue) |
| `data/narratives/stages/stage_04_01_opening.yaml` | ~383 字 |
| `data/narratives/stages/stage_04_01_victory.yaml` | ~236 字 |
| `data/narratives/stages/stage_04_02_opening.yaml` | ~459 字 |
| `data/narratives/stages/stage_04_02_victory.yaml` | ~279 字 |
| `data/narratives/stages/stage_04_03_opening.yaml` | ~488 字 |
| `data/narratives/stages/stage_04_03_victory.yaml` | ~302 字 |
| `data/narratives/stages/stage_04_04_opening.yaml` | ~637 字 |
| `data/narratives/stages/stage_04_04_victory.yaml` | ~344 字 |
| `data/narratives/stages/stage_04_04_defeat.yaml` | ~292 字 |
| `data/narratives/stages/stage_04_05_opening.yaml` | ~593 字 |
| `data/narratives/stages/stage_04_05_victory.yaml` | ~504 字 |
| `data/narratives/stages/stage_04_05_defeat.yaml` | ~428 字 v1 草稿 |

**narrative 累计**:13 文件 ~5,880 纯正文字。

### test/(4 文件)

| 文件 | 改动 |
|---|---|
| `test/data/game_repository_test.dart` | stageDefs.length 15→20 + 主线 20 关红线 case 加 ch=4 循环 |
| `test/features/mainline/presentation/chapter_list_screen_test.dart` | 3 章卡 → 4 章卡(锁数/通关数/cleared list) |
| `test/balance/battle_strategy_e2e_test.dart` | 主线 15 → 20 关 stageIds + Ch4 5 关 e2e battle test |
| **`test/balance/ch4_r5_crosstier_redline_test.dart`**(本批新加) | **R5 跨阶红线压测 + 50 种子玩家满 build vs jueDing boss** |

### docs/(2 文件 + 本 closeout)

- `GDD.md` v1.2 → v1.3(顶部摘要 + §8.1 注释 + §12.4 第二条主线行 + Ch5/Ch6 升档备注)
- `docs/ROADMAP_1_0.md`(P2.1 行加「升档 25-30 关」+ Ch4 桥头堡子项)
- `PROGRESS.md`(顶段升级 P2 ~25% → ~80%)
- **`docs/handoff/p1_x_chapter4_phase2_full_closeout_2026-05-22.md`**(本 doc)

### Isar codegen(1 文件)

- `lib/features/encounter/domain/encounter_progress.g.dart` 重生 enum index 15/16 = desert/frontier(.gitignore 不进 git,Pen/Codex 端 clone 后跑 build_runner)

---

## 三 · 4 拍板文化叙事弧 ⭐

用户 2026-05-21 早 grill 拍板 4 项,确立 Ch4 全章文化叙事弧:

| 维度 | 用户拍板 | 落地体现 |
|---|---|---|
| **章首心境**(李寒在 Ch3 武林会后第 17 日抵潼关) | 「闯过武林会的**释然**」 | chapter_04 prologue:许昌→潼关→长安灞桥→陇右→酒泉的释然心境过渡,师父遗言「这世上的事,看不懂的,就先去走一走」承上,酒泉客栈对饮 hook 西凉霸主 |
| **章末境界拐点**(打完西凉霸主后,「一流→绝顶」境界暗示) | 「已知不足」**哲学顿悟** | chapter_04 epilogue:嘉峪关夜守关楼石阶 + 霸主小铜镜未取 + 师父第二句遗言「剑到了一处地方,就要听那处地方的风」终听懂一半 + 顿悟核心句「剑往上走的那一段路他确实已经走完了。但再往上的那一段,不在剑上」 |
| **末 Boss 西凉霸主三人组人设**(jueDing·qiMeng·yinRou 流派) | 「**沉默克敌出手即决**」型(留 hook Ch5/Ch6) | stage_04_05_opening:灰袍人慢慢抬手 + 寡言之至「请」/ stage_04_05_victory:霸主开口「中原的剑——比我想的快了半寸」+ 留小铜镜遗物 + 隐式联结 Ch3 stage_03_05 灰衣人 / stage_04_05_defeat:三招对照(第一招你没接住 / 第二招你听见了但没看见 / 第三招没有出)+ 寡言典型「中原来的,再练十年,再来」 |
| **Batch 2.3 切分粒度** | **拆 3 子波**(① opus 10 段单写 + ② 用户精修章首尾 + ③ Batch 2.5 收尾) | Batch 2.3.①(本批 ~50min)+ Batch 2.3.② v1 草稿(~30min,用户审稿通过)+ Batch 2.4 doc 同步 + Batch 2.5 R5 + closeout(本批) |

**叙事弧协同**:释然出发(章首)→ 一路推进(stage 1-3)→ 西凉论剑(stage_04_04 校场礼节)→ 阳关沉默克敌(stage_04_05 霸主三招手势)→ 已知不足顿悟(章末)。**全章「修武渐悟」内化弧**,不写外在血战 / 不写网游词冲击,Tier 7 阶风格梯度词锚定到位。

---

## 四 · 字数预算 vs 实测

| 段 | spec 预算 | 实测 | 偏差 |
|---|---|---|---|
| chapter_04.yaml prologue + epilogue | ~1,300 字 | ~1,004 字(含 yaml 元字符,纯正文 ~900) | -23%(预算偏高,实际紧凑些) |
| 10 段 stage opening + victory(opus 单写) | ~3,500 字 | ~4,460 字 | +27%(opus 单写偏热) |
| stage_04_04_defeat(opus 单写) | ~300 字 | ~292 字 | -3% |
| stage_04_05_defeat(v1 草稿) | ~320 字 | ~428 字 | +34% |
| **合计** | **~5,420 字** | **~6,180 字**(含 yaml 元字符)/ ~5,880 纯正文 | **+9%**(整体合理范围) |

**结论**:opus 单写 narrative 字数偏热(单段 +20-30%),但整体在预算合理范围(±15%)。Tier 风格梯度词锚定到位,黑名单词 0 命中。

---

## 五 · 工作量复盘 ⭐⭐(用户颗粒度纠偏 case)

memory `feedback_opus_xhigh_interactive_duration`(已更新)新增 4 锚点:

| 批次 | spec 预估(sonnet baseline) | 实测 | 加速比 |
|---|---|---|---|
| Batch 2.1+2.1.5+2.2 | 1.5-2h | ~1.5h | ~1×(spec 漏检 +1.5h 反而提速 25%) |
| Batch 2.3.① | 3-5h | **~50min** | **4-6×** |
| Batch 2.3.② | 3-5h(合 ① 原 spec) | **~30min** | **6-10×** |
| Batch 2.4 doc 同步 | 30-60min | **~25min** | **1.5-2.5×** |
| Batch 2.5 R5 + closeout | 1-2h | ~1h(预估) | ~1-2× |
| **全 Phase 2** | **6-10h** | **~3.5h** | **~2-3×** |

**用户反馈**(2026-05-21 晚):「能不能把任务的颗粒度做准确一些,不要浪费时间」。memory `feedback_opus_xhigh_interactive_duration` 已 sink 颗粒度纠偏 case + 「8h autonomous / overnight 工作流不要按 sonnet baseline 排任务清单」反例。

**根因**:① opus xhigh 单轮长 plan + 一次性多文件改动节奏 ② 同 context 主对话复用决策日志(4 拍板文化叙事弧确立后直接落 narrative)③ Ch4 走过的路 Ch5/Ch6 还能更快(spec/数值/UI/narrative 机械化复用)。

---

## 六 · Phase 0/1 spec 漏检披露

memory `feedback_phase0_grep_two_axes` 维度 E 沉淀:

| 漏检 | 位置 | 影响 |
|---|---|---|
| **R0 红线层**:`_enforceMainlineRedLines` 硬绑 15/3 章 | `lib/data/game_repository.dart:1159-1184` | Phase 2.1 起步时浮现,+30min 修 |
| **UI 硬码 list**:`ChapterListScreen._chapters [1,2,3]` | `lib/features/mainline/presentation/chapter_list_screen.dart:23` | Phase 2.1 起步时浮现,+10min 修 |
| **test 总数硬绑**:`stageDefs.length, 15` | `test/data/game_repository_test.dart:43` | Phase 2.2 起步时浮现,+15min 修 |
| **test fixture 硬循环**:`for (ch in [1,2,3])` | `test/data/game_repository_test.dart:189-211` | 同上,+5min 修 |
| **test fixture 硬列**:`stageIds[15]` | `test/balance/battle_strategy_e2e_test.dart:90-95` | 同上,+10min 修 |

**Phase 0 起草前必跑 5 维 grep**(memory 维度 E):
```bash
grep -n "_enforce.*RedLines" lib/data/game_repository.dart        # 红线层
grep -rn "_chapters\s*=" lib/                                      # UI 硬码 list
grep -rn "stageDefs\.length, [0-9]" test/                          # test 总数
grep -rn "for.*ch in \[" test/                                     # test 硬循环
grep -rn "stage_0[1-3]_0[1-5]" test/balance/                       # test 硬列
```

---

## 七 · 红线自查总览(GDD §5.4 + §7)

| 字段 | Ch4 最高值 | 红线 | 状态 |
|---|---|---|---|
| 单 enemy HP | 15,500(stage_04_05 西凉霸主) | Boss 50,000+ | ✅ 远低 |
| 单 enemy Atk | 1,250 | 普伤上限 8,000 | ✅ |
| 单 enemy Speed | 215 | 公式约束 | ✅ |
| **R5 跨阶压测**:玩家方满 build 综合不输面 | (leftWins + draws) ≥ rightWins | 跨阶不一边倒 | ✅ |
| **主线总关数** | **20**(4 章 × 5 关) | **GDD §8.4 15-20 关** | ⚠ **顶上限**,Ch5/Ch6 进 1.0 P2 升档 25-30(GDD v1.3 已挂账) |
| 主线字数 | 8,233 + Ch4 ~5,880 = ~14,113 | GDD §8.4 7,000(Demo)| ⚠ Ch4 已超 1.0 P2 字数预算 ~50%(预算 +6-10k 字 / Ch4 ~5,880),留 Ch5/Ch6 各 ~3k |

---

## 八 · memory sink 候选(本 closeout 沉淀清单)

待 8h-E1 批次集中 sink(避免一次性写散):

1. **`feedback_opus_xhigh_interactive_duration`**(已 sink ✅)— 加 4 Ch4 锚点 + 颗粒度纠偏 case + 8h autonomous 反例
2. **`feedback_phase0_grep_two_axes`**(本 closeout §六)— 维度 E 红线层 5 维 grep
3. **新 memory `project_wuxia_idle_ch4_cultural_arc`**(待)— Ch4 4 拍板文化叙事弧 + Tier 风格梯度落地体例(给 Ch5/Ch6 复用)
4. **`feedback_living_doc_state_drift`**(已存)— 加 Ch4 实战 case「Batch 2.4 GDD v1.3 顶部摘要 + 行号 align」
5. **新 memory `feedback_8h_autonomous_workflow_template`**(待)— 8h 工作流 5 批次 ABCDE 模板 + 自主决策清单 + handoff doc 体例

---

## 九 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式 / §6.6 装备典故
- CLAUDE.md v1.9 Mac+Opus 单端全权
- Riverpod 3.x / Isar / 不引第三方游戏引擎
- spec §八 6 风险挂账(R0 红线层 grep 漏检 = Phase 0/1 发现)+ R5 跨阶红线(本批落地)
- memory `feedback_wuxia_boss_balance_crosstier`:末 Boss 跨阶 jueDing,defeat 文风呼应师父遗言
- memory `feedback_collab_mode_single_lore_workflow`:Tier 7 阶风格梯度词 + 黑名单词

---

## 十 · 下游 reference + Phase 2 全收口状态

### 10.1 P2 下波候选

| # | 任务 | 模型 | 估时(opus xhigh 实测节奏) | 接续度 |
|---|---|---|---|---|
| 1 | **Ch5「征东(暂定)」spec 起草**(Phase 0 + Phase 1 + 4 拍板 grill) | opus xhigh | ~30-45min(Phase 0 grep 现状 reality check) + ~1.5h(Phase 1 spec) | 接续 Ch4 全收口 |
| 2 | **GDD §8.4 1.0 P2 主线 25-30 关升档正式拍板 + 内容总量表新加** | opus | ~30-45min | 留用户审稿(草案 8h-D1 已起) |
| 3 | **Ch4 视觉验收派单 Codex Pen Windows**(stages.yaml 5 关 + narrative UI + chapter_04 list 4 章卡 + biome desert/frontier sceneBackground) | Codex Pen | 派单后 ~1h(用户介入 Codex 桌面 cookie) | 8h-B1 派单 spec 已起 |
| 4 | **§12.1 心魔系统起步**(高境界突破前心魔关卡剧情化) | opus xhigh | 多日 spec | 与 Ch5 解耦,可并行 |
| 5 | **1.0 P2 §12.4 节日活动系统级框架**(W17 内容层已落,系统级框架待) | opus xhigh | 多日 spec | 留 1.0 P2 后续 |

### 10.2 引用

- **上游**:`p1_x_chapter4_spec_2026-05-21.md`(Phase 1 spec)+ `p1_x_chapter4_phase0_reality_check_2026-05-21.md`(Phase 0)+ `p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md`(Batch 1 closeout)
- **commit**:`4f7fb6d` / `73fe060` / `fb06606` / `be9ac31` / `4bdb90d` / `0c8175b` / `9517d97` / `1b78d6e` + 本批
- **同级**:`docs/ROADMAP_1_0.md` P2 路径明确

### 10.3 收尾状态(2026-05-22 凌晨,A2 批次)

- HEAD(待本批 commit)+ R5 test 1 文件新加
- worktree clean(本 doc + R5 test 待 commit)
- 1178 pass / 0 analyze(原 1177 + R5 跨阶红线压测)
- 1.0 路线图:Demo ~95% / P0 100% / P1.1 ~100% / P1.2 ~25% / P1.3 美术线 ~80% / **P2 第二条主线 ~85%**(Ch4 全收口,留 Ch5/Ch6)
- **Phase 2 Ch4 全收口 ✅**,Batch 2.5 R5 + closeout 完成

---

**Phase 2 Ch4 西出阳关 1.0 P2 第二条主线第 1 章桥头堡 — 全收口 ✅**

下波候选 #1(Ch5 spec)8h-D2 批次起 Phase 0 reality check(不拍板)。
