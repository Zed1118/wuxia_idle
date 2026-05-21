# 候选 2 主线扩 · Phase 0 reality check(第 4 章 + 5 关)

> 日期:2026-05-21 晚
> 模型:Mac + Opus 4.7(Phase 0 高档,实装 spec 起草后切 xhigh)
> 触发:Stage 3 BOSS 22 张闭环后用户拍板候选 2 主线扩 · 边塞主题(大漠/雁门)
> 产物:本 doc(纯只读盘点,无代码改动)
> 上游 closeout:`art_stage3_boss_closeout_2026-05-21.md`

---

## TL;DR

第 4 章扩**对应 1.0 P2 "第二条主线 3 章 15-20 关"第 1 章**,不是 Demo §8.4 范围。

**4 个关键发现**:
1. ⭐ **口径澄清**:Ch4 = 1.0 P2 P2 阶段(M5-M10)第二条主线第 1 章,**不影响 Demo §8.4 14/14 现状**;PROGRESS 顶段 "Demo §8.4 主线 15→20 上限 + 支撑 1.0 P2 启动" 表述需校正(15→20 上限指 Demo 内,Ch4+ 属 1.0 P2,GDD §8.1 表 3 章不含 Ch4-6)
2. **schema 完备零扩**:`StageDef`(`stage_def.dart:12-115`)字段全(chapterIndex/narrativeOpeningId/VictoryId/DefeatId/biome/weather/sceneBackgroundPath)— 纯内容扩,不动代码
3. ⚠ **挂账 · GDD §8.4 字数上限已破**:实测 chapter*.yaml 3,430 + stages*.yaml 4,803 = **8,233 字**(超 GDD §8.4 "3,000-7,000 字" 上限 +1,233 字);上次 W18-A1 外部审查实测 6,778(2026-05-17),W18 之后又扩了 ~1,500 字;**Demo 字数挂账须先决议**(GDD §8.4 是否更新到 10k 上限?还是把超出部分挂 P2)
4. **边塞主题 lore 已有 hooks**:Ch3 stage_03_04 雁门把链客 + `lore/weapon_shenwu_po_jun_dao.yaml` + `lore/armor_baowu_jin_si_jia.yaml` + `codex/famous_battles.md` 已多处雁门元素;Ch4 不宜重复雁门,**建议向西延伸**(玉门关 / 河西走廊 / 西凉 / 大漠)

---

## 一 · 现状盘点(四维)

### 1.1 stages.yaml(916 行,15 关结构)

3 章 × 5 关 = 15 关,每章结构:**1-3 普通 + 4 小 Boss + 5 大 Boss**(章末)。

| 章 | 境界跨度(实装)| 末 boss 数值(stage_X_05)| narrativeDefeatId |
|---|---|---|---|
| Ch1 学武出山 | xueTu 学徒 | HP 3500 / Atk 160(实测) | 4/5 关有 |
| Ch2 武林初识 | sanLiu 三流 | HP 7000 / Atk 470(实测) | 4/5 关有 |
| Ch3 名扬江湖 | erLiu 二流 | HP 11000 / Atk 900(灰衣人 yinRou/yuanShu)| 4/5 关有 |

**末 boss 数值递增 ratio**:Ch1→Ch2 HP ×2 / Ch2→Ch3 HP ×1.57;Ch4(yiLiu)推算 HP ~12000-15000 / Atk ~1000-1200 / Speed ~200-220。

**配套 schema**(StageDef):
- `chapterIndex` int? · `requiredRealm` enum · `isBossStage` bool · `prevStageId` String?
- `narrativeOpeningId / VictoryId / DefeatId` String?(Defeat 仅章末 4/5 关)
- `biome / weather` enum?(C-W14-2 后加,本章 boss 喂奇遇维度)
- `sceneBackgroundPath` String?(M4 Stage 3 后加,战斗屏背景 png)
- `enemyTeam` length 0-3 · `dropTable` 精细化掉落

**Ch4 5 关 schema 直接复用,零字段扩**。

### 1.2 narratives 字数实测(8,233 总)

```
chapters/chapter_01.yaml    755 字   prologue + epilogue 双段(简洁)
chapters/chapter_02.yaml   1,329 字
chapters/chapter_03.yaml   1,346 字
  合计章首尾                3,430 字

stages/stage_XX_YY_*.yaml  4,803 字(36 文件 = 3 章 × 12 段:5 opening + 5 victory + 2 defeat)
  每文件平均                  ~134 字
  Ch3 12 文件最小/最大       296 / 550 字
  
总字数                     8,233 字  (GDD §8.4 上限 7,000,超 1,233)
```

