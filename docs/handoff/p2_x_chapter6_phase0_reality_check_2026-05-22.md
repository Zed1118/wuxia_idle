# Ch6「飞升」Phase 0 reality check(1.0 P2 第二条主线第 3 章)

> 日期:2026-05-22 / 模型:Mac + Opus 4.7 xhigh
> 用户拍板 4 主轴:章名「飞升」/ 境界跨度 A(zongShi 全章 + 末 Boss 跨 wuSheng·qiMeng)/ 文化主轴(师父第三句遗言完整联通 + 西凉霸主本人复出)/ 末 Boss B(霸主 + 三弟子合体)
> 体例沿 Ch4 Phase 0(`p1_x_chapter4_phase0_reality_check_2026-05-21.md`)+ Ch5 6-commit 节奏

---

## 一 · 6 维 grep 结论

| 维度 | 结论 | 缺口 / 已存 |
|---|---|---|
| **1 schema** | numbers.yaml `realms.tiers[wuSheng]`(行 350-353,defense 0.35 / shenWu / chuanShuoShenGong 全 cap)+ 武圣登峰压测案例(行 1238-1251 mult 8000)已存 ✅ | stages.yaml `stage_06_*` 全缺,需扩 5 entry |
| **2 红线层** | `test/balance/ch{4,5}_r5_crosstier_redline_test.dart` 模板成熟 ✅ Ch5 跨 zongShi → Ch6 跨 wuSheng·qiMeng 机械复用 | `ch6_r5_crosstier_redline_test.dart` 待新建(沿 Ch5 模板 +1 文件) |
| **3 邻近目录** | `data/narratives/chapters/` Ch01-05 已存,Ch6 0 / `data/lore/` shenWu lore 0(equip 5 件已落 5/5 lore 缺)/ `data/events/` ch6 0 | chapter_06.yaml + 11 stage narrative + 1-2 defeat 全新写 |
| **4 UI/widget** | `lib/shared/strings.dart:277-313` chapter5Title/Hint + switch case `5 =>` 已存 ✅ | 加 chapter6Title/Hint + case 6 + `chapter_list_screen.dart:10` 注释扩 6 章 |
| **5 assets** | shenWu 装备 10 张(5 件 ×{主图,detail})已落 ✅ | 西凉霸主 + 三弟子 enemy 立绘 0 张(估 ~4-5 张 MJ 异步派单,Phase 2 不阻塞)/ wuSheng 玩家立绘 0 张(玩家本人沿用 jueDing 头像不阻塞)|
| **6 §12.1 心魔** | lib/ + data/numbers.yaml + master/inheritance code 0 引用心魔 ✅(B 完全独立)| Ch6 narrative 文案不引心魔 hook(留 §12.1 P2.2 独立 spec)|

---

## 二 · Ch6 最小变更清单

### A. yaml 数据层(必改)

1. `data/stages.yaml` +5 entries:`stage_06_01..04`(小 Boss 链)+ `stage_06_05`(末 Boss B 复合 = wuSheng·qiMeng 西凉霸主 + 2 副 zongShi·dengFeng 三弟子)
2. `data/narratives/chapters/chapter_06.yaml`(prologue 承 Ch5 epilogue 师父第三句 + epilogue 飞升前夜师父遗言完整联通)
3. `data/narratives/stages/stage_06_*` 11 文件(5 opening + 5 victory + 1-2 defeat)
4. **0 扩**:equipment.yaml(shenWu 5 件现成)/ techniques.yaml(chuanShuoShenGong 3 个现成)/ encounters.yaml / events.yaml(不引新奇遇)/ EncounterBiome enum(全复用)

### B. 红线层(必改)

5. `lib/shared/strings.dart` +2 const(chapter6Title「第六章 · 飞升」/ chapter6Hint)+ 2 switch case
6. `lib/features/chapter/.../chapter_list_screen.dart` 注释 5→6 章
7. `test/features/chapter_list_screen_test.dart` fixture 扩 6 章
8. `test/data/game_repository_test.dart` fixture 扩 6 章 30 关(若有 25 关上限)
9. `test/balance/battle_strategy_e2e_test.dart` +5 stage_06_* e2e 扩段

### C. R5 跨阶红线压测(必新建)

10. `test/balance/ch6_r5_crosstier_redline_test.dart`(沿 Ch5 模板,玩家方 zongShi·dengFeng 满 build + shenWu 装 + chuanShuoShenGong 心法 vs `stage_06_05` 现行 yaml,50 种子双边断言)

### D. doc 同步(Phase 2.4)

11. GDD §12.4 Ch5 行升「Ch6 启动」+ 加 §12.4 Ch6 条目(章名 + 主轴 + 末 Boss 类型)
12. ROADMAP_1_0 P2.1 加 Ch6「飞升」子项(P2 第二条主线 ~92% → 100%)
13. PROGRESS.md 顶段重写 + Ch5 段归档

