# 候选 2 主线扩 Ch5「[章名待用户拍板]」· Phase 0 reality check

> 日期:2026-05-22 凌晨(8h autonomous 工作流 D2 批次)
> 模型:Mac + Opus 4.7 xhigh
> 上游:Ch4 全收口(`p1_x_chapter4_phase2_full_closeout_2026-05-22.md`)
> 拍板归属:**4 项主轴拍板留用户起床决议**(章名 / 境界跨度 / 文化主轴 / 末 Boss 类型 + 复出 hook 承接)
> 产出:本 Phase 0 reality check(不动 schema,只 grep 现状报告)

---

## TL;DR

Ch5 Phase 0 reality check 完成 ✅。**5 维 grep 现状**:① stages.yaml 0 stage_05 entry(全新需 add)② narratives 0 文件(全新)③ lore zhongQi/baoWu/shenWu 阶**全 15 件 lore 已存**(Ch5 dropTable 可直接引用)④ equipment.yaml 高阶装备 15 件已存(每阶 5 件)⑤ 红线层:`game_repository._enforceMainlineRedLines` 已**动态化**(`5 * chapterCount` 不必改)/ chapter_list_screen `_chapters [1,2,3,4]` 需扩 [1,2,3,4,5] / test 硬绑 20 需扩 25。

**Ch5 工作量预估**(基于 Ch4 实测 ~3.5h 经验):**~2.5-3h opus xhigh**(数值 + narrative + R5 + GDD/ROADMAP/PROGRESS 全联动)。

---

## 一 · 5 维 grep 现状报告(memory `feedback_phase0_grep_two_axes` 维度 A-E)

### 1.1 维度 A:stages.yaml(数值层)

- `grep -c "stage_05_" data/stages.yaml` = **0**
- **结论**:Ch5 5 关 entry 全新需 add(沿 Ch4 stage_04_01..05 体例)

### 1.2 维度 B:narratives(文案层)

- `ls data/narratives/stages/ | grep "stage_05_"` = **0 文件**
- `ls data/narratives/chapters/chapter_05.yaml` = 不存在
- **结论**:Ch5 13 narrative 文件全新(chapter_05 + 10 段 stage opening/victory + 2 段 defeat,沿 Ch4 体例)

### 1.3 维度 C:lore(典故层)— **预存,可直接引用** ⭐

zhongQi / baoWu / shenWu 阶 lore 文件已存 15+ 件:

| 阶 | weapon | armor | accessory |
|---|---|---|---|
| zhongQi(jueDing cap) | `weapon_zhongqi_qing_xu_jian.yaml` ✅(Ch4 末 Boss 主奖,已落) | `armor_zhongqi_yin_lin_jia.yaml` ✅ | `accessory_zhongqi_qing_yu_huan.yaml` ✅(Ch4 末 Boss 副奖) |
| baoWu(zongShi cap) | `weapon_baowu_chang_hong_jian.yaml` / `weapon_baowu_xuan_tian_fu.yaml` / `weapon_baowu_xue_lian_bian.yaml` ✅ | `armor_baowu_jin_si_jia.yaml` ✅(Ch4 末 Boss 传承奖,跨章 lore 联结)+ 其余 | `accessory_baowu_yu_long_pei.yaml` ✅ + 其余 |
| shenWu(wuSheng cap) | `weapon_shenwu_huan_meng_bian.yaml` ✅ + 其余 4 | `armor_shenwu_xuan_huang_pao.yaml` ✅ + 其余 4 | `accessory_shenwu_kun_lun_pei.yaml` ✅ + 其余 4 |

- **结论**:Ch5/Ch6 dropTable 可直接引用现有 lore,**无需新增 lore 文件**(GDD §6.6 典故联结现成)

### 1.4 维度 D:equipment.yaml(数值层)— **预存,可直接引用** ⭐

`grep -E "tier: zhongQi|tier: baoWu|tier: shenWu" data/equipment.yaml` 计数:
- **zhongQi(jueDing cap)** 5 件
- **baoWu(zongShi cap)** 5 件
- **shenWu(wuSheng cap)** 5 件

- **结论**:Ch5 dropTable 可直接引用 zhongQi/baoWu 阶现有 def(Ch5 玩家 jueDing 全章可投放 zhongQi cap 装备 + Ch5 末 Boss 跨 zongShi 可投放 baoWu 起步)

### 1.5 维度 E:红线层(memory `feedback_phase0_grep_two_axes` 维度 E)

