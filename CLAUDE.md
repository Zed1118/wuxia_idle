# CLAUDE.md

> Claude Code 启动必读。本文件用最小篇幅让你立刻能在本项目中正确工作。
> 任何细节冲突时，以 [`GDD.md`](./GDD.md) 为准；本文件提供操作层指引。
> 内容文案规范见 GDD §6.6 装备典故 / §10.2 江湖见闻录 / `data/lore/_templates/` 既有体例(原 `WINDOWS_DEEPSEEK_GUIDE.md` 已归档 `docs/_archive/`,2026-05-19 协作模式切换 Mac+Opus 单端接管文案后退役)。
>
> **版本:v1.20**
> v1.20 变更摘要(2026-06-16 全功能真审计修复批 · 0 改数值规则层):① **§5.6 正名集中式枚举本地化为合法 sink**——`EnumL10n`(enum→中文显示名,带 switch 穷尽检查)与 `UiStrings` 同类,不算「散写硬编码」;删 enum_localizations.dart 文件头 stale 的「Phase 4 会迁出」承诺,明确叙事文案走 data/、UI 文案走 UiStrings、枚举显示名走 EnumL10n;② **§6 公式/散功路径 drift 修正**:公式层 `lib/core/combat/formulas.dart`(不存在)→ 实际 `lib/features/battle/domain/`(damage_calculator + derived_stats);散功 `lib/features/cultivation/domain/dispel_cultivation.dart`(不存在)→ 实际 `lib/features/dispel/application/dispel_service.dart` + `lib/core/domain/technique.dart`;③ 本批另修 H1 爬塔周目迁移数据丢失 + M2-M5 散写中文迁 UiStrings(代码层,详 PROGRESS 续15 + `docs/audit/full_audit_2026-06-16.md`)。
> **版本:v1.19**
> v1.19 变更摘要(2026-06-11 阶段定调 + 文档体例 · 0 改数值规则层):① **项目定调「1.0 长线打磨期」**(用户拍板:长期打磨质量,不设上线时间压力)——§1/§7 措辞从「收尾冲刺」改长线打磨,§7 新增**打磨期工作原则**(不用 Demo/冲刺心态规划任务 · 能一次做全面就一次做全面 · backlog 只承载依赖未解除/待拍板项,不承载偷懒未做项);② **版本摘要搬家体例**:头部只留最近 2 版,v1.1-v1.17 迁 `docs/_archive/CLAUDE_CHANGELOG.md`(GDD 同步此体例 + 冻结 `GDD_v1.16_frozen_2026-06-11.md` 基线);③ 阶段锚单点 = PROGRESS.md 顶部常驻行。

---

## 1. 项目一句话

买断制、写实武侠挂机游戏，**发布目标 Windows**（开发与验收在 macOS）。Flutter Desktop，3v3 自动战斗 + 离线挂机。Demo 里程碑已达成（§8.4 14/14），当前处于 **1.0 长线打磨期**（质量优先，不设上线时间压力，见 §7）。

### GDD 快速索引

| 我想查 | 看 GDD 章节 |
|---|---|
| 项目定位与基调 | §1 |
| 反主流不做清单 | §2.1 |
| 7 阶节奏与三系对应 | §3 |
| 角色 4 项属性 / 稀有度 | §4.1 |
| 心法搭配 / 修炼度 9 层 | §4.2 – §4.3 |
| 三流派克制 | §4.4 |
| 心法相生组合 | §4.5 |
| 战斗数值范围（红线） | §5.2 |
| 伤害 / 血量 / 速度公式 | §5.3 – §5.6 |
| 装备获取 / 强化 / 心血结晶 | §6.1 – §6.3 |
| 共鸣度（人剑合一） | §6.4 |
| 开锋（3 槽 build） | §6.5 |
| 典故系统 | §6.6 |
| 师徒传承 | §7.1 |
| 武学领悟（替代抽卡） | §7.2 |
| 时间锚点闭关 | §7.3 |
| 主线 / 爬塔 / 闭关地图 | §8.1 – §8.3 |
| Demo 内容总量 | §8.4 |
| 核心循环（5 阶段） | §9 |
| 新手引导节奏 | §10 |
| Demo 阶段不做的扩展 | §12 |

## 2. 技术栈

