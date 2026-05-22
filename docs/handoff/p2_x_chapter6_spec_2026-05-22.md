# Ch6「飞升」· Phase 1 spec(1.0 P2 第二条主线第 3 章)

> 日期:2026-05-22 / 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:`p2_x_chapter6_phase0_reality_check_2026-05-22.md`
> 用户拍板:章名「飞升」/ 境界跨度 A(zongShi 全章 + 末 Boss 跨 wuSheng·qiMeng)/ 文化主轴(师父第三句遗言完整联通 + 西凉霸主本人复出)/ 末 Boss B(霸主 + 三弟子合体)/ Batch 沿 Ch5 拆 3 子波

---

## TL;DR

- **章定位**:1.0 P2 第二条主线第 3 章(承 Ch4 西出 → Ch5 征东 → Ch6 飞升 三章弧收束)
- **境界跨度**:zongShi 宗师(qiMeng → dengFeng 完整 7 层)+ 末 Boss 跨 wuSheng·qiMeng
- **5 关结构**:1-3 普通 + 4 小 Boss + 5 大 Boss(B 复合 = wuSheng·qiMeng 西凉霸主 + 2 副 zongShi·dengFeng 三弟子)
- **地理梯度**:中州论剑场散场 → 嵩山顶 → 黄河之源 → 昆仑山外 → **昆仑山顶**(飞升前夜)
- **biome 复用**:`cityWall` / `mountainForest` / `dock` / `desert` / `mountainForest`(**不扩 enum**,memory `feedback_avoid_over_engineer_abstraction`)
- **数值梯度**:HP 30,000 → 52,000 / Atk 2,000 → 2,700 / Speed 245 → 280(全在 §5.4 红线内,Boss HP < 1M / Atk 在 baseAttack 维度,非装备 Atk)
- **字数预算**:~6.6k 字(沿 Ch5 实测 ±10%)
- **schema 改动**:0(全复用 17 EncounterBiome enum / shenWu 5 件 / chuanShuoShenGong 3 个 / 心魔系统**不引入**)
- **不动**:equipment.yaml(shenWu 现成 5 件)/ techniques.yaml(chuanShuoShenGong 现成 3 个)/ skills.yaml(shichuan / jianghu 阶现成)/ encounters.yaml / EncounterBiome enum

---

## 一 · 5 关数值矩阵 + 末 Boss B 设计

### 1.1 数值梯度(沿 Ch4→Ch5 升档比例 hp ×2.06 / atk ×1.56,Ch6 跨 wuSheng 克制到 ×1.55-1.65)

| 关 | requiredRealm | enemy tier/layer cap | HP cap | Atk cap | Speed cap | difficulty | baseExp | 跨阶 |
|---|---|---|---|---|---|---|---|---|
| 06-1 | zongShi | zongShi·qiMeng | 30,000 | 2,000 | 245 | 4.8 | 48,000 | — |
| 06-2 | zongShi | zongShi·shuLian | 33,000 | 2,150 | 252 | 5.1 | 54,000 | — |
| 06-3 | zongShi | zongShi·jingTong | 36,000 | 2,300 | 260 | 5.4 | 60,000 | — |
| 06-4 | zongShi | zongShi·yuanShu(小 Boss)| 40,000 | 2,400 | 268 | 5.7 | 67,000 | — |
| 06-5 | zongShi | dengFeng + **wuSheng·qiMeng**(末 Boss 跨阶)| 52,000 | 2,700 | 280 | 6.1 | 80,000 | ✅ |

> **数值 delta 说明(spec → 实装)**:原 spec 矩阵 30k/35k/40k/45k/52k 等差升档,实装时发现 stage_06_04 yuanShu (45k) > stage_06_05 副 dengFeng (43k) 违反**层数排序**(GDD §3 dengFeng > yuanShu 7 层 > 5 层)。已调整为 30k/33k/36k/40k/52k(stage_06_04 40k < stage_06_05 副 43k ✓ 排序正确)。**实装 commit `f6379d7` 已对齐,本表为修正后矩阵**。

