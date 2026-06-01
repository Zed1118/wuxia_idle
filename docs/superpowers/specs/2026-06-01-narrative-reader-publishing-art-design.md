# 剧情阅读屏出版美术 设计（narrative_reader publishing art）

**日期**：2026-06-01 · **状态**：待 plan
**目标**：给主线剧情阅读屏 `NarrativeReaderScreen` 加出版美术——专属水墨场景图背景 + scrim + 正文浮层装帧，把"纯文字阅读区"升级为出版级观感。沿 B1/B2 + chapter_transition 既有体例，**接线基建 0 出图先行，MJ 图后补**。

## 范围

- **本波只主线 30 关**（`stage_01_01 … stage_06_05`，6 章 × 5），per-stage 一张专属背景，该关 opening/victory/defeat 三段剧情共用。
- 爬塔 / 飞升 / 招降 / 心魔等其余 `NarrativeReaderScreen` 调用方**不传图 → 走纯色底兜底**，后续波次再定。
- **30 张 MJ 图由用户出**；我负责接线 + 装帧 + TDD + 验收路由 + MJ prompt 清单。

## 接线方案（A：调用方传图 + 通用屏加可选参数）

最小侵入，与现有三体例一致（`topBanner` 可选参数 / `chapterCoverPath` helper / `BattleSceneBackground` errorBuilder）。

```dart
// 新 helper（追加到 lib/features/mainline/domain/chapter_assets.dart，与 chapterCoverPath 同列）
String stageNarrativePath(String stageId) => 'assets/scenes/narrative_$stageId.png';

// NarrativeReaderScreen 加可选参数（沿 topBanner 体例）
const NarrativeReaderScreen({..., this.backgroundImagePath});
final String? backgroundImagePath;

// stage_entry_flow.dart 三处调用（opening / victory / defeat）传：
backgroundImagePath: stageNarrativePath(stage.id),
```

- 其余调用方（tower_entry_flow / ascension_screen / stage_boss_recruit_hook）**不传** → null → 兜底纯色底。
- 命名约定：`assets/scenes/narrative_<stageId>.png`（如 `narrative_stage_01_01.png`）。

## 装帧设计（沿 BattleSceneBackground 体例）

1. **背景层**：新建 `NarrativeSceneBackground`（仿 `battle_scene_background.dart`）——`path` 空 → `SizedBox.shrink()`；否则 `Stack(fit:expand)`：`Image.asset(BoxFit.cover, errorBuilder→shrink)` + scrim `ColoredBox`。Scaffold body 底层。
2. **scrim**：先复用 `WuxiaColors.battleSceneScrim`；若长正文可读性不足，加 `narrativeSceneScrim`（≈0.5，比战斗略重）。**先看效果再调**（验收时定）。
3. **正文浮层**：正文 + 进度/按钮区包一层半透明墨底 `Container`（`WuxiaColors.background.withValues(alpha: ~0.55)` + 圆角 + padding），提升图上长文可读，不被背景花纹干扰。
4. **保留不动**（语义全不改）：G4 轻点推进 / 跳过按钮（mandatory 隐藏）/ 占位提示 / `topBanner` / 进度 `n/N` / 继续按钮。
5. **兜底**：图未到位 → errorBuilder shrink → 退回现状 `WuxiaColors.background` 纯色底。**不破布局、不破 widget 测**（assets 不在测试加载）。

## 接口契约（可独立测试的单元）

| 单元 | 职责 | 依赖 |
|---|---|---|
| `stageNarrativePath(stageId)` | stageId → asset 路径，纯函数（chapter_assets.dart） | 无 |
| `NarrativeSceneBackground(path)` | 背景图 + scrim 层，path 空/缺图安全降级 | WuxiaColors |
| `NarrativeReaderScreen(backgroundImagePath)` | 可选背景，缺省=现状纯色底 | 上两者 |

## 测试计划