**Ch4 字数预算推算**:
- Ch4 章首尾 ~1,300 字(沿用 Ch2/Ch3 体例)
- Ch4 stages 12 文件 ~150 字/文件 × 12 = ~1,800 字
- **Ch4 合计 ~3,100 字**
- 加完后总字数 ~11,300 字(若 GDD §8.4 不更新即破上限 +4,300)

### 1.3 encounters.yaml + events 边塞 lore 现状

边塞类 events 现成可复用(15+ 候选):
```
huang_sha_ke_zhan.yaml      黄沙客栈
huang_miao_jiu_seng.yaml    荒庙旧僧
huang_yuan_yi_zhong.yaml    荒原遗冢
gu_dao_xue_ji.yaml          古道雪迹
shan_dao_wu_zhe.yaml        山道无遮
shi_dao_shou_hu.yaml        石刀守护
ma_kuai_song_hua.yaml       马快送花
ye_du_gu_chuan.yaml         夜渡孤船
shan_lin_qi_yu.yaml         山林奇雨
... (累计 30+ events,Demo 实装 24/15-25,P2 内容扩补足 +6-10k 字主线时同步补 encounters)
```

**Ch4 encounter 触发**:可复用 `EncounterBiome.desert / mountain / borderland`(待确认 enum 是否已有相应 biome 枚举);若未有,加 1-2 enum 即可,memory `feedback_phase0_grep_two_axes` 反例(P3 UI 接入缩水)不适用本批(纯内容)。

### 1.4 雁门关 lore 已有 hooks(避重复)

```
stages/stage_03_04 雁门把链客 boss + 三段 narrative
lore/weapon_shenwu_po_jun_dao.yaml      神物破军刀(含雁门关元素)
lore/armor_baowu_jin_si_jia.yaml        宝物金丝甲(含雁门关元素)
codex/famous_battles.md                  著名战役(含雁门)
recruit_candidates.yaml                  收徒候选(可能含雁门相关)
```

**建议 Ch4 地理向西延伸**:玉门关 / 河西走廊 / 嘉峪关 / 西凉 / 大漠戈壁 — 不与 Ch3 雁门重叠,延展 GDD §1 写实武侠 + memory `feedback_mj_character_batch_v6_evolution` 主题词梯度。

---

## 二 · 关键发现详

### 发现 1 ⭐ · Ch4 = 1.0 P2 第二条主线第 1 章(口径澄清)

**ROADMAP_1_0.md L37 P2 行**:
> P2 第二条主线主战场 M5-M10(6 月)· §12.4 第二条主线 3 章 15-20 关 / §12.1 心魔 / A1 飞升 E.2/E.3 + 遗物 transfer / 文案 +6-10k 字 / 装备 35→80 / 心法 21→50 / 典故 80→160

- **Demo §8.4 主线 15-20 关**:目前实装 15 关 = Ch1-3,在 §8.4 区间下沿
- **1.0 P2 第二条主线 3 章 15-20 关**:Ch4-6 新章节,文案 +6-10k 字(P2 范畴)
- **PROGRESS 顶段表述 "Demo §8.4 主线 15→20 上限"**:**易误读**,15→20 上限指 Demo 内可扩到 20,但 Demo 章节固定 3 章(GDD §8.1)— 即可加 1-5 关延展 Ch3 但不开第 4 章

**Ch4 5 关定位拍板**:
- 选项 A:**当 1.0 P2 第二条主线第 1 章**(M5-M10 范畴,本会话起跑就锁 P2 标记)
- 选项 B:**当 Demo §8.4 扩** — 但 GDD §8.1 只有 3 章,需先升级 GDD §8.1 到 4 章 + §8.4 字数上限 → 触及 GDD 修改
- 选项 C:**当混血** — 第 4 章 5 关收作 Demo §8.4 内的"番外/支线",GDD §8.1 不动 — 风险:番外不在主线计数,玩家完成度感觉割裂

**推荐选项 A**:实质就是 1.0 P2 起跑,本会话作为 P2 启动桥头堡;**PROGRESS 顶段需要校正**(把 "Demo §8.4 主线 15→20 上限" 删掉,改为 "1.0 P2 第二条主线启动")。