**红线自查**:Boss HP 52k 在 §5.4「50,000+ 不进 1M」内 ✅ / baseAttack 2,700 ≠ 装备 attackPower 红线(后者 ≤2,000,装备维度)/ **普伤 spot check 最坏 case**(主敌 chuanshuo ult `powerMultiplier=8000` × 暴击 1.5 × 修炼度 3.0 × 流派 1.25 × 跨阶 1.4 × 防御 0.7)≈ **~9 万** 接近 GDD §5.4「大招暴击 几万 不许进十万」上限 ⚠️ acceptable 但偏激进 / 普攻 ~4,200 < §5.4 普伤 8,000 红线 ✅。

### 1.2 5 关 stage 简表(完整 entry 沿 Ch5 stage_05_* 体例)

| stage_id | name | biome | weather | prev | 末 Boss |
|---|---|---|---|---|---|
| stage_06_01 | 论剑散场 | cityWall | clear | — | — |
| stage_06_02 | 嵩山再访 | mountainForest | mist | 06_01 | — |
| stage_06_03 | 黄河之源 | dock | rain | 06_02 | — |
| stage_06_04 | 昆仑山外(小 Boss) | desert | clear | 06_03 | 昆仑外门守关(zongShi·yuanShu) |
| stage_06_05 | 昆仑山顶(末 Boss 跨 wuSheng) | mountainForest | snow | 06_04 | B 复合(霸主 + 三弟子合体) |

### 1.3 末 Boss B 复合(stage_06_05 · 三章弧 hook 全闭环)

| 角色 | tier/layer | school | HP | Atk | Speed | skillIds | 文化定位 |
|---|---|---|---|---|---|---|---|
| **enemy_wuSheng_xiliang_bazhu** 西凉霸主(本人首次开口)| **wuSheng·qiMeng**(跨阶 1)| yinRou | **52,000** | **2,700** | 270 | `skill_yinrou_shichuan_basic/skill/ult` | Ch4 沉默克敌 + Ch5 三弟子代行的反转,飞升前夜首次开口对话 |
| **enemy_zongShi_xiliang_disciple_gang** 西凉三弟子·刚猛 | zongShi·dengFeng | gangMeng | 43,000 | 2,200 | 250 | `skill_gangmeng_shichuan_basic/skill/ult` | 承 Ch5 三弟子玉佩 hook 联结物 |
| **enemy_zongShi_xiliang_disciple_ling** 西凉三弟子·灵巧 | zongShi·dengFeng | lingQiao | 42,000 | 2,150 | 260 | `skill_lingqiao_shichuan_basic/skill/ult` | 承 Ch5 三弟子玉佩 hook 联结物 |

**dropTable**(Ch6 末关 = Demo endgame,给玩家见 wuSheng 阶物件):
- `weapon_shenwu_tian_wen_jian` 1.0(主奖 · 天问剑 · 玩家 zongShi 不可装备 GDD §5.3 但可携带见过,**Phase 5+ 飞升解锁**)
- `accessory_shenwu_kun_lun_pei` 0.5(蜻蜓点水 hook 昆仑)
- `armor_baowu_jin_yu_jia` 0.5(zongShi 实际可装 baoWu 配饰)
- `item_xinxuejiejing` qty [18,24] 1.0

---

## 二 · 文化叙事弧(B 拍板 + 师父第三句完整联通 + 三章 hook 闭环)

| 维度 | Ch6 拍板 |
|---|---|
| **章首心境** | 「飞升前夜的回望」— 承 Ch5 epilogue 师父第三句半解,中州论剑大会胜后启程,小铜镜 + 玉佩两件遗物再次出场 |
| **章末拐点** | **「师父第三句遗言完整联通」** — 三句「先去走一走 / 听那处地方的风 / 最后那一段路也许已说完,下文要自己走」在昆仑山顶**全数照面** |
| **末 Boss B** | 西凉霸主本人首次开口(三章沉默 → 飞升前夜对话)+ 三弟子合体 — Ch4 小铜镜 + Ch5 玉佩双 hook 兑现 |
| **物理遗物 hook** | **不留任何物理遗物** — 承 Ch5 玉佩兑现 →「无物之境」收束(因为「自己走」就是最后一段,不需要再传) |

**Tier zongShi 风格梯度词**:**「澄澈 / 无为 / 玄妙 / 化境」**全章(对照 Ch5 jueDing「沉静 / 从容 / 通达 / 入微」 + Ch4 yiLiu「沉着 / 肃杀 / 老练 / 冷静」,zongShi 偏「人 vs 天地」内省天人)。