- `stageNarrativePath` 单测：id → 路径正确（含 30 关任取样）。
- `NarrativeSceneBackground` widget 测：path=null → shrink；path 给值 → 含 Image + scrim（errorBuilder 守不加载真图）。
- `NarrativeReaderScreen` 回归：不传 backgroundImagePath 时与现状一致（G4 轻点 / 跳过 / 进度 / 继续 / topBanner / 占位 全过）；传 path 时 body 多一层背景不破布局。
- 全量 `flutter test` + 0 analyze（改 reader 必跑全量，沿 B1/B2 教训）。

## 验收路由（Codex 视觉验收）

新增 `VisualRoute.narrativeScene`（id `narrative_scene`）：渲染 `NarrativeReaderScreen` 带某 stage 的 `backgroundImagePath` + 一段长占位文案。**即使图未到位也能验** scrim 深浅 / 正文浮层可读性 / 兜底纯色底不破。图到位后复验背景题材对位。

## MJ 出图清单（30 张 · prompt 在 plan/单独 prompt 文档产出）

prompt 方向（沿 `feedback_mj_wuxia_prompt_pitfalls`）：水墨厚涂 / **16:9 横构图作背景** / **中间留暗区/留白给正文浮层** / 低饱和青墨宣纸调 / 无人物主体（场景为主）/ 与该关 biome + 剧情题材对位。

| stage | biome | 场景 | stage | biome | 场景 |
|---|---|---|---|---|---|
| 01_01 | mountainForest | 山门之外 | 04_01 | mountainForest | 阳关初渡 |
| 01_02 | inn | 荒山野店 | 04_02 | frontier | 古道行商 |
| 01_03 | mountainPath | 黑风岭 | 04_03 | desert | 沙海迷踪 |
| 01_04 | cityWall | 洛阳城外(B) | 04_04 | drillGround | 西凉论剑(B) |
| 01_05 | dock | 风雨渡口(B) | 04_05 | frontier | 阳关一决(B) |
| 02_01 | escortRoad | 镖局护送 | 05_01 | mountainForest | 渭水东渡 |
| 02_02 | teaHouse | 茶馆论剑 | 05_02 | temple | 嵩山道观 |
| 02_03 | smithy | 春水堂 | 05_03 | dock | 黄河义渡 |
| 02_04 | drillGround | 城外校场(B) | 05_04 | drillGround | 中州论剑(B) |
| 02_05 | alley | 巷中夜雨(B) | 05_05 | cityWall | 嵩山一决(B) |
| 03_01 | cityWall | 武林会 | 06_01 | cityWall | 论剑散场 |
| 03_02 | drillGround | 许昌擂台 | 06_02 | mountainForest | 嵩山再访 |
| 03_03 | temple | 山寺夜话 | 06_03 | dock | 黄河之源 |
| 03_04 | mountainPath | 雁门旧事(B) | 06_04 | desert | 昆仑山外(B) |
| 03_05 | drillGround | 一剑封名(B) | 06_05 | mountainForest | 昆仑山顶(B) |

## 分工（并行，基建先行）

- **我**：helper + `NarrativeSceneBackground` + reader 加参数 + `stage_entry_flow` wire + 兜底 + TDD + 验收路由 + 30 条 MJ prompt（单独 prompt 文档）。基建先合（缺图绿测）。
- **你**：跑 30 张 MJ → 归位 `assets/scenes/narrative_stage_XX_XX.png`（oxipng/pngquant 压缩）→ Codex 验收。
- 不互相阻塞：图回来即显。

## 不做（YAGNI）

- 支线（爬塔/飞升/招降/心魔）背景图（本波纯色底兜底）。
- per-段落不同图（一关一图，三段共用）。
- yaml 数据驱动 backgroundImage 字段（方案 B，过重）。
- 题字标题特殊字体 / 立绘 / 对话气泡（出版美术后续可选，本波聚焦背景装帧）。