| 位置 | 现状 | Ch5 改动 |
|---|---|---|
| `lib/data/game_repository.dart _enforceMainlineRedLines` L1187 | `总数 == 5 * chapterCount`(已动态化 ✅) | **不必改** |
| `lib/features/mainline/presentation/chapter_list_screen.dart` L23 | `_chapters = [1, 2, 3, 4]` 硬码 | **扩到 [1, 2, 3, 4, 5]** |
| `test/data/game_repository_test.dart` L43 | `expect(repo.stageDefs.length, 20)` | **扩到 25** + 主线红线 case 加 ch=5 循环 |
| `test/features/mainline/presentation/chapter_list_screen_test.dart` | 4 章卡测试 | **扩到 5 章卡** |
| `test/balance/battle_strategy_e2e_test.dart` L91-96 | stageIds 主线 20 关 | **扩到 25 关** |

**结论**:红线层硬码层数 Ch5 共 4-5 项小 patch(单文件 ≤10 行改动),Ch4 经验已涵盖。

---

## 二 · EncounterBiome 现状(地理梯度)

`lib/core/domain/enums.dart` EncounterBiome 现已扩 Ch4 desert/frontier 后:
- mountainPath / inn / dock / cityWall / escortRoad / teaHouse / smithy / drillGround / alley / temple / mountainForest / swordTomb / cliffWaterfall / cliff / bambooForest / desert / frontier(17 个)

**Ch5 是否需要新 biome**:取决于用户拍板「章名 / 文化主轴 / 地理梯度」:
- 若「征东」(中原 / 山东半岛 / 渤海) → 复用现有 dock / cityWall / mountainForest / bambooForest,**不必扩**
- 若「问鼎」(中州 / 嵩山 / 武林大会) → 复用 drillGround / temple / mountainForest,**不必扩**
- 若「江南」(水乡 / 西湖 / 苏杭) → 可能需要扩 **waterTown / lake** 1-2 enum
- 若「北漠 / 草原」 → 可能需要扩 **steppe / forest_cold** 1-2 enum
- 若「南疆 / 苗疆」 → 可能需要扩 **jungle / cave** 1-2 enum

memory `feedback_avoid_over_engineer_abstraction`:能复用就不扩。具体看用户拍板地理。

---

## 三 · Ch5 拍板候选(留用户起床决议)

### 3.1 章名拍板(4 选 1)

| 章名 | 文化主轴 | 地理梯度 | 复出 hook 承接(Ch4 西凉霸主小铜镜) |
|---|---|---|---|
| **「征东」** | 东归长安 / 中州武林大会 / 山东半岛 / 渤海 | 西北 → 中原 → 渤海 | 西凉霸主东归 + 中州武林大会复出?(沉默克敌型继续) |
| **「问鼎」** | 中州武林大会 / 嵩山论剑 / 名扬中原 | 河南 / 嵩山 / 中州 | 西凉霸主在嵩山现身 + 「中州武人」与「西凉武人」对照 |
| **「江南」** | 水乡 / 西湖论剑 / 苏杭风物 | 江南水乡 / 西湖 / 苏杭 | 西凉霸主跨度大,留 Ch6 复出?Ch5 走「水墨江南」对比西北「干燥风沙」 |
| **「北漠」** | 草原 / 蒙古 / 边塞 | 北疆 / 草原 | Ch4 西北 → Ch5 北漠 → Ch6 飞升,地理北方一线 |

**推荐**:「**征东**」— Ch4 西出 + Ch5 征东形成对称,师父遗言「这世上的事,看不懂的,就先去走一走」=西北西出,东归是「走过看过再回来」的延续。中州武林大会承接「名扬江湖」(Ch3)→「西出阳关」(Ch4)→「征东」(Ch5)叙事弧。西凉霸主 hook 在中州武林大会复出最自然。

### 3.2 境界跨度拍板

| 候选 | 玩家境界 | 末 Boss 跨阶 |
|---|---|---|
| **A**(对称 Ch4) | jueDing 全章(qiMeng→dengFeng 完整 7 层) | 跨 zongShi·qiMeng(为 Ch6 zongShi 起步) |
| B(jueDing + 部分 zongShi) | jueDing·qiMeng → zongShi·jingTong 中 | 同阶 zongShi 顶层 + 多人特殊机制 |

**推荐**:A 对称,与 Ch4 yiLiu 全章节奏一致。

### 3.3 文化主轴拍板(基于章名)