**师父遗言 3 处贯穿**(沿 Ch4-Ch5 体例,Ch6 第三句全联通):
1. **chapter_06 prologue 章首**:Ch5 epilogue「也许已说完,下文要自己走」启始 + 三句话第二句「听那处地方的风」回响
2. **stage_06_05_victory**:**「自己走」的过程终点**,飞升前夜师父三句话**全联通** + 玩家自立(不引心魔具象)
3. **chapter_06 epilogue 章尾**:「师父临终那三句话,他到此夜全数明白。下文要自己走 — 走到何处,师父再也指不动了」(为 1.0 P3 飞升或心魔系统 hook)

---

## 三 · 13 narratives 文件(沿 Ch5 实测 ~6.6k 字)

| 文件 | 类型 | 字数预算 | 风格锚点 |
|---|---|---|---|
| stage_06_01_opening.yaml | 开场 | ~430 | 中州论剑场散场,zongShi 澄澈起,三弟子玉佩与小铜镜两件遗物出场 |
| stage_06_01_victory.yaml | 战胜 | ~330 | 论剑余韵,启程嵩山 |
| stage_06_02_opening.yaml | 开场 | ~470 | 嵩山再访(Ch5 stage_05_02 故地),雾中静坐,Tier zongShi 无为 |
| stage_06_02_victory.yaml | 战胜 | ~340 | 嵩山道宗复出再败,hook 黄河之源 |
| stage_06_03_opening.yaml | 开场 | ~490 | 黄河之源,水声玄妙,武学返本之意 |
| stage_06_03_victory.yaml | 战胜 | ~350 | 渡水入西,远眺昆仑 hook 飞升 |
| stage_06_04_opening.yaml | 小 Boss 开场 | ~560 | 昆仑山外昆仑外门守关,化境前夜的最后一关人事 |
| stage_06_04_victory.yaml | 小 Boss 战胜 | ~380 | 守关让路,昆仑山顶在望 |
| stage_06_04_defeat.yaml | 小 Boss 战败 | ~310 | 昆仑外门人事的最后阻挡,师父第二句话回响 |
| stage_06_05_opening.yaml | 末 Boss 开场 | ~620 | 昆仑山顶,雪夜,西凉霸主本人**首次开口** + 三弟子合体,小铜镜玉佩三章联结物全闭环 |
| stage_06_05_victory.yaml | 末 Boss 战胜 | ~480 | 大胜,**师父第三句话全联通**,飞升前夜无物之境收束 hook Ch7/1.0 P3 |
| stage_06_05_defeat.yaml | 末 Boss 战败 | ~360 | 三人合体下落败,雪夜寒,化境未至的孤独 |
| chapter_06.yaml | 章首尾 | ~1,650(prologue ~830 + epilogue ~820) | prologue 承 Ch5 epilogue + 三句遗言起 / epilogue 三句话全联通 + 无物收束 |

**字数合计**:~6,770 字(单 stage 均 ~430 字,与 Ch5 实测 ~6,638 一致 ±2%)。

---

## 四 · 红线层 schema patch 4 处(沿 Ch5 体例)

| 位置 | 现状 | Ch6 改动 |
|---|---|---|
| `lib/data/game_repository.dart _enforceMainlineRedLines` | 已动态化 `5 * chapterCount` ✅(Ch5 已动态)| **不必改** |
| `lib/features/mainline/presentation/chapter_list_screen.dart` | `_chapters = [1, 2, 3, 4, 5]` | **扩 `[1, 2, 3, 4, 5, 6]`** |
| `lib/shared/strings.dart` | chapter5Title/Hint + switch case 5 | **加 chapter6Title「第六章 · 飞升」+ chapter6Hint + case 6** |
| `test/data/game_repository_test.dart` | 25 关 fixture | **扩 30 关** |
| `test/features/mainline/presentation/chapter_list_screen_test.dart` | 5 章卡测试 | **扩 6 章卡** |
| `test/balance/battle_strategy_e2e_test.dart` | 25 stageIds | **扩 30 stageIds** |

---

## 五 · GDD v1.5 → v1.6 同步动作(Phase 1 + Phase 2.4)

### 5.1 Phase 1(与 spec 同 commit)

- **GDD.md** v1.5 → **v1.6**:① 顶部加 v1.6 变更摘要(Ch6 启动);② §12.4 加 Ch6「飞升」启动条目(章名 + 主轴 + 末 Boss B 复合)

