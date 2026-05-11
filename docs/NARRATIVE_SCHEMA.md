# NARRATIVE_SCHEMA.md · 主线/章节剧情 yaml 格式约定

> **领域**：DeepSeek 端写 `data/narratives/` 下的剧情文案文件时遵循的格式约定。
> Mac 端不写这个目录的任何文件（CLAUDE.md §3 文件类型隔离）。
> Mac 端在 `lib/data/narrative_loader.dart` 维护此 schema 的解析逻辑。
>
> **版本**：v0.1.0（Phase 3 T36/T38 落地）

---

## 1. 文件命名

每个剧情段对应一个独立 yaml：

```
data/narratives/<narrativeId>.yaml
```

`narrativeId` 必须等于文件名（不含 `.yaml` 后缀），且与 `data/stages.yaml` 中
对应字段严格一致：

| stages.yaml 字段 | narratives/ 文件名 | 触发时机 |
|---|---|---|
| `narrativeOpeningId` | `data/narratives/<id>.yaml` | 进入关卡前播放 |
| `narrativeVictoryId` | `data/narratives/<id>.yaml` | 战斗胜利后播放（战败不触发） |

**示例（来自 Phase 3 stages.yaml T33 backfill）**：

```yaml
# data/stages.yaml （Mac 写）
- id: mainline_test_01
  name: 山道试剑
  ...
  narrativeOpeningId: mainline_test_01_opening   # → data/narratives/mainline_test_01_opening.yaml
  narrativeVictoryId: mainline_test_01_victory   # → data/narratives/mainline_test_01_victory.yaml
```

```
data/narratives/
├── mainline_test_01_opening.yaml   # ← DeepSeek 写
├── mainline_test_01_victory.yaml   # ← DeepSeek 写
├── mainline_test_02_opening.yaml
├── mainline_test_02_victory.yaml
...（共 6 关 × 2 段 = 12 个）
```

---

## 2. yaml schema

```yaml
id: mainline_test_01_opening   # 必填，必须等于文件名（不含 .yaml）
title: 山道试剑                 # 选填，缺省时 UI 用 stage.name 兜底
paragraphs:                    # 必填，按顺序播放
  - 山雾未散，你立于青石之上，手按腰间长剑。
  - 林梢三声鸟啼，三道身影自雾中浮现……
  - 「初出茅庐的小子，懂规矩么？」
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | 必须等于文件名（不含 `.yaml`） |
| `title` | string | 选 | 标题；缺省时 UI 用 `stage.name` 兜底 |
| `paragraphs` | List\<string\> | ✅ | 段落数组；UI 一段一页推进 |

**约束建议**（Demo 阶段）：

- 单段长度 60-200 字（避免单页太长，玩家需要滚动）
- 总段数 3-8 段（避免节奏拖沓）
- 不写 `<br>` / `\n` 等转义；段间换页由 UI 处理
- 不引入「选项」「分支」字段（Demo 阶段所有剧情是线性，分支留 Phase 5+）

---

## 3. 数据 ↔ 文案隔离原则（GDD §8.1）

- `data/stages.yaml`（Mac 维护）只放数值 + 触发条件（`enemyTeam` / `dropTable`
  / `narrativeOpeningId` 等 id 引用）
- `data/narratives/<id>.yaml`（DeepSeek 维护）只放剧情文本
- **两侧不互相读对方字段**：剧情 yaml 不读 `enemyTeam`，stages yaml 不读
  `paragraphs`
- 同样原则适用：装备 (`equipment.yaml` ↔ `data/lore/<id>.yaml`)、奇遇
  (`encounters.yaml` ↔ `data/events/<id>.yaml`)

---

## 4. 缺文件 / 损坏的兜底行为

`NarrativeLoader.load(narrativeId)` 在以下 3 种情况返回 placeholder（**不抛异常**）：

1. yaml 文件不存在（DeepSeek 还没写）
2. yaml 解析失败（语法错误）
3. yaml 顶层非 map（结构错误）

placeholder 内容：

```
id: <narrativeId>
title: null
paragraphs: ["[剧情待补：<narrativeId>]"]
isPlaceholder: true
```

UI 行为（`NarrativeReaderScreen`）：

- 顶部显示弱提示「⚠ 剧情占位（DeepSeek 待补）」
- 段落区显示 `[剧情待补：<id>]`
- 「继续/完成」按钮正常工作（流程不卡）

**为什么不 fail-fast**：narratives 是文案层，DeepSeek 异步补，**运行期不能挂**。
区别于 `GameRepository` 的 fail-fast：那是数值/配置层（红线校验在启动期一次性
做完）。

---

## 5. Phase 3 Week 1 待写清单

DeepSeek 端按本 schema 完成以下 12 个文件（不强制 Week 1 完成；Mac 端
NarrativeLoader 兜底保证未写时 UI 不挂）：

```
data/narratives/
├── mainline_test_01_opening.yaml      第一章 山道试剑（开场）
├── mainline_test_01_victory.yaml      第一章 山道试剑（胜利）
├── mainline_test_02_opening.yaml      第一章 林间伏击（开场）
├── mainline_test_02_victory.yaml      第一章 林间伏击（胜利）
├── mainline_test_03_opening.yaml      第二章 镖局护送（开场）
├── mainline_test_03_victory.yaml      第二章 镖局护送（胜利）
├── mainline_test_04_opening.yaml      第二章 黑风寨（开场）
├── mainline_test_04_victory.yaml      第二章 黑风寨（胜利）
├── mainline_test_05_opening.yaml      第三章 武林会（开场）
├── mainline_test_05_victory.yaml      第三章 武林会（胜利）
├── mainline_test_06_opening.yaml      第三章 一战封王（开场）
└── mainline_test_06_victory.yaml      第三章 一战封王（胜利）
```

**章节背景**（DeepSeek 自由发挥；Mac 端的 `lib/ui/strings.dart` 已写 章节标题
+ 简介，DeepSeek 端可参考但不必引用）：

| 章节 | 标题 | 简介 |
|---|---|---|
| 第一章 | 学武出山 | 初出茅庐，山道试剑、林间伏击 |
| 第二章 | 武林初识 | 镖局护送、黑风寨剿匪 |
| 第三章 | 名扬江湖 | 武林会、一战封王 |

---

## 6. 写完后的验证（Pen 端）

1. yaml 文件 commit + push 到 main
2. Mac 端会在 Phase 3 Week 1 收尾（T39）跑视觉验收，截图你写的剧情显示效果
3. 后续 Pen 端如有反馈（节奏 / 长度 / 字数），可在 PROGRESS.md「已知偏差」段
   记录，下个 Phase 一并调整

