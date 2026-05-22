# Ch5「征东」· Phase 1 spec(1.0 P2 第二条主线第 2 章)

> 日期:2026-05-22 早间
> 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:`p2_ch5_phase0_reality_check_2026-05-22.md`
> 用户拍板:章名「征东」/ jueDing 全章 / 推荐文化主轴 / 末 Boss C 复合(三弟子 + 中州顶强者)/ GDD §12.4.1 同步升 v1.5 / Batch 沿 Ch4 拆 3 子波

---

## TL;DR

- **章定位**:1.0 P2 第二条主线第 2 章(承 Ch4 西出 → 东归长安 → 中州武林大会)
- **境界跨度**:jueDing 一流(qiMeng → dengFeng 完整 7 层)
- **5 关结构**:1-3 普通 + 4 小 Boss + 5 大 Boss(跨 zongShi 末关)
- **地理梯度**:潼关 → 嵩山道观 → 黄河义渡 → 中州武林论剑场 → 嵩山论剑顶
- **biome 复用**:`mountainForest` / `temple` / `dock` / `drillGround` / `cityWall`(**不扩 enum**,memory `feedback_avoid_over_engineer_abstraction`)
- **数值梯度**:HP 14,500 → 32,000 / Atk 1,200 → 1,950 / Speed 200 → 250(全在 §5.4 红线内)
- **字数预算**:~5,000 字(章首尾 ~1,300 + 12 stages narratives ~3,700)
- **schema 改动**:0(全复用 Ch4 EncounterBiome 扩后的现有 17 enum)
- **不动**:lib/ 零代码改(除红线层 4 处硬码 patch)/ equipment.yaml(全用现成 zhongQi/baoWu)/ skills.yaml(jianghu/shichuan 阶现成)/ techniques.yaml(jueDing/zongShi 阶现成)

---

## 一 · 5 关数值矩阵 + 敌人设计

### 1.1 数值梯度推算(沿 Ch4 经验 + jueDing 升档)

参考 Ch4 yiLiu 7,200→15,500 / 720→1,250,jueDing 应高约 1.6-2×(攻方境界 +1 阶 → HP/Atk pool 升档)。末 Boss 跨 zongShi·qiMeng(差 1 阶,GDD §5.5 攻方 ×1.4 守方 ×0.7,触发跨阶红线压测)。

| 关 | requiredRealm | enemy tier/layer cap | HP cap | Atk cap | Speed cap | difficulty | baseExp | 跨阶 |
|---|---|---|---|---|---|---|---|---|
| 05-1 | jueDing | jueDing·qiMeng | 14,500 | 1,200 | 200 | 3.7 | 22,000 | — |
| 05-2 | jueDing | jueDing·shuLian | 17,000 | 1,350 | 215 | 3.9 | 25,000 | — |
| 05-3 | jueDing | jueDing·jingTong | 20,500 | 1,500 | 230 | 4.1 | 28,000 | — |
| 05-4 | jueDing | jueDing·yuanShu(小 Boss)| 24,000 | 1,700 | 240 | 4.3 | 32,000 | — |
| 05-5 | jueDing | dengFeng + **zongShi·qiMeng**(末 Boss 跨阶)| 32,000 | 1,950 | 250 | 4.6 | 40,000 | ✅ |

**红线自查**:Boss HP 32,000 < §5.4 50,000 ✅ / Atk 1,950 < 装备 Atk 2,000 ✅(普伤公式约束 ≤ 8,000)/ Speed 250 沿 Ch4 +35 升档合理。

### 1.2 5 关 stage 详(简表 · 完整 entry 沿 Ch4 stage_04_* 体例)

| stage_id | name | biome | weather | prev | 末 Boss |
|---|---|---|---|---|---|
| stage_05_01 | 渭水东渡 | mountainForest | clear | — | — |
| stage_05_02 | 嵩山道观 | temple | mist | 05_01 | — |
| stage_05_03 | 黄河义渡 | dock | clear | 05_02 | — |
| stage_05_04 | 中州论剑(小 Boss) | drillGround | clear | 05_03 | 中州先锋(jueDing·yuanShu) |
| stage_05_05 | 嵩山一决(末 Boss · 跨 zongShi) | cityWall | night | 05_04 | C 复合三人组 |

### 1.3 末 Boss 三人组 C 复合(stage_05_05)

| 角色 | tier/layer | school | HP | Atk | Speed | skillIds | 文化定位 |
|---|---|---|---|---|---|---|---|
| **enemy_zongShi_xiliang_sandizi** 西凉三弟子 | **zongShi·qiMeng**(跨阶)| yinRou | **32,000** | **1,950** | 250 | `skill_yinrou_shichuan_basic/skill/ult` | 师承霸主沉默体例 + 小铜镜出场 |
| **enemy_jueDing_zhongzhou_lunjian** 中州论剑顶 | jueDing·dengFeng | gangMeng | 27,000 | 1,750 | 235 | `skill_gangmeng_jianghu_basic/skill/ult` | 公开比剑 + 中州礼节 |
| **enemy_jueDing_songshan_daozong** 嵩山道宗 | jueDing·dengFeng | lingQiao | 26,000 | 1,700 | 245 | `skill_lingqiao_jianghu_basic/skill/ult` | 道家飘逸 + 中州本土武林 |

