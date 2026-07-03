# 祖师 / 门派命名 · 设计

**日期**：2026-07-03 · **状态**：已拍板，待写 plan · **saveVer**：不变（0.33.0）

## 背景

「祖师创建页」7 项 backlog（`playability_phase2_backlog.md §十二`）经 Phase 0 探查确认 **6/7 已于 2026-06-27（commit `c967a959`·saveVer 0.33.0）完整实装**：流派三选 / 三份命盘 / 出身四选 / 交互式创建页 / 属性预览 / 履历写档案。backlog 把已做项列成待做属长寿文档 drift（`feedback_living_doc_state_drift`）。

**唯一缺口 = 第 ⑦ 项：给祖师和门派取名**。当前 `master_builder.dart:69` 硬编码「祖师」、`onboarding_service.dart:139` 门派名默认「我的门派」，创建页（`founder_creation_screen.dart`）无任何 `TextField`。本 spec 补齐这最后一块。

## 范围

**做：**
- 创建页底部加「名号」段：祖师名 + 门派名两输入框，各带「掷个名号」随机按钮
- 新增武侠名库 `data/founder_names.yaml`（组件式：姓+名 / 前缀+后缀，小 yaml 撬大变体）
- 输入接进已有字段：祖师名→创建的祖师 `Character.name`；门派名→`SaveData.sectName`
- 主菜单顶部加门派名横幅（`sectName` 当前**只存不显**，取名必须连带补显示才有意义）

**不做（YAGNI / 守假设）：**
- 不改旧档、不做追溯改名（旧档保持「祖师/我的门派」）
- 不给弟子取名（弟子仍默认名，属另一未来项）
- 不做重名校验（单机买断无必要）

## 数据层：`data/founder_names.yaml`

组件式，内容交 wuxia-content skill 产：

```yaml
founder_surnames: [慕容, 令狐, 独孤, 上官, 东方, 西门, ...]   # 姓池
founder_given:    [无咎, 惊鸿, 玄机, 拂尘, 问天, ...]          # 名池
sect_prefixes:    [青城, 昆仑, 天山, 桃花, 听雨, 落霞, ...]    # 门派前缀（地名/意象）
sect_suffixes:    [派, 门, 山庄, 阁, 洞, 观, ...]              # 门派后缀
```

「掷个名号」= 随机组合（祖师名 = 姓+名；门派名 = 前缀+后缀）。加载走现有 `game_repository.loadAllDefs()` 同款 `fromYaml`，无 schema 硬校验（与 `founder_creation.yaml` 一致）。随机走项目 `rngProvider` 而非裸 `dart:math`（守确定性测·`feedback_wuxia_rngprovider_vs_dartmath_random`）。

## UI：名号段

- 新增 `_Section(title: '四 · 立名号')`，内含 2 个 `TextField` + 各一「掷个名号」IconButton（刷新/骰子图标）
- 深底配色沿用 `WuxiaColors`（创建页深底）；复用现有 `_Section` 体例
- 中文文案全进 `UiStrings`（沿用 `founderCreateXxx` 前缀），不散写

## 接线 + 约束

- `FounderCreationSelection` 加 `founderName` / `sectName` 两字段；`_confirm()` 透传
- `createFoundingMaster()` 用输入值替代 `defaultMasterName()` / `defaultSectName`
- **留空 → 回退默认**（祖师/我的门派）：确认按钮永远可点，不强制输入
- **约束**：去首尾空白；纯空白视作留空；`maxLength` 祖师名 ≤ 8 字 / 门派名 ≤ 12 字（护 UI 不溢出）

## 关键：无 schema 改动

祖师名进 `Character.name`（已有）、门派名进 `SaveData.sectName`（已有）——两字段本就存在，只是被默认值填充。故 **不改 Isar schema、不 bump saveVer、旧档零影响**。

## 主菜单门派横幅

主菜单顶部读当前存档 `SaveData.sectName` 显示成横幅。实现时先核实主菜单能否拿到 active `SaveData`；若无现成 provider，补一个**只读** provider（不碰写路径）。留空档（旧档）显示「我的门派」默认值。

## 测试

- `founder_names.yaml` 解析测（4 池非空、类型正确）
- 「掷个名号」组合合法性（非空、在长度上限内）
- 接线测：输入名 → `createFoundingMaster` → 祖师 `Character.name` / `SaveData.sectName` 落值；留空 → 回退默认
- widget 测：名号段渲染 + 掷名按钮填入 + 主菜单横幅显门派名
- 节奏：接线碰存档写路径属跨切面，批末跑全量（默认并发·§8.0）

## 拍板决策记录

| 决策 | 选择 | 备选（已否决） |
|---|---|---|
| 输入位置 | 底部内联 `_Section`（预览后·确认前） | 顶部 / 确认时弹框 |
| 随机取名 | 空白 + 「掷个名号」按钮 + 名库 yaml | 纯空白 / 预填随机可改 |
| 门派名显示 | 主菜单顶部横幅 | 存档槽列表 / 角色面板 |
| 留空行为 | 回退默认 | 强制输入 |
| 长度上限 | 祖师名 8 / 门派名 12 字 | — |
| 名库结构 | 组件式（姓+名 / 前缀+后缀） | 整名平铺列表 |
| 工作假设 | 仅创建时命名 / 不改旧档 / 弟子默认名 | — |

## 验收标准

1. 新档创建页底部可输入祖师名 + 门派名，「掷个名号」按钮能填入合法武侠名
2. 输入名落进祖师 `Character.name` 与 `SaveData.sectName`；留空回退默认
3. 主菜单顶部显示门派名横幅
4. 不改 saveVer；旧档启动零影响、原名保持
5. 中文全进 `UiStrings`；名库走 yaml；随机走 `rngProvider`
6. `flutter analyze lib/ test/` 0 issue；相关测试 + 批末全量绿