### 发现 2 · schema 完备零扩

stage_def.dart 字段 + biome/weather/sceneBackgroundPath 都齐(M4 Stage 3 已扩好),Ch4 纯内容扩:
- 12 narrative 文件(5 opening + 5 victory + 2 defeat)
- stages.yaml 5 关 entry(沿用 Ch3 数值 +20-30% 跨阶到 yiLiu)
- 章首尾 chapter_04.yaml

可选:`EncounterBiome` enum 是否需补 desert/borderland — Phase 1 起草 spec 时 grep 当前 enum 后再决定。

### 发现 3 ⚠ · GDD §8.4 字数上限已破挂账

| 时点 | 实测字数 | GDD §8.4 上限 | 状态 |
|---|---|---|---|
| W18-A1(2026-05-17 外部审查)| 6,778 | 5,000(原)→ 7,000(v1.7 升档) | 接近上限,可接受 |
| 现在(2026-05-21)| **8,233** | 7,000 | **超 +1,233** |
| Ch4 加完(若)| ~11,300 | 7,000 | **超 +4,300** |

**挂账**:Demo §8.4 字数已超(W18 之后 ~1,500 字扩未对齐 GDD),需先决议:
- 方案 α:GDD §8.4 字数上限改为 10,000 字(Demo 内 + 兼容未来扩)
- 方案 β:认 Demo 已超,作既成事实不动 GDD §8.4(不严谨)
- 方案 γ:Ch4-6 字数计入 1.0 P2 不计入 Demo §8.4,Demo §8.4 7000 上限保留但下沿留 1,233 buffer 不严抓

**推荐方案 γ**:Ch4 是 1.0 P2 范畴,Demo §8.4 字数挂账作 W18 之后扩的"轻微越线"接受,不动 GDD §8.4 上限;1.0 P2 字数预算单独跟。

### 发现 4 · 边塞主题向西延伸建议

避免与 Ch3 stage_03_04 雁门元素重复,Ch4 5 关可走"中原→西北→大漠"地理梯度:

| 关 | 主题方向 | biome/weather 候选 | boss 类型梯度 |
|---|---|---|---|
| 4-1 | 出关西行 / 河西走廊 | desert?/clear | yiLiu·qiMeng 流寇前哨 |
| 4-2 | 玉门关 / 古道驿站 | borderland?/wind | yiLiu·ruMen 守关把总 |
| 4-3 | 沙海迷踪 / 商队遭袭 | desert?/sandstorm? | yiLiu·shuJian 沙匪头领 |
| 4-4 (小 Boss) | 西凉武林集会 / 私斗 | mountain?/clear | yiLiu·yuanShu 武林名宿 |
| 4-5 (大 Boss) | 嘉峪关 / 西凉霸主 | borderland?/night | yiLiu·dengFeng 西凉霸主 三人组 |

数值梯度(推算):Ch3 末 boss HP 11000/Atk 900 → Ch4 末 boss HP ~14000-15000 / Atk ~1100-1200 / Speed ~200-220 — 仍在 §5.4 红线 "Boss 血量 50,000+" 之下,且属 yiLiu 区间合理。

---

## 三 · 待用户拍板项

按推荐选项预填,等用户确认/修改:

| # | 拍板项 | 推荐 | 备选 |
|---|---|---|---|
| 1 | Ch4 定位 | A · 1.0 P2 第二条主线第 1 章 | B · Demo §8.4 扩 / C · Demo 支线番外 |
| 2 | 5 关结构 | 沿用 1-3 普通 + 4 小 Boss + 5 大 Boss(同 Ch1-3 体例)| 4 关合并 / 6 关扩展 |
| 3 | 境界跨度 | yiLiu 全章(qiMeng→dengFeng)| yiLiu 跨 jueDing 末关 |
| 4 | 地理 | 西北 / 玉门关 / 河西走廊 / 大漠戈壁(避雁门重叠)| 重叠雁门做 Ch3 续 / 完全自定主题 |
| 5 | 字数挂账 | 方案 γ · Demo §8.4 不动,Ch4 计 1.0 P2 | α · GDD §8.4 升 10k / β · 既成事实 |
| 6 | Encounter biome enum 扩 | spec 起草前 grep 当前 enum,如缺补 1-2 个(desert/borderland)| 复用 mountain + 接受语义偏移 |
| 7 | DeepSeek 退役后单端文案 | Mac+Opus 全权写(沿 Tier 风格梯度 v1.8)| 用户介入精修关键段(章首尾 + 末 boss defeat)|