若「征东」:
| 维度 | 候选 | 推荐 |
|---|---|---|
| **章首心境** | 「西出阳关之后的回归」/「中州武林初涉」/「东归路上的反思」 | **「西出阳关之后的回归」**(承接 Ch4 顿悟「已知不足」) |
| **章末拐点** | 「中州武林之顶」/「武林大会论道」/「师父遗言全听懂」 | **「师父遗言全听懂」**(Ch4 只听懂前一半「看不懂的就先走一走」,Ch5 全听懂「剑到了一处地方,就要听那处地方的风」)|
| **末 Boss 复出 hook** | 「西凉霸主中州复出」/「西凉霸主三弟子复出」/「西凉霸主与中州大派合作」 | **「西凉霸主三弟子复出」**(Ch4 留小铜镜 + 师承体例,留霸主本人到 Ch6) |

### 3.4 末 Boss 类型拍板

| 候选 | 性格 | 战术 |
|---|---|---|
| A 西凉霸主三弟子(沉默 + 中州大派合作) | 寡言但合作非孤狼 | 三人队 + 中州大派护法 |
| B 嵩山论剑顶强者(中州本土武林霸主) | 公开比剑 + 礼节 | 三人队 + 招式公开 |
| **C 复合:三弟子 + 中州顶强者(论剑联手)** | 沉默对开朗 = 西凉对中州冲突 | 三人队 + 流派对照 |

**推荐 C**:剧情冲突最大 + 留 Ch6 续战(三弟子 + 中州顶强者各承一段,Ch6 飞升前再决 Ch5 留挂账)。

---

## 四 · Ch5 工作量预估(Ch4 经验校准)

| 批次 | 内容 | 估时(opus xhigh 实测节奏) |
|---|---|---|
| Phase 0 reality check | **本 doc 已完成 ✅** | ~15min |
| Phase 1 spec(数值矩阵 + Boss 设计 + EncounterBiome + GDD 同步动作 + 风险挂账) | 起 Ch5 spec | ~25-30min |
| Batch 2.1+2.2 数值实装 | 5 关 stages.yaml + UI/strings + test fixture + 红线层 patch | ~30-45min |
| Batch 2.3.① opus 单写 10 段 narrative + chapter_05 占位 | 10 段 opening/victory + 1 stage_05_04_defeat | ~50min |
| Batch 2.3.② v1 章首尾 + stage_05_05_defeat | chapter_05 prologue/epilogue + 1 defeat | ~30min |
| Batch 2.4 GDD/ROADMAP/PROGRESS 同步 | v1.5 顶部 + §12.4 加 Ch5 子项 + ROADMAP P2.1 加 Ch5 子项 + PROGRESS | ~20-30min |
| Batch 2.5 R5 红线压测 + Phase 2 closeout | 5 关 → 25 关 e2e fixture + R5 跨阶压测 + closeout doc | ~30-45min |
| **合计 Ch5 全推进** | — | **~2.5-3h opus xhigh** |

---

## 五 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式 — **完全不动**
- CLAUDE.md v1.9 Mac+Opus 单端全权
- Riverpod 3.x / Isar / 不引第三方游戏引擎
- memory `feedback_collab_mode_single_lore_workflow` Tier 7 阶 jueDing 风格梯度词:**「沉静 / 从容 / 通达 / 入微」**(对照 Ch4 yiLiu「沉着 / 肃杀 / 老练 / 冷静」)
- memory `feedback_wuxia_boss_balance_crosstier` 跨阶设计:Ch5 末 Boss 跨 zongShi·qiMeng(差 1 阶,GDD §5.5 攻方 ×1.4 守方 ×0.7)
- memory `feedback_avoid_over_engineer_abstraction` EncounterBiome 扩与否看用户拍板地理
- memory `feedback_phase0_grep_two_axes` 维度 E 红线层 5 维 grep(本 doc §1.5 已跑)

---

## 六 · 起草下一步

用户起床后需拍板 4 项:
1. **章名**(推荐「征东」)
2. **境界跨度**(推荐 A 对称 jueDing 全章)
3. **文化主轴 3 项**(章首心境 / 章末拐点 / 末 Boss 复出 hook 承接)
4. **Batch 2.3 切分**(沿 Ch4 拆 3 子波 vs 全包一波)

**用户拍板后直接起 Ch5 spec doc**(Phase 1),工作量 ~2.5-3h opus xhigh 全推进。

---

**Ch5 Phase 0 reality check 完成 ✅** → 等用户起床拍板 4 项 → Ch5 spec 起 → Phase 2 实装一波到底。