### 5.2 Phase 2.4(实装后)

- **PROGRESS.md** 顶段加 Ch6 全推进段(Ch5 段归档末尾)
- **ROADMAP_1_0.md** P2.1 加 Ch6「飞升」子项(P2 第二条主线 ~92% → 100%)
- **GDD §12.4** Ch6 行升「Phase 2 全收口 ✅」

---

## 六 · 风险挂账

| # | 风险 | 应对 |
|---|---|---|
| R1 | wuSheng·qiMeng 主敌 baseAttack 2,700 偏高(Ch5 末 1,950 × 1.38)| Phase 2.5 R5 验,普伤公式终值 ≤8,000 兜底;若爆红线,主敌 atk 收紧到 2,500 |
| R2 | shenWu dropTable 玩家不可装备(zongShi <  wuSheng GDD §5.3)| narrative 写「天问剑入怀,你尚不能持」+ codex 已有相关说明 / dropTable 留 1 件 baoWu 配饰玩家直接可装 |
| R3 | stages.yaml prevStageId 单链(2026-05-22 R3 红线已 ready)| stage_06_01..05 直链,test 兜底 |
| R4 | 西凉霸主本人首次开口的台词分寸(避免「神化」)| 黑名单 14 词 0 命中 + 霸主开口仅 1-2 句,留余韵 |
| R5 | 末 Boss 跨阶 wuSheng 红线压测(玩家 zongShi·dengFeng + 满 build vs wuSheng·qiMeng 主 + 2 副 zongShi·dengFeng)| Phase 2.5 跑 50 种子 e2e,(leftWins+draws) ≥ rightWins 综合不输面 / rightWins+draws ≥ 1 |
| R6 | dropTable shenWu 反向引用红线(2026-05-22 R6 红线 ready)| `_enforceRedLines` 反向引用红线兜底 |
| R7 | enemy 立绘 0 张(西凉霸主 + 三弟子 ~3-5 张)| MJ 异步派单(与 Ch4 enemy 15 张同批),iconPath 占位先落 yaml,Phase 2 不阻塞 |

---

## 七 · 工作流估时(Ch5 ~3.5h opus xhigh 实测校准,精度 1.0×)

| Batch | 内容 | 估时 |
|---|---|---|
| Phase 1 | spec doc + GDD v1.5→v1.6(本 commit)| ~30min |
| Batch 2.1+2.2 | stages.yaml 5 关 + 红线层 patch + strings.dart + chapter_list_screen + test fixture 扩 | ~45min |
| Batch 2.3.① 子波 1 | 11 段 stage opening/victory + stage_06_04_defeat + chapter_06 占位 | ~50min(用户介入点 1)|
| Batch 2.3.② 子波 2 | chapter_06 prologue/epilogue v1 + stage_06_05_defeat | ~30min(用户介入点 2)|
| Batch 2.4 | GDD §12.4 升 / ROADMAP_1_0 P2.1 加 / PROGRESS 同步 | ~25min |
| Batch 2.5 | R5 跨阶红线压测 + Phase 2 closeout | ~45min |
| **合计** | — | **~3-3.5h opus xhigh** |

---

## 八 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式 — 全程不动
- CLAUDE.md v1.9 Mac+Opus 单端全权(GDD/CLAUDE/numbers/data_schema/IDS_REGISTRY 顶部变更摘要明文)
- memory `project_wuxia_idle_ch4_cultural_arc` Ch6 复用 confidence 高(Ch5 已验)
- memory `feedback_collab_mode_single_lore_workflow` Tier 7 阶 + 黑名单词 14 个
- memory `feedback_wuxia_boss_balance_crosstier` 跨阶 1 阶 sweet spot
- memory `feedback_phase0_grep_two_axes` 维度 E 红线层 grep(Phase 0 已跑)
- memory `feedback_red_line_test_semantics` R5 双边断言
- memory `feedback_doc_inflation_overnight` 本 spec ≤150 行 ✅
- memory `feedback_opus_xhigh_interactive_duration` 精度 1.0× 估时
- **§12.1 心魔系统不前置依赖**(B 路线 0 contamination,留 1.0 P3 独立 spec)

---

**Phase 1 完 → Phase 2.1+2.2 开始 5 关 stages.yaml + 红线层 patch 数值实装**