| 层 | 选型 | 备注 |
|---|---|---|
| 引擎 | Flutter Desktop | 发布目标 Windows；开发/验收在 macOS（`-d macos`，Isar 无 web target） |
| 状态管理 | **Riverpod 3.x**（已迁，`flutter_riverpod ^3.0.0`） | 不引入 BLoC 等其他方案 |
| 本地存储 | Isar | 角色、装备、进度、共鸣度计数等 |
| 云端 | Supabase + Edge Function | **仅**排行榜，不做账号同步 |
| 战斗表现 | 纯 Flutter Widget + AnimationController | 不引入 Flame 等游戏引擎 |
| 打包 | MSIX，内测先发 itch.io | — |
| 数据格式 | YAML | 数值、配置统一 yaml |

## 3. 目录结构

```
project_root/
├── CLAUDE.md                  # 本文件
├── GDD.md                     # 主设计文档（你维护）
├── docs/_archive/             # 退役文档归档（含 WINDOWS_DEEPSEEK_GUIDE.md，v1.8 起退役）
├── lib/                       # Dart 源码 ── 你的领地
│   ├── core/                  # 公式、常量包装、领域模型（纯 Dart，无 Flutter 依赖）
│   ├── data/                  # yaml 加载、Isar 仓储、Supabase 客户端
│   ├── features/              # 按功能切分（battle / equipment / cultivation / ...）
│   │   └── <feature>/
│   │       ├── domain/        # 实体与用例
│   │       ├── application/   # Notifier
│   │       └── presentation/  # Widget
│   ├── shared/                # 跨 feature 复用（主题、组件、工具）
│   └── main.dart
├── data/                      # 全部配置与文案
│   ├── ranks.yaml             # 境界配置                    [你]
│   ├── equipment.yaml         # 装备数值                    [你]
│   ├── techniques.yaml        # 心法数值                    [你]
│   ├── stages.yaml            # 关卡配置                    [你]
│   ├── encounters.yaml        # 奇遇触发条件与数值          [你]
│   ├── narratives/            # 主线/章节剧情               [你 · v1.8 起接管]
│   ├── lore/                  # 装备典故                    [你 · v1.8 起接管]
│   └── events/                # 奇遇事件文本                [你 · v1.8 起接管]
├── assets/                    # 图片、字体、音频（AI 产出；audio/{bgm,sfx} 按 enum.name 命名）
└── test/                      # 单元测试 + golden 测试
```

**[你] = Mac + Opus 4.7 写**;v1.8 起单端接管全部文件类型(数值 + 文案 + 代码 + 测试 + GDD)。

## 4. 命名规范

| 对象 | 规则 | 示例 |
|---|---|---|
| Dart 文件 | snake_case.dart | `equipment_repository.dart` |
| 类 / Enum | UpperCamelCase | `EquipmentRepository`, `RealmTier` |
| 变量 / 函数 | lowerCamelCase | `currentRealm`, `calculateDamage()` |
| 私有 | 前缀 `_` | `_internalCache` |
| 常量 | lowerCamelCase（不用 SCREAMING） | `maxStrengthenLevel` |
| YAML key | snake_case | `attack_power: 1500` |
| 文案文件名 | snake_case | `chapter_01_opening.yaml` |
| 提交分支 | `feat/<feature>` `fix/<bug>` `balance/<topic>` | — |

**枚举命名锁死 GDD 词汇**：境界用 `Realm`，层用 `RealmStratum`，装备阶用 `EquipmentTier`，心法阶用 `TechniqueTier`，流派用 `Style { rigid, agile, sinister }`（刚猛/灵巧/阴柔）。**不要用 `legendary` `epic` 这类网游词汇**——本项目不存在这些概念。

## 5. 关键设计原则（红线）

> 这一节是底线。实现任何功能前若发现冲突，**停下来与人类确认**，不要自作主张地"折中"。

### 5.1 反主流不做清单
不做：体力 / 每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 装备分解 / 强化破防降级 / 留存焦虑通知。任何 PR 涉及以上功能 → 停。

### 5.2 七阶节奏（统一锚点）
所有可量化进阶系统共用同一套 7 阶：
- **境界**：学徒 / 三流 / 二流 / 一流 / 绝顶 / 宗师 / 武圣（每阶 7 层 → 49 级）
- **装备阶**：寻常货 / 像样货 / 好家伙 / 利器 / 重器 / 宝物 / 神物
- **心法阶**：入门功 / 常练功 / 名家功 / 门派绝学 / 江湖秘传 / 失传神功 / 传说神功

