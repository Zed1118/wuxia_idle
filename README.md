# 挂机武侠 · wuxia_idle

> 买断制、写实武侠挂机游戏。Flutter Desktop，3v3 自动战斗 + 离线挂机。
> **发布目标：Windows**（开发与验收在 macOS）。当前处于 **1.0 长线打磨期**（质量优先，不设上线时间压力）。

一款不走网游套路的武侠挂机游戏：**没有体力 / 每日任务 / 登录奖励 / 抽卡 / VIP**。关游戏 8 小时回来，等于一直挂着 8 小时——挂机就是挂机。玩家扮演一派祖师，从学徒一路修行至武圣，靠境界、心法、装备三系同步精进，以自动战斗闯主线、爬塔、闭关、飞升传承。

---

## 目录

- [核心玩法](#核心玩法)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [测试](#测试)
- [设计红线](#设计红线)
- [文档索引](#文档索引)
- [协作与仓库](#协作与仓库)

---

## 核心玩法

**七阶节奏（统一锚点）** — 所有可量化进阶系统共用同一套 7 阶，三系一一锁死、不可破：

| 系 | 七阶 |
|---|---|
| 境界 | 学徒 / 三流 / 二流 / 一流 / 绝顶 / 宗师 / 武圣（每阶 7 层 → 49 级） |
| 装备阶 | 寻常货 / 像样货 / 好家伙 / 利器 / 重器 / 宝物 / 神物 |
| 心法阶 | 入门功 / 常练功 / 名家功 / 门派绝学 / 江湖秘传 / 失传神功 / 传说神功 |

> **三系锁死**：境界 ↔ 装备阶 ↔ 心法阶严格对应。二流境界 → 最多装备「好家伙」、最多修「名家功」。低境界不可能使用更高阶装备/心法（师承遗物也不例外，可携带不可装备，等境界到了自动解锁）。

**三流派克制** — 刚猛 `rigid` / 灵巧 `agile` / 阴柔 `sinister`，克制系数 0.75 / 1.0 / 1.25，另有相生组合。

**战斗** — 地面 3v3 自动战斗（半手动可介入）+ 轻功对决 + 群战守城 + 心魔试炼。伤害走统一公式：

```
基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
最终伤害 = 基础伤害 × 心法修炼度(1.0~3.0) × 流派克制 × 暴击 × (1 - 防御率) × 境界差距修正
```

**成长支柱** — 修炼度 9 层、共鸣度（人剑合一）、开锋（3 槽 build）、装备强化/出售/分解、师徒传承与多代飞升、武学领悟（替代抽卡）、时间锚点闭关、桃花岛养成经营。

**内容量（Demo 里程碑 14/14 全达标，现为 1.0 打磨基线）** — 3 章主线 15 关 + 30 层爬塔（3 小 Boss + 3 大 Boss）+ 5 闭关地图 + 30-50 装备 + 20-30 心法 + 50-80 段典故 + 第二条主线 Ch4-6 + 江湖恩怨/声望/帮派门派等扩展系统。

---

## 技术栈

| 层 | 选型 | 版本 / 备注 |
|---|---|---|
| 引擎 | Flutter Desktop | 发布目标 Windows；开发/验收在 **macOS**（Isar 无 web target） |
| 语言 | Dart | SDK `^3.11.3` |
| 状态管理 | Riverpod 3.x | `flutter_riverpod ^3.0.0` + `riverpod_annotation ^4.0.0` + 代码生成 |
| 本地存储 | Isar（`isar_community` fork） | `^3.3.2`（fork 解 analyzer 上限）；角色/装备/进度/存档 |
| 云端 | Supabase + Edge Function | **仅**排行榜，不做账号同步 |
| 战斗表现 | 纯 Flutter Widget + AnimationController | 不引入 Flame 等游戏引擎 |
| 配置/文案 | YAML | 数值 `data/*.yaml` + 剧情 `data/narratives|lore|events` |
| 音频 | `audioplayers ^6.0.0` | bgm / sfx |
| 窗口 | `window_manager ^0.5.1` | 桌面窗口管理 |
| 打包 | MSIX，内测先发 itch.io | — |

代码生成依赖：`build_runner ^2.4.0` + `isar_community_generator` + `riverpod_generator`（生成 Isar schema 与 Riverpod provider 的 `*.g.dart`）。

---

## 项目结构

```
project_root/
├── CLAUDE.md          # AI 协作操作规范（启动必读）
├── GDD.md             # 主设计文档（设计层唯一真相源）
├── PROGRESS.md        # 开发进度跟踪
├── data_schema.md     # 所有 Dart model 字段定义规范
├── IDS_REGISTRY.md    # id 注册表
├── content_guide.md   # 文案写作技法指引
├── lib/
│   ├── core/          # 公式、常量、领域模型（纯 Dart，无 Flutter 依赖）
│   ├── data/          # yaml 加载、Isar 仓储、Supabase 客户端
│   ├── features/      # 按功能切分（battle / equipment / cultivation / tower / taohua_island / ... 共 40+ 模块）
│   │   └── <feature>/{domain,application,presentation}/
│   ├── shared/        # 跨 feature 复用（主题、组件、UiStrings）
│   └── main.dart
├── data/              # 全部配置与文案（452 个 yaml，数值 + narratives/lore/events）
├── assets/            # 图片、字体、音频（AI 产出）
├── test/             # 单元 + golden + 平衡红线测试（553 个测试文件）
└── docs/             # 设计 spec、审查报告、交接记录、归档
```

分层约定：`core/` 纯 Dart 领域层（公式集中在 `lib/features/battle/domain/`，系数全读 `numbers.yaml`）；`features/<x>/` 按 domain → application(Notifier) → presentation(Widget) 三段切分。

---

## 快速开始

> **前置**：Flutter SDK（含 Dart `^3.11.3`）、macOS（开发端）。

```bash
# 1. 拉取依赖
flutter pub get

# 2. ⚠️ 必跑：生成代码
#    .g.dart 不入库（fresh checkout / 新 worktree 都要先跑），
#    否则 Isar schema 与 Riverpod provider 缺失，编译失败。
dart run build_runner build

# 3. 运行（Isar 无 web target，开发端只用 macOS）
flutter run -d macos
```

全屏快捷键用 **Alt+Enter**（F11 被 macOS 系统占用）。

---

## 测试

```bash
# 全量（默认并发，10 核约 2.5 分钟）
flutter test --no-pub

# 排查隔离型 flaky 时才用串行
flutter test --no-pub -j1

# 静态分析（0 issue 为准）
flutter analyze lib/ test/
```

测试体系（553 个测试文件）分三类：**单元测试**（公式/service/仓储）、**widget 测试**（各屏交互与桌面语义）、**平衡红线测试**（`test/data/` + `test/balance/` + `test/tools/` 的极值模拟与数值红线守卫，防数值膨胀越界）。

> 代码改动的测试节奏：自包含改动只跑 targeted + analyze；跨切面改动（numbers/结算/schema/迁移）或批末合并才跑全量。

---

## 设计红线

> 这些是底线。实现任何功能若与之冲突，**停下与人确认**，不自作主张折中。完整规则见 `GDD.md §5` / `CLAUDE.md §5`。

**反主流不做清单** — 不做体力 / 每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 强化破防降级 / 留存焦虑通知。

**在线 = 离线** — 不允许任何「在线 buff」「挂机加速」「快进券」。

**数值红线（两层语义）**：

| 硬红线（配置基础表值 · schema 拦截） | 上限 |
|---|---|
| 装备基础攻击 | 2,000 |
| 玩家血量 | 20,000 |
| 内力 | 15,000 |
| Boss 血量 | 60,000+（不进 1M） |
| 招式倍率 | 全局 ≤ 8,000 单线 |

软红线：满强化神物极值 build 真实战斗峰值约 13.5 万（大招约 21 万）——**核心唯一线 = 不进百万级膨胀**，保持六位可读。

**不硬编码** — Dart 代码里不写中文文案（走 `data/narratives|lore|events` 与集中式 `UiStrings`），不写数值常量（走 `data/*.yaml`）。

**让玩家先感受问题再给答案** — 新系统靠剧情/战斗自然出现，不写教程弹窗；未解锁系统的菜单按钮灰掉或隐藏。

---

## 文档索引

| 文档 | 作用 |
|---|---|
| [`GDD.md`](./GDD.md) | 主设计文档，设计层唯一真相源（冲突时以此为准） |
| [`CLAUDE.md`](./CLAUDE.md) | AI 协作操作规范（技术栈、命名、红线、工作流） |
| [`PROGRESS.md`](./PROGRESS.md) | 开发进度跟踪（每次开局读、任务完成更新） |
| [`data_schema.md`](./data_schema.md) | 所有 Dart model 字段定义规范 |
| [`IDS_REGISTRY.md`](./IDS_REGISTRY.md) | id 注册表（encounters ↔ events / equipment ↔ lore 联结） |
| [`content_guide.md`](./content_guide.md) | 文案写作技法指引 |
| `docs/spec/` · `docs/audit/` | 设计 spec 与全项目审查报告 |
| `docs/_archive/` | 退役文档归档（历史阶段快照、协作模式文档） |

---

## 协作与仓库

- **仓库**：`Zed1118/wuxia_idle`（私有，`publish_to: none`）·主分支 `main`
- **开发**：macOS 单端（Claude Code + Opus），写 `lib/` / `data/` / `test/` / 文档
- **数值/规则层受保护**：`GDD.md` / `CLAUDE.md` / `numbers.yaml` / `data_schema.md` / `IDS_REGISTRY.md` 改前需确认
- **Windows**：仅作发布目标平台，ship 前实机验证