**dropTable**(给玩家进 Ch6 zongShi 起步):
- `weapon_baowu_chang_hong_jian` 1.0(主奖,长虹剑 — 中州顶强者继承奖)
- `accessory_baowu_yu_long_pei` 0.5(zongShi 配饰)
- `armor_zhongqi_yin_lin_jia` 0.4(银鳞甲补 jueDing,跨 Ch4 lore 联结)
- `item_xinxuejiejing` qty [14,18] 1.0

---

## 二 · 文化叙事弧(沿 Ch4 4 拍板叙事弧体例 · memory `project_wuxia_idle_ch4_cultural_arc`)

| 维度 | Ch5 拍板 |
|---|---|
| **章首心境** | 「西出阳关之后的回归」— 承接 Ch4「已知不足」顿悟,东归路上反思,中州武林初涉 |
| **章末拐点** | 「师父遗言全听懂」— Ch4 半懂「就先去走一走」+「听那处地方的风」,Ch5 全懂「剑到了一处地方,就要听那处地方的风」+ 师父第三句遗言起(为 Ch6 飞升伏笔) |
| **末 Boss 类型** | C 复合:西凉霸主三弟子(沉默 + 中州顶强者论剑联手)— 留霸主本人到 Ch6 顶决战 |
| **物理遗物 hook** | 西凉三弟子留**师承玉佩**(刻「师」字)给 Ch6 — Ch5 章首 prologue 玩家小铜镜与三弟子玉佩对照,章末三弟子留遗物 |

**Tier jueDing 风格梯度词**:**「沉静 / 从容 / 通达 / 入微」**(对照 Ch4 yiLiu「沉着 / 肃杀 / 老练 / 冷静」,jueDing 偏内省 vs yiLiu 偏外在)。

**师父遗言 3 处贯穿**(沿 Ch4 体例):
1. **chapter_05 prologue 章首**:Ch4 epilogue「半听懂」开头 →「东归路上反思,师父的第二句话此刻在心里反复回响」
2. **stage_05_05_defeat**:落败时回响「剑到了一处地方,就要听那处地方的风」— 全听懂中州武林的「风」
3. **chapter_05 epilogue 章尾**:「师父临终那第三句话,他到此刻才听明白前一半」(为 Ch6 hook)

---

## 三 · 12 narratives 文件(沿 Ch4 体例 ~3,700 字)

| 文件 | 类型 | 字数预算 | 风格锚点 |
|---|---|---|---|
| stage_05_01_opening.yaml | 开场 | ~380 | 潼关东渡,中原风物初见,jueDing 沉静 |
| stage_05_01_victory.yaml | 战胜 | ~290 | 关东武人散去,hook 嵩山 |
| stage_05_02_opening.yaml | 开场 | ~420 | 嵩山道观,中州道家武学初涉,雾中论道 |
| stage_05_02_victory.yaml | 战胜 | ~310 | 道宗败北,留经文一卷,hook 黄河 |
| stage_05_03_opening.yaml | 开场 | ~440 | 黄河渡口,夺刀风波,北方水文 |
| stage_05_03_victory.yaml | 战胜 | ~320 | 渡船过黄河,远眺嵩山 hook 论剑 |
| stage_05_04_opening.yaml | 小 Boss 开场 | ~520 | 中州武林论剑场,先锋挑事,礼节中带杀机 |
| stage_05_04_victory.yaml | 小 Boss 战胜 | ~350 | 先锋退场,得中州武林初步认可 |
| stage_05_04_defeat.yaml | 小 Boss 战败 | ~290 | 礼节性认输,中州门派的体面 vs 西出阳关时的肃杀 |
| stage_05_05_opening.yaml | 末 Boss 开场 | ~580 | 嵩山论剑大会主场,三弟子出场(小铜镜兑现)+ 中州顶强者论剑联手 |
| stage_05_05_victory.yaml | 末 Boss 战胜 | ~420 | 大胜 hook Ch6,三弟子留玉佩 + 师父第三句遗言半解 |
| stage_05_05_defeat.yaml | 末 Boss 战败 | ~310 | 三人合力下落败,中州夜寒,师父遗言全听懂的孤独 |

**字数合计**:~4,630 字(单关均 ~390 字,与 Ch4 均 ~410 字接近)。

**chapter_05.yaml** prologue ~700 + epilogue ~550 ≈ ~1,250 字。

---

## 四 · 红线层 schema patch 4 处(沿 Ch5 Phase 0 §1.5)

