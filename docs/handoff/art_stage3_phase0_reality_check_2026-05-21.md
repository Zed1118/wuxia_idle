# M4 美术 Stage 3 量产 · Phase 0 reality check(2026-05-21)

> Mac + Opus 4.7 主对话 · ~30min 4 维 grep · 0 代码 / 0 yaml 改动 · 仅产 doc
>
> 用户拍板信号(2026-05-21 grill):
> - **题材**:BOSS 立绘 + 场景插画 + 心法卷轴(3 题材,跳 NPC portrait)
> - **数量**:~50 张 轻量收口(P1.3 75% 暂稳,不冲 100%)
> - **优先级**:BOSS 优先(战斗存在感)

---

## §1 4 维 grep audit 结论一句话

⭐ **核心发现**:stages.yaml + towers.yaml 已经预埋 `iconPath: assets/enemies/<id>.png` **60+ 处**(主线 15 关 ~45 敌 + 爬塔 30 层敌),且 **`StageDef.iconPath` + `BattleCharacter` 字段已 parse 入域模型**(`lib/data/defs/stage_def.dart:128,140,156`),**但 widget 层完全没消费 ——** `character_avatar.dart` 仍用「首字 + 流派色边框 CircleAvatar」占位(line 33 自注释)。即 **schema 字段已死写,差最后一公里 widget 接入**。Stage 3 改造 1 个 widget = 激活 60+ enemy iconPath 字段 = BOSS + 普通敌头像全部上线。

→ **Stage 3 ~50 张可拆**:BOSS 立绘 ~22(主线 6 boss + 爬塔 6 boss + 普通敌补 10)/ 场景插画 ~18(主线核心关背景 + 闭关章节首图 + 章节开篇)/ 心法卷轴 ~10(7 阶 cover or 3 流派 cover or 标志性高阶心法)。

---

## §2 4 维 grep 详条

### §2.1 A 维 assets/ 现状(89 张分布)

```
assets/equipment/         70 张  (Stage 2 W1-W6 量产主力)
assets/ui/                10 张  (paper_bg / mountain_bg / scroll_v/h / seal_red / dividers / icons)
assets/maps/               5 张  (闭关 5 地图:shanLin / guJianZhong / cangJingGe / xuanYaPuBu / duanYaJueBi)
assets/characters/         3 张  (founder / first_disciple / second_disciple)
assets/equipment/_alt/     1 张  (Stage 2 备选,未挂 pubspec)
─────────────────────────────────
                          89 张  ✅ Stage 1 PoC 15 + Stage 2 W1-W6 74
```

**Stage 3 新增子目录建议**(全新建):
- `assets/enemies/` — BOSS + 普通敌头像(yaml iconPath 已锚)
- `assets/scenes/` — 场景插画(主线关背景 / 章节开篇)
- `assets/techniques/` — 心法卷轴(7 阶 / 流派 / 标志性招式)

### §2.2 B 维 schema 字段(yaml)

| yaml | 字段 | 状态 | 备注 |
|---|---|---|---|
| `stages.yaml` 60+ 处 | `iconPath: assets/enemies/<id>.png` | ✅ schema 已锚 + parsed | `StageDef.iconPath` 字段已 parse(stage_def.dart:128,140,156),enemyTeam 每 enemy 必填 |
| `towers.yaml` 30+ 处 | `iconPath: assets/enemies/<id>.png` | ✅ schema 已锚 + parsed | 同 stage 体例 |
| `equipment.yaml` 35 处 | `iconPath: assets/equipment/<id>.png` | ✅ 已消费 | `EquipmentDef.iconPath`(equipment_def.dart:20)/ inventory_screen.dart:253 已渲染 |
| `numbers.yaml retreat.maps` | `image_path: assets/maps/*.png` | ✅ 已消费 | 5 闭关地图 seclusion_map_list_screen 已渲染 |
| `techniques.yaml` | **无 image 字段** | ❌ 缺口 | Stage 3 需新增 `imagePath` 字段(可空) |
| `skills.yaml` | **无 image 字段** | ❌ 缺口 | 同上 |
| `narratives/chapters/*.yaml` | **无 image 字段** | ❌ 缺口 | 章节开篇插画需新增 `coverPath` |
| `narratives/stages/*.yaml` | **无 image 字段** | ❌ 缺口 | 关卡场景背景需新增字段 |

