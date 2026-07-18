# 全 assets 零引用候选重扫

> 扫描日期：2026-07-19
>
> 扫描基线：`796899b8`（立绘专属化盘点提交）
>
> 性质：只读报告；未删除、接线或修改任何资产/代码/配置。

## 结论

- `assets/` 当前共 **530 文件 / 83.761 MiB**，其中图片 **495 张**（494 个 `.png` 路径 + 1 个 `.webp`）。
- 对 `lib/`、`data/`、`pubspec.yaml` 做完整路径字面量扫描后，有 **104 文件 / 24.536 MiB** 没有直接文件路径命中。
- 进一步展开 4 类生产动态约定，排除 **91 文件 / 23.207 MiB**：音频 30、道具图 13、章节封面 8、主线剧情背景 40。
- 最终得到**运行时零引用候选 8 张 / 1.328 MiB（1,392,226 bytes）**。另有 `assets/README.md` 与 4 个 `.gitkeep` 属仓库维护文件，不计图片候选。
- 8 张中 7 张曾在 `lib/` / `data/` / `pubspec.yaml` 被引用后移除，按本单规则统一标注“**疑似目检否决废弃品**”；另 1 张装备 alt 从未进入生产引用，原始集成规格明确记为“归档不用”。本报告只列候选，不作删除或重新接线决定。

## 数据口径

1. 枚举 `assets/` 全部普通文件，读取 `lib/`、`data/` 与 `pubspec.yaml` 全部文本；文件完整仓库路径存在于语料中即为“直接引用”。`pubspec.yaml` 的目录声明只表示会打包，不等同业务消费，因此不把目录下每个文件自动判为已引用。
2. 对无直接命中的文件展开已确认的生产约定：
   - `lib/shared/audio/audio_assets.dart`：`BgmTrack.name`、`SfxId.name` 及 `battleHit_<side>_<slot>.mp3`，覆盖 30 个 MP3；
   - 道具图：`assets/images/items/${defId}.png`，以 `data/items.yaml` 的 `defId` 对应 13 张动态图片；`item_scroll_generic.png` 是直接引用；
   - `chapterCoverPath(chapterIndex)`：当前第 1–8 章对应 8 张 `chapter_<NN>_cover.png`；
   - `stageNarrativePath(stage.id)`：当前 40 个主线 stage 对应 40 张 `narrative_stage_<CC>_<SS>.png`。
3. 候选逐一执行 `git log --all -S'<完整路径>' -- lib data pubspec.yaml`。历史中出现增加后又删除的，依用户口径标“疑似目检否决废弃品”；该标签是待拍板提示，不是对删除原因的事实断言。
4. `test/`、`docs/`、`tool/` 不计生产引用；另行检查后，候选仅在历史/交付文档中出现，没有测试或工具的运行时消费。

## 汇总对账

| 层级 | 文件数 | 体积 | 说明 |
|---|---:|---:|---|
| `assets/` 全量 | 530 | 83.761 MiB | 含图片、音频、维护文件 |
| 完整路径直接命中 | 426 | 59.225 MiB | `lib/` / `data/` / `pubspec.yaml` 字面量 |
| 无直接命中（初筛） | 104 | 24.536 MiB | 尚含动态约定与维护文件 |
| 动态约定有效引用 | 91 | 23.207 MiB | 音频 30 + 道具 13 + 章节封面 8 + 剧情背景 40 |
| 仓库维护文件 | 5 | 0.002 MiB | README 1 + `.gitkeep` 4 |
| **运行时零引用候选** | **8 张** | **1.328 MiB** | 仅列，不删 |

### 动态引用排除明细

| 约定 | 数量 | 体积 | 生产依据 |
|---|---:|---:|---|
| BGM / SFX 枚举和命中音变体 | 30 | 15.329 MiB | `audio_assets.dart` |
| 道具 `defId` → 文件名 | 13 | 1.865 MiB | `items.yaml` + 3 处动态取图 |
| 章节序号 → 封面 | 8 | 1.242 MiB | `chapterCoverPath` + 当前 chapterIndex 1–8 |
| stage id → 剧情背景 | 40 | 4.771 MiB | `stageNarrativePath` + 40 个 mainline stage |

## 零引用候选清单

