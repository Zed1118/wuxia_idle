# D · 四类养成进度「五要素」标准化展示

> 2026-06-12 · 1.0 长线打磨期 · P1b 唯一未完项收口
> **纯 UX**：零数值 / 零 schema / 零规则层改动。所有展示数据从现有 domain/config 派生。

## 背景与真痛点

四类可量化养成进度的玩家可见性参差：

| 进度类型 | 现状 | 五要素缺口 |
|---|---|---|
| 熟练度 `SkillProficiencyRow` | 完整 Row（藏经阁） | 无 ✅（参考样板） |
| 残页 `FragmentProgressRow` | 有 Row（藏经阁） | 收集进度，**天然无阶段/效果** |
| 共鸣度 | 数据完整但散成纯文字（`equipment_detail._ResonanceDetailsSection`） | 未成 Row |
| 修炼度 | 阶段名 + 进度条（character/technique panel） | **缺「当前效果/下一阶效果」倍率文案** |

**真痛点**：① 修炼度玩家看不到「修炼带来的伤害倍率」（最大缺口）；② 共鸣度数据散落不成 Row、与其余视觉不一致。

「五要素」= 当前阶段 + 进度 + 当前效果 + 下一阶段效果 + 来源/标记。

## 方向（已与用户确认 = A 标准化模式，原地补齐）

不强抽 domain-aware 通用组件（残页不符模子、四类数据类型不同、跨屏）。改为：固化一个**纯表现层布局基元**，各 screen 原地复用，喂已格式化字符串。

## 架构

### ① 布局基元 `StageProgressRow`（新建）

`lib/shared/widgets/wuxia_ui/stage_progress_row.dart` —— 哑组件，**不认任何 domain 类型**，只接收已格式化字符串 + 进度比率：

```
StageProgressRow({
  required String title,        // 招名/心法名/装备名
  String? stageName,            // 当前阶段名；null = 无阶段（残页式退化，不渲染阶段/效果行）
  required double ratio,        // 0~1，喂 MeridianBar
  String? progressText,         // "还需 120 次" / "1840/2000 战"
  String? currentEffect,        // "伤害 +30%" / "伤害 ×1.75"
  String? nextEffect,           // "下一阶 +50%" / "已至极境"
  String? tag,                  // 装配标 / 来源文案
  bool tagHighlighted,          // 装配标用青底高亮，来源文案用 muted
  VoidCallback? onTap,
})
```

视觉骨架沿用现有 `SkillProficiencyRow` 三行结构：① 标题行（title 占宽 + stageName 青字 + 可选 tag）② `MeridianBar(ratio)` ③ 效果行（currentEffect ↔ nextEffect/progressText）。复用 `WuxiaUi` token + `MeridianBar`。`stageName==null` 时退化为「标题 + 进度条 + 来源」两段式（承载残页语义）。

### ② 熟练度 `SkillProficiencyRow` 重构到基元（子决策 a，已确认）

内部布局改为 `StageProgressRow` 实例，**外部构造参数与可见文案不变**（阶段名 / `+N%` / 还需次数 / 装配标）→ 四类真正像素一致 + 去重。现有 widget test 断言可见字符串，重构保留 → 风险低。

### ③ 修炼度 Row（补效果文案 · 两处都补，已确认）

数据：`NumbersConfig.cultivationMultiplier[layer]`（9 层 1.00→3.00 伤害倍率）+ `Technique.cultivationLayer/cultivationProgress/cultivationProgressToNext` + `EnumL10n.cultivationLayer`。

- 当前效果：`伤害 ×1.75`（`cultivationMultiplier[layer]`）
- 下一阶效果：`下一阶 ×2.00`（`cultivationMultiplier[nextLayer]`）；极境无下一阶 → `已至极境`
- 进度：`cultivationProgress / cultivationProgressToNext`

落点：
- `character_panel._MainTechniqueTile`（主修心法卡，玩家最常见）→ 现有修炼度块换 `StageProgressRow` 完整五要素。
- `technique_panel._LayerLadder`（9 层阶梯图）→ 保留 ladder 视觉，仅在层名徽章下补一行倍率文案（`当前 ×1.75 · 下一阶 ×2.00`），不替换阶梯。

新增文案走 `UiStrings`（§5.6 不硬编码中文）。

### ④ 共鸣度 Row（抽取 · 已确认）

`equipment_detail._ResonanceDetailsSection` 现有散文字数据（当前加成% / 解锁人剑合一 / 剑鸣 / 距下阶战斗数）抽成一个 `StageProgressRow` 实例，留原位：

- 阶段名：`EnumL10n.resonanceStage(stage)`（生疏/趁手/默契/心剑通灵）
- 进度：`battleCount` 在当前阶 [min, nextMin] 内的比值；最高阶 ratio=1
- 当前效果：`伤害 +20%` + 解锁标记（默契解锁人剑合一 / 心剑通灵剑鸣）
- 下一阶效果：`下一阶 +30%`
- 来源：`战斗 N/2000 次`（progressText）

### ⑤ 残页 `FragmentProgressRow`（仅视觉对齐）

保持收集态语义（方块进度 + 来源），仅微调字号/间距/来源行与基元协调，**不强塞五要素**。若改动微小可只对齐 token，不强制改结构。

## 数据可得性

四类的五要素全部可从现有 domain/config 派生，**无 yaml/schema 改动**。新增仅：① 一个表现层 widget；② 几条 `UiStrings` 文案 helper（修炼度倍率 / 共鸣度下一阶 / 解锁标记）。

## 红线 / 约束

- 零 numbers.yaml / 零 schema / 零规则层（§5.4 数值红线天然不触及，纯展示）。
- §5.6 不硬编码：所有中文走 `UiStrings`，倍率数字从 config 读。
- 沿用 `WuxiaUi` 水墨 token，不引 Material 饱和色。

## 闸门

- 全量测试维持绿（基线 1983）+ analyze 0。
- 新增 `StageProgressRow` widget test：五要素全渲染 / `stageName==null` 残页退化 / `onTap` / ListView viewport 扩（`setSurfaceSize` 见 memory `feedback_listview_widget_test_viewport`）。
- 修炼度 Row + 共鸣度 Row 各 1 文案断言测（倍率文案 / 下一阶文案 / 极境与心剑通灵最高阶退化）。
- 熟练度重构后现有 widget test 必须仍绿（可见文案不变）。
- 合 main 前派 Codex 1280×720 看四类一致性（沿现有验收流）。

## 非目标（YAGNI）

- 不做「成长总览」聚合新 screen（B/C 方向已否）。
- 不抽 domain-aware 泛型组件。
- 不改残页的收集态语义。
- 不动战斗/数值/解锁逻辑。