新增任何"阶/品/级"概念前先问：能否复用 7 阶？不能 → 找人类讨论。

### 5.3 三系锁死同步（不可破，无例外）
境界 ↔ 装备阶 ↔ 心法阶 一一对应。例：二流境界 → 最多装备「好家伙」、最多修「名家功」。**任何允许低境界使用更高阶装备/心法的设计都是错的**。在 `EquipmentRepository.canEquip()` / `TechniqueRepository.canPractice()` 这类校验点上保持硬约束。

**例外说明（v1.1 明确）**：
- **师承遗物同样受锁死约束**：虽自带传承 buff（内力上限 +5%），但徒弟境界未达对应阶时不可装备，只能存放在背包等到达阶时才可装备。规则统一，无网开一面。
- **奇遇所得 / 失传神物等"高于当前境界"的物品**同理：可获得、可携带、可观摩，但**不可装备 / 不可修炼**，等境界到了自动解锁。

### 5.4 数值红线（两层语义 · v1.20 收口 2026-06-14）

> **2026-06-14 红线语义收口（用户拍板分两层）**：原「普通伤害 ≤8000 不得突破」与现实分裂——满强化神物极值 build 普攻 calculator 探针约 5.8 万（暴击 8.7 万），**真实战斗峰值约 13.5 万、大招约 21 万**（含 per-skill 熟练度 ×1.30 + 地形/阵型/恩怨 APM 末端乘 + 飞升 +1 阶差距，由 `balance_simulator` 极值×周目诊断测实测），均「进十万、不进百万」；且 `test/data/p1a_redline_test.dart` 早已自承「≤8000 是设计层指南，极值已越界」。故红线分两层：**配置基础表值=硬约束**（schema 拦截）；**极值满 build 实战可见值=软可读区间**（核心唯一线 = 不进百万膨胀，2026-06-14 诊断后用户拍板从「不进十万」放宽，13-21 万仍 6 位可读）。

**硬红线（配置基础表值 · 不得突破 · schema 校验拦截）**：

| 项目 | 上限 |
|---|---|
| 装备基础攻击 | 2,000 |
| 玩家血量 | 20,000 |
| 内力 | 15,000 |
| Boss 血量 | 60,000+（不许进 1M；2026-06-14 终局周目膨胀调 50000→60000） |
| 招式倍率 | 普攻~500 / 强力 1,000–3,000 / 大招 5,000+ |

**软红线（极值满 build 实战可见值 · 保可读 · 不进百万膨胀）**：

| 项目 | 区间 |
|---|---|
| 普通伤害 | 典型 build 设计目标 8,000；满强化神物极值 build 普攻 calculator 探针 ~5.8 万、**真实战斗峰值 ~13.5 万**（含熟练度 ×1.30 + APM + 飞升阶差），**不进百万** |
| 大招暴击 | calculator 探针 ~8.7 万、真实战斗峰值 ~21 万，**不进百万** |

**理由**：玩家一眼能读懂——核心唯一线是**不进百万级膨胀**，不是钉死每个极值 build ≤8000、也不钉死十万（2026-06-14 诊断实测真实峰值 13-21 万后用户拍板放宽）。配置基础表值（装备攻击/血量/内力/招式倍率）yaml 写完 schema 校验拦下越界；实战可见值由两道测兜底：`test/balance/full_build_damage_redline_test.dart`（calculator 探针下界，硬断言不进百万）+ `test/tools/balance_simulator_test.dart` 极值×周目诊断测（真实战斗峰值 ~13.5-21 万，硬断言不进百万）。装备派生有效攻击（强化×共鸣×开锋连乘）远超 2000 是**有意终局爽感**，不是越界；终局极值 build 一回合秒杀终局内容（周目进化对满配无效）同属有意爽感（2026-06-14 用户拍板不动）。

### 5.5 在线 = 离线
挂机就是挂机。**不允许任何"在线 buff""挂机加速""快进券"**。关游戏 8 小时回来 = 一直挂着 8 小时。