### §2.3 C 维 lib widget 接入点(16 处 Image.asset)

| widget | 接入字段 | 现状 |
|---|---|---|
| `splash_screen.dart:56` | `assets/ui/landscape_loading.png` | ✅ 已落 |
| `main_menu.dart:86` | `assets/ui/seal_red.png` | ✅ 已落 |
| `seclusion_map_list_screen.dart:127,275` | maps/*.png(地图缩略 + 详) | ✅ 已落 |
| `recruitment_dialog.dart:274` | characters/*.png(收徒头像) | ✅ 已落 |
| `lineage_panel_screen.dart:74,360` | characters/founder / disciples | ✅ 已落 |
| `technique_panel_screen.dart:47` | ui/paper_bg.png(panel 背景) | ✅ 已落,但**心法本身无图** |
| `home_feed_screen.dart:41` | ui/seal_red.png | ✅ 已落 |
| `equipment_detail_screen.dart:98,118,532` | equipment/<id>.png(典故 + 装备图) | ✅ 已落 |
| `inventory_screen.dart:252,404` | equipment/<id>.png | ✅ 已落 |
| `chapter_list_screen.dart:38` | ui/scroll_horizontal(章节卡背景) | ✅ 已落,但**章节本身无插图** |

**关键缺口**:
- ❌ `battle_screen.dart` **0 Image.asset 调用**(只 `WuxiaColors.background`)
- ❌ `character_avatar.dart` **0 Image.asset 调用**(line 33 自注释「占位用首字 + 流派色边框 CircleAvatar」)
- ❌ `technique_panel_screen` 心法本身无图(只有 paper_bg)

### §2.4 D 维 narrative / lore 联结(场景插画用)

| 来源 | 数量 | 说明 |
|---|---|---|
| `data/narratives/stages/*.yaml` | 39 个 yaml(15 关 × ~2.6 段) | 主线 15 关 × {opening / victory / 章末关 defeat} |
| `data/narratives/chapters/*.yaml` | 章首 + 章末 | 3 章节叙事 |
| `data/narratives/techniques/insights/*.yaml` | techniqueInsight 文案 | 武学领悟招式 narrative |

→ 场景插画可挂接位置:章节开篇 narrative(3 章 ≈ 3 张)/ 关卡 opening narrative(15 关挑核心 6-10 张) / 章末 defeat narrative(章末特定情境 3 张)。

---

## §3 ⭐ sleeper schema 激活机会(本次最大 ROI)

`character_avatar.dart` 97 行,占位 widget 改造 = 1 处 widget 改 = 全局头像系统激活。

**改造路径**:
```dart
// 现状(character_avatar.dart line 33-end):
// 占位用首字 + 流派色边框 CircleAvatar
final firstGlyph = character.name.characters.isEmpty ? '?' : character.name.characters.first;
// CircleAvatar 渲染 firstGlyph + WuxiaColors.schoolColor(character.school) 边框

// Phase 1 改造:
Image.asset(
  character.iconPath,           // ← 已在 BattleCharacter 字段(从 enemy/player def parse)
  width: avatarSize,
  height: avatarSize,
  fit: BoxFit.cover,
  errorBuilder: (_, _, _) => _FirstGlyphAvatar(...),  // ← 现行占位降级为 errorBuilder(memory feedback_image_asset_error_builder)
)
```

**激活范围**:
- 主线 15 关 × ~3 敌 = 45 enemy iconPath(已 yaml 锚)
- 爬塔 30 层 × ~3 敌 = ~90 enemy iconPath(已 yaml 锚)
- **总计 60-90+ 字段一次性激活** ⭐

→ Stage 3 不必产 60-90 张 enemy 图就能完整测试 widget(空文件走 errorBuilder),只产 ~22 张优先 BOSS + 普通敌即可。其他敌人继续走首字占位,后续 Stage 4-5 量产再补。

---

## §4 Stage 3 ~50 张 3 题材拆分建议(BOSS 优先)

### §4.1 BOSS 立绘 ~22 张(题材 1,优先级最高)

**主线 6 BOSS**(章末 4/5 关 isBossStage=true,3 章 × 2 = 6,narrativeDefeatId 已挂):

| stage | 章 | 关 | enemy id | 名 | 数量 |
|---|---|---|---|---|---|
| stage_01_04 | 学武出山 | 第 4 关 boss | enemy_xueTu_gateguard_b | (待 grep 实名) | 1 |
| stage_01_05 | 学武出山 | 章末大 boss | enemy_xueTu_?_b | (待 grep) | 1 |
| stage_02_04 | 武林初识 | 第 4 关 boss | enemy_sanLiu_dock_b | (待 grep) | 1 |
| stage_02_05 | 武林初识 | 章末大 boss | enemy_sanLiu_?_b | (待 grep) | 1 |
| stage_03_04 | 名扬江湖 | 第 4 关 boss | enemy_erLiu_killer_b 等 | (待 grep) | 1 |
| stage_03_05 | 名扬江湖 | 章末大 boss | enemy_erLiu_?_b | (待 grep) | 1 |

**爬塔 6 BOSS**(5/10/15/20/25/30 层):

| floor | bossKind | name | 数量 |
|---|---|---|---|
| 5 | minor | 试剑石老叟 | 1 |
| 10 | major | 黑风寨主 | 1 |
| 15 | minor | 暗夜阁主 | 1 |
| 20 | major | 武林霸主 | 1 |
| 25 | minor | 绝顶剑魔 | 1 |
| 30 | major | 九霄魔尊 | 1 |

**普通敌补 ~10 张**(第 1 章基础敌头像 + 标志性中境界敌,让 character_avatar 改造后低境界关也有面孔):

- xueTu 流民甲/乙/丙(3)+ ruffian 山道伏客 / 闲汉(2)+ bandit 山贼乙/丙 + 头(3)+ qingshan / gateguard 选标志性(2)= ~10 张

**BOSS 题材小计:6 + 6 + 10 = 22 张**

### §4.2 场景插画 ~18 张(题材 2)

| 用途 | 张数 | 接入位 |
|---|---|---|
| 章节开篇插画 | 3(每章 1) | narratives/chapters/ 新增 coverPath 字段 |
| 主线核心关背景 | 9(每章挑 3 标志关) | narratives/stages/ 或 stages.yaml 新增 sceneBackgroundPath |
| 闭关 5 地图章节首图 / 闲庭 | 3-6(可选,maps 已有 5 缩略) | 上层意境插图(非缩略),独立于 maps/ |

**场景小计 ~18 张**

### §4.3 心法卷轴 ~10 张(题材 3)

**选项**(grill 用户拍板,以下任选 1 维度):
- **A 维 7 阶 cover**:每阶 1 张代表卷轴(7 张)+ 3 张顶阶心法名片(传说神功)= 10 张
- **B 维 3 流派 cover**:每流派代表心法 3 张 × 3 = 9 张 + 1 张通用心法封面 = 10 张
- **C 维 标志性高阶心法**:挑 10 个标志性心法(失传神功 / 传说神功 / 门派绝学) — 每个 1 张

**心法小计 ~10 张**

**3 题材合计 22 + 18 + 10 = 50 张 ✅**

---

## §5 schema 缺口 + Phase 1 接入 cookbook

### §5.1 schema 改动(轻量)

| yaml | 新增字段 | 必填? |
|---|---|---|
| `techniques.yaml` | `imagePath: assets/techniques/<id>.png` | ❌ 可空(占位走 paper_bg) |
| `skills.yaml` | `imagePath: assets/techniques/<id>.png` | ❌ 可空 |
| `data/narratives/chapters/*.yaml` 或新增 `data/chapters.yaml` | `coverPath: assets/scenes/chapter_<n>.png` | ❌ 可空 |
| `data/stages.yaml` 或 `data/narratives/stages/*.yaml` | `sceneBackgroundPath: assets/scenes/stage_<id>.png` | ❌ 可空 |
| `pubspec.yaml` flutter.assets | 加 `assets/enemies/` / `assets/scenes/` / `assets/techniques/` | ✅ 必加 |

→ **核心:全部可空,旧 yaml 不破不需要逐条加**;widget 端走 errorBuilder fallback(memory `feedback_image_asset_error_builder`)。

### §5.2 widget 接入(BOSS 优先三步)

**Step 1: character_avatar.dart 改造** ⭐
- 占位 CircleAvatar → Image.asset(character.iconPath, errorBuilder: 现行 CircleAvatar 降级)
- 影响:battle_screen 中所有敌方 / 我方头像
- ROI:1 个 widget 改 = 60-90+ iconPath 字段一次性激活

**Step 2: battle_screen.dart 背景层**(场景插画)
- 加 Scaffold body 底层 Stack + Image.asset(stage.sceneBackgroundPath, errorBuilder: 现 backgroundColor 兜底)
- 影响:战斗屏视觉基调

**Step 3: technique_panel_screen + skill_detail 卷轴层**(心法卷轴)
- technique tile 加 Image.asset(technique.imagePath, errorBuilder: paper_bg 降级)
- 影响:心法面板视觉丰富度

---

## §6 风险 + memory 参考

### §6.1 已知风险

| 风险 | 影响 | 对策 |
|---|---|---|
| widget test 不加载 pubspec assets | character_avatar 改造后 1172 test 部分爆红 | 严格走 errorBuilder fallback(memory `feedback_image_asset_error_builder`)+ test viewport 检查 |
| Image.asset 不存在抛 exception | 改造后没 BOSS 图的关卡 / 心法 / 场景显示错误 | errorBuilder + 测试 fallback path |
| 50 张 PNG 总大小 ~50MB(平均 1MB/张) | release build 体积膨胀 | Stage 3 收口后可选 sharp 压缩 + pubspec assets 子目录细粒度声明 |
| schema 加字段后旧 yaml 缺字段报错 | yaml load 抛 missing key | **全部可空字段**(decode 时 `y['imagePath'] as String?` ?? null) |
| character_avatar 改造影响所有战斗屏 | 视觉验收要求扩到 battle 屏 | Phase 1 完成后 Codex Pen Windows `flutter run -d windows` 视觉验收(memory `feedback_codex_pen_windows_visual_check`) |

### §6.2 memory 参考

| memory | 用途 |
|---|---|
| `feedback_mj_wuxia_prompt_pitfalls` | M4 美术 MJ v7 11 条配方矩阵,Stage 3 用户出图必看 |
| `feedback_mj_url_paste_order` | 用户 4-8 张一批贴 URL,Mac Read 视觉对照不盲信文件名假设 |
| `feedback_image_asset_error_builder` | widget test 不加载 pubspec assets,Image.asset 必加 errorBuilder |
| `feedback_phase0_grep_two_axes` | 本 doc 四维 grep 基线 |
| `feedback_audit_report_phase0_verify` | 三维验证 sleeper schema |
| `feedback_codex_pen_windows_visual_check` | Phase 1 收口可选视觉验收 |
| `feedback_dart_underscore_wildcard` | errorBuilder 参数 `(_, _, _)` Dart 3.7+ wildcard |

---

## §7 决策请求(grill list)

**P0 必决项**(grill 用户):

### G1 BOSS 立绘 22 张是否按推荐拆?

| # | 推荐拆 | grill |
|---|---|---|
| **G1.a** | 主线 6 章末 boss + 爬塔 6 boss + 普通敌补 10 = 22(均衡) | ✅ 推荐(战斗存在感 + 头像系统 PoC 完整) |
| G1.b | 只画 BOSS(主 6 + 塔 6 = 12),普通敌全 errorBuilder 走首字占位 | 节省 10 张工时;但 character_avatar 改造体验不完整 |
| G1.c | BOSS + 大量普通敌(主 6 + 塔 6 + 普通敌 20 = 32)+ 压缩场景/心法 | 头像优先压倒场景/心法 |

### G2 场景插画 18 张接入哪些点?

| # | 拆法 | grill |
|---|---|---|
| **G2.a** | 章节开篇 3 + 主线核心关 9 + 闭关章节首图 6 = 18 | ✅ 推荐(均匀分布主线 / 闭关) |
| G2.b | 只主线 15 关全配 + 3 章开篇 = 18 | 主线视觉饱和,闭关不动 |
| G2.c | 5 闭关意境 + 主线核心 9 + 章节开篇 3 + 留 1 张 BOSS 背景 = 18 | 闭关意境拉满 |

### G3 心法卷轴 10 张取哪种维度?

| # | 维度 | grill |
|---|---|---|
| **G3.a** | 7 阶 cover + 3 标志高阶 = 10(纵深感) | ✅ 推荐(7 阶节奏铺底) |
| G3.b | 3 流派 cover 9 + 1 通用 = 10(横向广度) | 流派对比鲜明 |
| G3.c | 10 个标志性心法各 1 张(失传 / 传说 / 绝学) | 实际游戏内常见心法 |

### G4 schema 字段可空 vs 必填?

| # | 拆法 | grill |
|---|---|---|
| **G4.a** | techniques/skills/scenes 字段全部可空,旧 yaml 不动 | ✅ 推荐(改动最小,渐进式) |
| G4.b | 新字段必填,补全所有 yaml(35 装备 + 21 心法 + 15 关 + 30 塔层) | 一次性收口 schema 完整度,但 50+ yaml 改动 |

### G5 接入顺序 BOSS 优先具体 step?

| # | step 顺序 | grill |
|---|---|---|
| **G5.a** | character_avatar 改造(Step 1) → battle_screen 背景(Step 2) → technique 卷轴(Step 3) | ✅ 推荐(按用户 BOSS 优先信号 + ROI 排序) |
| G5.b | schema 全补字段先(Step 1) → 3 widget 一起改(Step 2) | schema 一次性收口,widget 一起改 |

### G6 用户 MJ 产图节奏?

| # | 拆法 | grill |
|---|---|---|
| **G6.a** | 用户分批出图(每批 8 张 → Mac Read 视觉对照 + 命名归位 → 下一批),~6-7 批 | ✅ 推荐(沿 Stage 2 W1-W6 节奏 + memory `feedback_mj_url_paste_order`) |
| G6.b | 用户一次性出 ~50 张后 Mac 批处理 | 用户 MJ 工时连续 4-6h,fatigue 风险 |

---

## §8 工作量重估(reality check 后)

| 阶段 | 估时 | 谁干 |
|---|---|---|
| Phase 0 reality check | ~30min ✅ | Mac opus(本 doc) |
| Phase 1.a schema 改动(全可空)| ~30min | Mac opus xhigh |
| Phase 1.b character_avatar.dart 改造 | ~40min(含 widget test errorBuilder fallback) | Mac opus xhigh |
| Phase 1.c battle_screen 背景层 | ~30min | Mac opus xhigh |
| Phase 1.d technique 卷轴层 | ~20min | Mac opus xhigh |
| Phase 2 用户 MJ 产图 ~50 张 | ~6-10h 分批 | 用户 MJ |
| Phase 2.b Mac 视觉对照 + 命名归位 | ~2h 分批 | Mac opus + 用户 grill 命中 |
| Phase 3 test + analyze 验证 | ~30min | Mac opus |
| Phase 4 视觉验收(可选)| ~1h | Codex Pen Windows |
| Phase 5 closeout + commit + PROGRESS | ~30min | Mac opus |
| **合计** | **~12-16h(用户 MJ 大头)** | **Mac + 用户** |

→ 远低于 audit doc §5 「多日」估计,主因 sleeper schema 节省了大量 yaml 改动 + widget 新增。

---

## §9 references

- `docs/handoff/art_assets_integration_spec_2026-05-20.md` — Phase 2 接入体例参考
- `docs/handoff/art_assets_integration_closeout_2026-05-20.md` — 89 张 round 1 接入 cookbook
- `docs/handoff/stage_audit_2026-05-21.md` §5 — 候选 1 ROI 表
- `docs/ROADMAP_1_0.md` §P1.3 — 美术线 75% 现状
- `~/.claude/projects/-Users-a10506/memory/feedback_mj_wuxia_prompt_pitfalls.md` — MJ v7 配方 11 条
- `lib/features/battle/presentation/character_avatar.dart:33` — 占位 CircleAvatar 自注释
- `lib/data/defs/stage_def.dart:128,140,156` — iconPath schema 已 parse

---

**Phase 0 完结**。下一步:用户审本 doc + grill G1-G6 6 项,然后 Mac opus 起 Phase 1.a schema 改动 + Phase 1.b character_avatar 改造。