| 文件 | 体积 | `git log -S` 最后引用史 | 标注 / 拍板提示 |
|---|---:|---|---|
| `assets/characters/battle_founder.png` | 26.6 KiB | `63eb0822`（2026-07-15）接入；`57242282`（2026-07-15）改指 `battle_founder_v2.png` | **疑似目检否决废弃品**；V1 被 V2 替换 |
| `assets/enemies/battle_tower_boss_30.png` | 162.3 KiB | `f29ccef5`（2026-07-16）接入；`7d70ef11`（2026-07-16）改指 `battle_tower_boss_30_v2.png` | **疑似目检否决废弃品**；V1 被 V2 替换 |
| `assets/enemies/guard_b.png` | 201.6 KiB | `df8b539d`（2026-05-21）加入关卡；`e73979ce`（2026-06-28）随敌人定义移除 | **疑似目检否决废弃品**；历史显示阵容删除，未证明图本身破损 |
| `assets/enemies/kunlun_dunke.png` | 124.6 KiB | `4460bdb9`（2026-05-22）加入关卡；`e73979ce`（2026-06-28）随敌人定义移除 | **疑似目检否决废弃品**；历史显示阵容删除，未证明图本身破损 |
| `assets/enemies/songshan_daozong.png` | 331.9 KiB | `a7e23574`（2026-05-22）加入关卡；`e73979ce`（2026-06-28）随敌人定义移除 | **疑似目检否决废弃品**；历史显示阵容删除，未证明图本身破损 |
| `assets/enemies/xiliang_b.png` | 233.5 KiB | `df8b539d`（2026-05-21）加入关卡；`e73979ce`（2026-06-28）随敌人定义移除 | **疑似目检否决废弃品**；历史显示阵容删除，未证明图本身破损 |
| `assets/enemies/zhongzhou_lunjian.png` | 230.5 KiB | `a7e23574`（2026-05-22）加入关卡；`e73979ce`（2026-06-28）随敌人定义移除 | **疑似目检否决废弃品**；历史显示阵容删除，未证明图本身破损 |
| `assets/equipment/_alt/01_tie_jian_icon_alt.png` | 48.5 KiB | `git log -S` 无生产引用记录 | 从未接线；`docs/handoff/art_assets_integration_spec_2026-05-20.md` 明记“归档不用” |

## 维护文件（不计图片候选）

| 文件 | 体积 | 处理 |
|---|---:|---|
| `assets/README.md` | 1,663 bytes | 资产说明文档，保留 |
| `assets/audio/bgm/.gitkeep` | 0 | 目录占位，保留 |
| `assets/audio/sfx/.gitkeep` | 0 | 目录占位，保留 |
| `assets/enemies/.gitkeep` | 0 | 目录占位，保留 |
| `assets/scenes/.gitkeep` | 0 | 目录占位，保留 |

## 与 2026-07-02 旧审查的关系

- 旧审查曾报 67 文件 / 44.9 MiB；`docs/spec/full_review_2026-07-02_followup_backlog.md` 已记录 2026-07-03 实际清理 59 文件 / 8.0 MiB，并说明旧体积受 WebP 转码与清理时点漂移影响。
- 本次从当前树重新枚举，不继承旧清单。当前剩余仅 8 张 / 1.328 MiB；其中两个 V1 立绘在 2026-07-15/16 才接入后被 V2 替换，属于旧审查之后的新遗留。

## 残留风险

- 动态引用识别基于当前代码中的四种明确命名约定；未来若存在反射、远端清单或未入库生成器，本扫描无法感知。当前仓库搜索未发现这些机制。
- “疑似目检否决废弃品”是按历史移除统一打标：两个 V1→V2 很可能是视觉替换，五个旧敌则是关卡阵容被删，不能据此断言素材质量不合格。
- `pubspec.yaml` 仍按目录打包这 8 张，因此若不处置会继续进入产物；本单没有测量最终 bundle 的压缩后边际体积。

## 复核摘要

- 全量枚举：530 文件 / 87,829,439 bytes。
- 直接扫描：426 命中，104 未命中。
- 动态展开：91 有效，8 图片候选，5 维护文件。
- 候选历史：7 曾引用后移除，1 从未生产接线。
- 边界：报告之外零变化；零资产、零 Dart、零 data、零 pubspec 改动。