### 5.6 不硬编码
- **Dart 代码里不写中文文案**——叙事文案(剧情/旁白/事件)全部走 `data/narratives/` `data/lore/` `data/events/`;UI 文案(标签/提示/错误串)走集中归集层 `lib/shared/strings.dart`(`UiStrings`)。禁止的是在 presentation / domain 各处**散写**中文字面量。
- **集中式格式化 / 本地化层是合法 sink(v1.20 正名)**:单一文件集中维护、非散落各处的中文,与 `UiStrings` 同类,**不算「散写硬编码」**——计有 `enum_localizations.dart`(`EnumL10n` 枚举→显示名,带 `switch` 穷尽检查)、`battle_log.dart`(战报格式化,大量插值句子集中一处)。新增此类文本进对应集中层,不要在调用点内联中文。
- **Dart 代码里不写数值常量**——全部走 `data/*.yaml`。
- 唯一例外：开发期占位字符串可临时用，但合并 main 前必须迁出。

### 5.7 让玩家先感受问题，再给答案
新系统通过剧情或战斗自然出现，**不要写教程弹窗**。未解锁系统的菜单按钮直接灰掉或隐藏。

## 6. 核心公式（实现层必须遵循）

```
基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率

最终伤害 = 基础伤害
        × 心法修炼度加成 (1.0 ~ 3.0)
        × 流派克制 (0.75 / 1.0 / 1.25)
        × 暴击系数 (1.0 / 1.5 ~ 2.5)
        × (1 - 目标防御率)
        × 境界差距修正

最大血量 = 1,000 + 内力 × 0.5 + 根骨 × 400 + 装备血量
出手速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成
```

> 注（v1.6 起 · P0.1 #38 方案 D 再对齐）：装备攻击系数 GDD §5.3 早期 ×8 / 最大血量内力系数 GDD §5.6 早期 ×5 均为 Phase 1 平衡前的口误值。代码以 `numbers.yaml` 为准：`combat.damage_formula.equipment_attack_factor` (1.0) / `combat.max_hp_formula.internal_force_factor` (**0.5**，P0.1 #38 方案 D 从 0.7 再调) / `constitution_factor` (**400**，从 500 再调)。均已在 numbers.yaml 注释中标注历史变更。出手速度 ×8 与 yaml 一致无变动。