---

## 四 · 推荐工作流(spec → 实装)

**预计 ~10-15h opus xhigh(分 Phase 1-3)**:

- **Phase 1 · spec 起草(opus xhigh ~30-45min,本会话本次可继续做)**
  - 用户拍板上述 7 项后,起草 `docs/handoff/p1_x_chapter4_spec_2026-05-21.md`
  - 含:5 关 stages.yaml 设计稿(name/敌人组合/数值/skillIds/dropTable)+ 12 narratives 文件章节标题 + 章首尾构想 + boss 设计 + encounter biome 补丁 + GDD/PROGRESS 同步动作清单
  
- **Phase 2 · 内容产出(opus xhigh ~6-10h,分 batch)**
  - Batch 2.1 stages.yaml 5 关 entry(~1h):新 5 关 entry + enemy id 命名 + 数值锚定 yiLiu × 三流派 + skillIds 复用 mingjia/menpai 阶
  - Batch 2.2 narratives 12 文件(~3-5h):章首尾(Ch2/Ch3 体例)+ 5 opening + 5 victory + 2 defeat(章末 4/5 关)
  - Batch 2.3 encounters.yaml + events 文件配套(~1-2h):若决议补 desert/borderland biome,加 2-3 encounter 触发 + 关联事件
  - Batch 2.4 GDD + PROGRESS + ROADMAP_1_0 同步(~30min):明确 Ch4 P2 标记
  
- **Phase 3 · 验证(opus xhigh ~30-60min)**
  - `flutter analyze` 0 issues
  - `flutter test` 全 pass + 红线测试加 Ch4 关卡 case
  - schema 校验(loader 跑通 Ch4 yaml)
  - 手动跑 Ch4 第一关战斗(用户跑 macOS / Codex Pen 视觉验收,可选)

**Phase 1 spec 起草用 Mac+Opus xhigh 直接干,本会话候选 2 起手不需 nightshift / Codex 协助**(单端文案 + 数值 + 代码全在 Mac 主对话内即可)。

---

## 五 · 不变量沿用

- GDD §5.4 数值红线(Boss HP ≤ 50000 / 内力 ≤ 15000 / 装备攻击 ≤ 2000)
- GDD §5.3 三系锁死(境界 ↔ 装备阶 ↔ 心法阶)
- §5.6 不硬编码数值/文案 / §6 核心公式
- CLAUDE.md v1.9 单端 Mac+Opus 全权(数值 + 文案 + 代码 + GDD)
- Riverpod 3.x / Isar / 不引第三方游戏引擎
- 工作流速度 3 lever(memory `feedback_workflow_speed_levers`):局部 test / spec Phase 0 分布矩阵 / closeout ≤50 行扩段

---

## 六 · 上下游 reference

- **上游**:`art_stage3_boss_closeout_2026-05-21.md`(本会话 BOSS 22 张闭环)
- **上游**:`stage_audit_2026-05-20.md`(P1 状态 + 1.0 P2 路线图对齐)
- **同级**:`docs/ROADMAP_1_0.md` v1.2(P2 第二条主线 3 章 15-20 关 / +6-10k 字)
- **同级**:GDD §5.4 / §6 / §7 / §8.1 / §8.4 / §10.2 / §12
- **下游 next**:`p1_x_chapter4_spec_2026-05-21.md`(Phase 1 起草后填充)
- **memory sink**:本 Phase 0 暂无新 memory(reality check 内容入 doc,不入 memory);若 Ch4 实装中触发新 pattern 再开 memory

---

## 七 · Phase 0 结束态(2026-05-21 晚 ~22:00)

- 现状盘点:4 维(stages/narratives/encounters/lore)全跑完
- 4 关键发现已浮现(Ch4 定位 / schema 完备 / 字数挂账 / 主题向西)
- 7 项待拍板项就绪(预填推荐 + 备选)
- 工作流 Phase 1-3 已估时(~10-15h)
- 不动代码 / 不动 yaml / 不动 GDD,本 Phase 0 仅产 doc 1 个

**等用户拍板 → Phase 1 spec 起草开工**。