---

## 三 · Ch6 末 Boss B 设计草案(Phase 1 spec 起草锚定)

跨阶节奏 = Ch5 跨 1 阶模板复用,玩家 zongShi·dengFeng 跨 wuSheng·qiMeng,符合 GDD §5.5 攻方 ×1.4 / 守方 ×0.7。

| Boss | 境界 | 流派 | baseHp 预设 | baseAtk 预设 | baseSpeed |
|---|---|---|---|---|---|
| **主 西凉霸主**(本人首次开口)| wuSheng·qiMeng | yinRou | ~52000 | ~2500 | 270 |
| 副 1 三弟子刚猛(承 Ch5 三人组其一)| zongShi·dengFeng | gangMeng | ~42000 | ~2200 | 245 |
| 副 2 三弟子灵巧(承 Ch5 三人组其二)| zongShi·dengFeng | lingQiao | ~42000 | ~2150 | 255 |

数值规模逐项验 §5.4 红线(普伤 ≤8000 / Boss 血 ≤50000+ 不进 1M / 装备攻击 ≤2000 — Boss baseAttack 不在红线内,直伤为公式终值):**Phase 1 spec 起草时按 Ch5 stage_05_05 ×1.5-1.7 上调比例细化,R5 红线压测验**。

dropEquipmentDefIds:3 件 shenWu(从现有 5 件 shenWu pool 挑 — `weapon_shenwu_tian_wen_jian` / `weapon_shenwu_po_jun_dao` / `accessory_shenwu_kun_lun_pei` 或类似组合)

---

## 四 · 文化主轴落地锚点(narrative Phase 2.3 起草前对齐)

1. **师父第三句遗言完整联通**(Ch5 epilogue hook 兑现)
   - chapter_06 prologue:承 Ch5「也许已说完,下文要自己走」起点
   - stage_06_05_victory:**全章「自己走」过程的终点**,飞升前夜师父三句话**全联通** + 玩家自立(不引心魔具象)
   - chapter_06 epilogue:**不留任何物理遗物**(承 Ch5 玉佩兑现 → Ch6「无物之境」收束)
2. **西凉霸主本人复出**(Ch4 小铜镜 + Ch5 三弟子玉佩双 hook 兑现)
   - chapter_06 prologue:小铜镜与玉佩两件遗物再次出场(三章联结物完整闭环)
   - stage_06_05_opening:霸主**首次开口**(Ch4 沉默克敌 + Ch5 三弟子代行的反转)
3. **Tier zongShi 风格梯度词**:「澄澈 / 无为 / 玄妙 / 化境」全章(memory `project_wuxia_idle_ch4_cultural_arc`)
4. **黑名单 14 词**(legendary/epic/史诗/神器/无敌/血溅/刀光剑影等)0 命中
5. 视角切换:chapter 第三人称 / stage 第二人称(沿 Ch4-Ch5)
6. 字数预算:沿 Ch5 ~6.6k 字 ±10%(prologue/epilogue ~1.6k + 11 stage ~5k)

---

## 五 · Phase 1 spec 起手清单

Phase 1 doc:`docs/handoff/p2_x_chapter6_spec_2026-05-22.md`(沿 Ch5 spec 172 行体例 ≤150 行)

起手内容:① stages.yaml 5 关数值表(stage_06_01..05) ② chapter_06.yaml + 11 stage narrative 体例锚点(已在本 doc §四) ③ R5 跨阶红线双边断言预期(沿 Ch5 模板) ④ GDD v1.5 → v1.6 §12.4 Ch6 启动条目对齐 ⑤ Batch 拆 3 子波(沿 Ch5 节奏 = Phase 1 spec / 2.1+2.2 数值红线 / 2.3.① 子波 1 opus 单写 12 / 2.3.② 子波 2 章首尾精写 / 2.4 doc / 2.5 R5+closeout)

---

## 六 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式 — 全程不动
- CLAUDE.md v1.9 Mac+Opus 单端全权
- memory:`feedback_wuxia_boss_balance_crosstier` 跨阶设计 / `feedback_collab_mode_single_lore_workflow` Tier 7 阶 / `feedback_red_line_test_semantics` 双边断言 / `feedback_doc_inflation_overnight` doc 上限 / `feedback_phase0_grep_two_axes` 维度 E / `feedback_avoid_over_engineer_abstraction` biome 不扩 / `project_wuxia_idle_ch4_cultural_arc` 体例 / `feedback_opus_xhigh_interactive_duration` 精度 1.0× 锚点
- **§12.1 心魔系统不前置依赖**(B 路线 contamination 0,留 P2.2 独立 spec)

---

**Phase 0 ✅ → Phase 1 spec 起草(估 ~30min opus xhigh,沿 Ch5 节奏 ~3-3.5h 全 Phase 2)**