**境界差距修正**（攻方/守方）：同 1.0/1.0｜差 1 阶 1.4/0.7｜差 2 阶 2.5/0.3｜差 3+ 阶 —/**0.05（近免疫）**。

**招式倍率参考**：普攻 500｜强力技能 1,000–3,000｜大招 5,000+。

**散功代价**（玩家更换主修心法时触发，v1.1 新增）：
```
新角色内力     = 当前内力 × 0.5
新主修修炼度   = 原主修修炼度 × 0.5    （原修炼度记录保留，重学时不归零）
辅修不受影响   = 不动
```
扣除非清零，鼓励多元探索；50% 的代价让"换流派"成为重决策而非随手切。

公式实现集中放 `lib/features/battle/domain/`(`damage_calculator.dart` 伤害 + `derived_stats.dart` 派生属性,系数全从 `numbers.yaml` 读),**任何战斗结果计算都必须走这里**,禁止在 Widget 或 Notifier 里散写。散功流程封装在 `lib/features/dispel/application/dispel_service.dart` + `lib/core/domain/technique.dart`(`TechniqueDispersion`)。

## 7. 当前开发阶段

**阶段：1.0 长线打磨期**（2026-06-11 用户定调）——Demo 里程碑已完成（下表 §8.4 14/14 全达标，留作内容量历史锚），1.0 内容周期已闭环。**长期打磨游戏质量，不设上线时间压力**；Steam/法律等外部项不催，性能实机/beta 等在打磨自然成熟后做。

**打磨期工作原则**（用户拍板，规划任何任务前必守）：
- **不用 Demo/冲刺心态规划任务**：不为赶进度切「最小闭环」，方案对比时质量优先于工期。
- **能一次做全面的就一次做全面**：不偷懒先挑简单的活做、把难活硬活留成一堆后期工作。
- **backlog 只承载两类项**：依赖未解除的、需用户拍板的。「本次没空做/偷懒没做」不是合法的 backlog 理由。

Demo 必交付内容量（已全部达标）：

| 项目 | 数量 |
|---|---|
| 主线关卡 | 15–20 |
| 章节 | 3 章（学武出山 / 武林初识 / 名扬江湖） |
| 主线剧情字数 | 3,000–7,000 |
| **爬塔** | **30 层（3 小 Boss [5 / 15 / 25 层] + 3 大 Boss [10 / 20 / 30 层]）** |
| 闭关地图 | 5 |
| 武学领悟触发（techniqueInsight encounter） | 20–30 |
| 基础奇遇（fortuneEvent，非节日） | 15–25 |
| 节日 encounter（festivalRequired 独立通道） | 6–10 |
| 装备 | 30–50（覆盖 7 阶，每阶 5–7） |
| 心法 | 20–30（覆盖 7 阶 + 3 流派） |
| 典故 | 50–80 段 |
| 武学领悟招式 | 30–50 招 |
| 心法相生组合 | ≥ 5 |
| 师徒角色 | 祖师 + 大弟子 + 二弟子（共 3） |

**扩展系统现状**（v1.18 更新，原「Demo 阶段不要做」清单退役）：江湖恩怨/声望（P1.2）、心魔（Batch 2.x）、帮派门派（P4.1）、轻功对决（P3.1）、群战守城（P3.2）、第二条主线 Ch4-6、多代飞升/真传位（P5+）均已在 1.0 周期实装。**仍然不做**：GDD §2.1 反主流清单（见 §5.1，永久红线）+ PVP / MOD / 跨周目元数据 / 节日活动系统级框架（GDD §12.4，1.0 后评估）——动这几项前必须先与人类讨论。

## 8. 工作流

| 端 | 工具 | 写什么 |
|---|---|---|
| Mac | Claude Code + Opus 4.7 | `lib/` / `data/` 全部(`*.yaml` 数值 + `narratives/` + `lore/` + `events/` 文案) / `test/` / `GDD.md` |

**汇合**:GitHub 主分支(`Zed1118/wuxia_idle`)。**单端写入,无跨端冲突**(v1.8 起 DeepSeek 端退役)。

**Windows 端 AI 工具已全下线**(2026-06-11 用户拍板):Pen Windows 不再参与任何 AI 工作流(视觉验收/代码备份/文案全停)。视觉验收唯一在 **Mac 本地 Codex**;Windows 仅作为发布目标平台,ship 前实机验证(D 段)时人工操作。

### 8.1 数值与文案的联结约定

`data/encounters.yaml`（数值与触发条件）与 `data/events/<id>.yaml`（文案）通过 `id` 字段联结（v1.8 起两端均你写）。**`id` 必须严格相等且唯一**，加载时若任一端缺失对应 id 直接抛错而非静默跳过。

**示例**：

```yaml
# data/encounters.yaml （你写：纯数值与触发条件）
- id: bamboo_listen_rain
  type: technique_insight        # 类型枚举：领悟 / 奇缘 / 试炼 / 因果
  trigger:
    biome: bamboo_forest
    weather: rain
    enemy_class: swordsman
    kill_count_threshold: 100
  fortune_required: 30           # 机缘属性门槛
  unlock_technique_id: ting_yu_jian
  cooldown_days: 30
```

```yaml
# data/events/bamboo_listen_rain.yaml （你写：纯文案）
id: bamboo_listen_rain           # 必须与 encounters.yaml 完全一致
title: 听雨悟剑
opening: |
  竹叶上水珠成串而下，雨声渐密。你伫立林间，
  忽觉百日来斩落的剑影，皆与雨势暗合……
choices:
  - text: 闭目静听
    outcome: insight
  - text: 拔剑试招
    outcome: practice
```

同样规则适用于：装备 (`equipment.yaml` ↔ `lore/<equipment_id>.yaml`)、关卡 (`stages.yaml` ↔ `narratives/<stage_id>.yaml`)。

## 9. 不要做的事（操作清单）

❌ Dart 代码里写硬编码数值（`damage = 1500`、`hp = 5000`）
❌ Dart 代码里写中文字符串文案（`"你战胜了山贼头子"`）
❌ 引入其他状态管理库（已锁定 Riverpod 3.x）
❌ 引入第三方游戏引擎（Flame、Forge2D 等）
❌ 未经讨论实装仍未启动的扩展（PVP / MOD / 跨周目元数据 / 节日系统级框架，见 §7）
❌ 给玩家做"每日任务""登录奖励""快进券""体力"等留存机制
❌ 让任何系统的数值突破 §5.4 的红线
❌ 让 yaml 配置在没有 schema 校验的情况下被静默接受
❌ 让 `data/encounters.yaml` 的 id 与 `data/events/` 下文件名失联（加载层必须强校验）
❌ 用 Material 默认饱和色彩——基调是水墨克制（青、墨、宣纸黄、绛红点缀）
❌ 写教程弹窗——用剧情、气泡提示、百科三种方式（见 GDD §10.2）
❌ 让"低境界 + 神物装备"或"低境界 + 高阶心法"的组合在任何代码路径上能跑通（**师承遗物也不例外**）

## 10. 拿不准时的处理顺序

1. 查 `GDD.md` 对应章节（用 §1 的快速索引定位）
2. 查 §12 待人类决策清单——是否在已登记的未决项中？
3. 查 `data/*.yaml` 既有结构是否已暗示约定
4. 查同类 feature 下已实现代码的模式
5. 仍不清楚 → **停下来问人类**，不要凭推测落代码

## 11. 提交规范

- commit message 用中文，动宾结构，简明
- 涉及 GDD 修改：标题前加 `[GDD]`，并简述变更影响范围
- 涉及数值平衡：标题前加 `[balance]`
- 涉及配置 schema 变化：标题前加 `[schema]`，并在 PR 描述中列影响的 yaml 文件
- 普通代码改动可省略前缀

## 12. 待人类决策清单（v1.5 收口 · §12.1 清零）

> v1.5（2026-05-16）：§12.1 #10 师承遗物规则层 4 子项决议收口（详 v1.5 变更摘要 + §12.2 归档），**§12.1 真硬阻塞清零**。所有 13 条原始待决条目已 100% 收口(11 条 yaml/代码层默认决议 + 2 条本批方案 A / v1.4 / v1.5 决议)。完整销账见 §12.2 归档。

### §12.1 未决项

**无**(2026-05-16 v1.5 全收口)。后续进 Phase 5 师徒系统升级 / 1.0 版本扩展系统时若出现新待决项,在此区段重开。

`#12` 江湖商店 Demo 不列(`§7` 内容总量表无)— 已知 Demo 不阻塞挂账,Phase 5+ 自然实装时再回头。(`#11` 祖师爷 buff 已于 2026-05-21 P1.1 候选 2 激活,详 §12.2 #11 v1.9 更新)

### §12.2 已消解归档（W1-W15 实装中默认决议）

| # | 条目 | 实质决议位置 |
|---|---|---|
| 1 | 境界 7 层 vs 修炼度 9 层名重叠 | 代码层严格不同名：境界用「启蒙/入门/熟练/精通/圆熟/化境/登峰」，修炼度用「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」，见 `lib/features/battle/domain/enum_localizations.dart`（`RealmLayer.qiMeng:42 / dengFeng:48` + `CultivationLayer.wuXia:96 / jiJing:97`） |
| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
| 3 | 强化 +20-49 成功率与材料 | `numbers.yaml equipment.enhancement.success_curve`：`max(0.30, 0.50 - 0.02*(level-19))`，磨剑石 18/25 颗，心血结晶保底 8 颗 |
| 4 | 暴击系数 + 防御率 | `numbers.yaml combat.critical`：base 5% + 身法 0.5%/点 + 上限 50%，倍率 1.5-2.5（灵巧固定 2.0）；防御率走 `realms.tiers.defense_rate` 按境界固定档（学徒 5%→武圣 35%） |
| 5 | 闭关产出公式 | `numbers.yaml retreat`：5 地图 base_outputs 各产出 + `realm_scale_per_tier: 1.3` + `cap_hours: 72`（2026-05-11 决议） |
| 6 | 武学领悟机缘累积规则 | W14-1 简化为「fortune 属性 1-10 静态值 + 软概率 `p = baseProbability * (1 + fortune/20)`」，不再单独累积"机缘值"，见 `encounters.yaml:13` + `lib/features/encounter/application/encounter_service.dart:216`（公式实装）+ `lib/features/encounter/domain/encounter_def.dart:162`（schema 注释） |
| 8 | 心法速度加成 | `numbers.yaml techniques.tiers[*].speed_bonus`：7 阶 0/5/10/15/25/40/60，直接进 GDD §5.6 公式，无独立上限 |
| 9 | 人剑合一招式定义位置 | `numbers.yaml combat.resonance.unlocks_joint_skill: true`（默契阶段解锁）+ `skills.reference_multipliers.joint_skill.base: 4500`，**统一固定倍率，不绑流派/不绑装备类型**，由共鸣度系统统管。**v1.9 补**:P1.1 候选 3-b(2026-05-21,commit `15ff8aa`)已实装 battle 释放路径 — `skills.yaml:772 skill_joint_skill`(mult=4500 / cost=250 / cd=4)+ `ResonanceStageConfig.unlocksJointSkill/hasSwordSongEffect` 解析 + `battle_ai` 优先级 `pending>jointSkill>powerSkill>normalAttack`,红线 27,421 < 100,000 ✅ |
| 13 | 节气日完整清单 | v1.2 决议方案 A（2026-05-15）：12 个节气均匀覆盖四季，公历 hardcode 不引入农历库；删除原中秋（属农历节日非节气）。已落 `numbers.yaml retreat.solar_term_bonus.days_2026` |
| 7 | 三流派 extra_effect 数值 + 正午阳刚定向 | v1.4 决议（2026-05-16）：① 刚猛震伤每招 +500 固定(穿透防御不暴击,主攻击命中才触发);② 阴柔内伤 N=3 守方 tick × 200/tick 固定(穿透防御 + 同源刷新覆盖,可致死);③ 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `character.school==gangMeng` 触发;④ 灵巧 crit_rate +0.20 已在 §6 公式实装 (v1.0 起)。已落 `numbers.yaml combat.schools.gang_meng_quake / yin_rou_internal_injury / retreat.time_of_day_bonus[zhengWu].target_attribute & applies_to_school` + 代码层 damage_calculator 震伤分支 / BattleState internalInjurySlot / battle_engine tick 衰减 / seclusion_service 正午阳刚 wire |
| 10 | 师承遗物规则层(4 子项)| v1.5 决议(2026-05-16):① 传递时机:武圣飞升时自动传(GDD §7.1 原意);② 多徒弟归属:玩家进选件界面逐件分配;③ 累代叠加:只取当代不叠加(数值不爆炸 + UI 可显传承链路但 buff 不叠);④ 同部位冲突:自动卸下原装入背包 + 新遗物入槽。已落 `numbers.yaml inheritance.heritage_items` 加 4 规则字段。**v1.14 P2.3 已实装 ✅**(2026-05-24 Batch 3.1-3.3):①+② 真消费(LineagePanel→AscensionScreen→performAscend · player_pick DropdownButton 真分配);③+④ Demo 一代飞升不验证 YAGNI 留 P5+。**v1.15 P5+ 多代飞升 + 真传位完整实装 ✅**(2026-05-24,④+⑤ 合并 batch 4 commit `1e875d6 → 1b1bb86`):③ `stackAcrossGenerations=false` derived_stats §244 按 isLineageHeritage instance count 不按 prev len 累加(R5.8 防回退测) + ④ `conflictSlotResolution=auto_swap` 真消费 `AscendService.performAscend` 副作用 4(disciple 端 equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包语义) + **真传位**:`performAscend` 加 `promotedDiscipleId: int?` 可选参数 · `promotedDisciple.isFounder=true` · `founder.isFounder` 保 true 「太祖」语义 · `founder_buff_service` 0 代码改自然接管(active 中找 isFounder=true → buff 激活) + AscensionScreen 加 _PromotedDiscipleRow widget · R5 测族 14→18(R5.6 多代 e2e 2 + R5.7 auto_swap 2 + R5.8 stack enforce 1)。详 `docs/handoff/p5_lineage_full_closeout_2026-05-24.md`。 |
| 11 | 祖师爷门派 buff(v1.9 已激活)| **v1.9 反转**:P1.1 候选 2(2026-05-21,commit `a0eae82`)决议方案 E.5.A → `enabled_when_alive: true`,玩家=祖师自享 sect_wide_buff(internal_force_max_pct=0.05 / max_hp_pct=0.05 / crit_rate_bonus=0.02 / cultivation_progress_pct=0.03)。`apply_to_disciples_only: false` 即 active 中 founder + disciple 全员享。Phase 5+ 飞升后再切语义(founder 退 active → buff 作用于新一代继位者)。已落 `lib/features/inheritance/application/founder_buff_service.dart` + `derived_stats.dart` `maxHp / internalForceMaxWithLineage / criticalRate` 各加 `founderBuffActive` 可选参数 + `lineage_panel_screen.dart _FounderBuffSection` UI 显。**P1.1 简化**:玩家本人即 founder 自享 buff;cultivation_progress_pct 修炼度公式接入留 Phase 5+ |
| 12 | 江湖商店折扣公式(Demo 不列)| Demo 内容总量表(§7)未列江湖商店,1.0 版需要时再补 |

---

**遇到拿不准的设计决策，优先回到 `GDD.md`，查 §12 待决项，仍不清晰则停下来与人类确认。不自作主张是这个项目最重要的纪律。**