| 位置 | 现状 | Ch5 改动 |
|---|---|---|
| `lib/data/game_repository.dart _enforceMainlineRedLines` L1187 | 已动态化 `5 * chapterCount` ✅ | **不必改** |
| `lib/features/mainline/presentation/chapter_list_screen.dart` L23 | `_chapters = [1, 2, 3, 4]` | **扩 `[1, 2, 3, 4, 5]`** |
| `test/data/game_repository_test.dart` L43 | `expect(repo.stageDefs.length, 20)` | **扩 25** + 主线红线 case 加 ch=5 循环 |
| `test/features/mainline/presentation/chapter_list_screen_test.dart` | 4 章卡测试 | **扩 5 章卡** |
| `test/balance/battle_strategy_e2e_test.dart` L91-96 | stageIds 主线 20 关 | **扩 25 关** |

---

## 五 · GDD / ROADMAP / PROGRESS 同步动作(Phase 1 + Phase 2.4)

### 5.1 Phase 1(与 spec 同 commit)

- **GDD.md** v1.4 → **v1.5**:① 顶部加 v1.5 变更摘要;② §12.4.1 标签 `[v1.3 待用户审]` → `[v1.5 正式拍板,2026-05-22 用户审稿过]`;③ §12.4 加 Ch5「征东」启动条目。

### 5.2 Phase 2.4(实装后)

- **PROGRESS.md** 顶段加 Ch5 全推进段
- **ROADMAP_1_0.md** P2.1 加 Ch5「征东」子项

---

## 六 · 风险挂账

| # | 风险 | 应对 |
|---|---|---|
| R1 | zongShi/baoWu dropTable 数值跨章连续性(Ch5 末 → Ch6 起) | spec 数值矩阵已审 baoWu attack 1,000-1,400 / health 1,400-2,000,Ch6 起步 zongShi 玩家可携 baoWu 装备 → 不断挡 |
| R2 | 中州武林大会三人 vs 西凉三人组 narrative 差异化 | 风格梯度词锁:中州「礼节 / 公开 / 论剑」对比西凉「沉默 / 不语 / 出手即决」,Tier 词 jueDing「沉静 / 从容」对比 yiLiu「沉着 / 肃杀」 |
| R3 | stages.yaml prevStageId 单链(2026-05-22 R3 红线已 ready)| stage_05_01..05 直链,test 兜底 |
| R4 | 小铜镜兑现剧情写实(避免「神迹化」)| chapter_05 prologue 写「玩家从怀里掏出小铜镜」+ stage_05_05_opening 写「三弟子腰间挂同款玉佩」自然出场,不写神化情节 |
| R5 | 末 Boss 跨阶 zongShi 红线压测(玩家 jueDing·dengFeng + 满 build vs zongShi·qiMeng 主 Boss + 二副 jueDing·dengFeng)| Phase 2.5 跑 50 种子 e2e,(leftWins+draws) ≥ rightWins 综合不输面 |
| R6 | dropTable baoWu reverse reference(2026-05-22 R6 红线已 ready)| `_enforceRedLines` 反向引用红线兜底 |

---

## 七 · 工作流估时(Ch4 ~3.5h 实测校准)

| Batch | 内容 | 估时 |
|---|---|---|
| Phase 1 | spec doc + GDD v1.5 (本 commit) | ~30min |
| Batch 2.1+2.2 | stages.yaml 5 关 + 红线层 patch + UI/strings + test fixture 扩 | ~45min |
| Batch 2.3.① 子波 1 | 10 段 stage opening/victory + chapter_05 占位 + stage_05_04_defeat | ~50min(用户介入点 1)|
| Batch 2.3.② 子波 2 | chapter_05 prologue/epilogue v1 + stage_05_05_defeat | ~30min(用户介入点 2)|
| Batch 2.4 | GDD/ROADMAP/PROGRESS 同步 | ~25min |
| Batch 2.5 | R5 跨阶红线压测 + Phase 2 closeout | ~45min |
| **合计** | — | **~3.5h opus xhigh** |

---

## 八 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式
- CLAUDE.md v1.9 Mac+Opus 单端全权
- memory `project_wuxia_idle_ch4_cultural_arc`:Ch4 4 拍板叙事弧体例(师父遗言 3 处 / 物理遗物 hook / 第二/三人称切换 / 黑名单词)
- memory `feedback_collab_mode_single_lore_workflow`:Tier 7 阶风格梯度 + 黑名单词
- memory `feedback_wuxia_boss_balance_crosstier`:末 Boss 跨 1-2 阶 sweet spot
- memory `feedback_phase0_grep_two_axes` 维度 E:红线层 5 维 grep 已跑(Phase 0 doc §1.5)
- memory `feedback_red_line_test_semantics`:R5 双边断言(leftWins+draws ≥ rightWins 且 rightWins+draws ≥ 1)
- memory `feedback_doc_inflation_overnight`:本 spec ≤ 150 行 ✅

---

**Phase 1 完 → 等用户审 spec 通过 → 切 Phase 2.1+2.2 开始数值实装。**
