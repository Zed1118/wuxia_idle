# CLAUDE.md

> Claude Code 启动必读。本文件用最小篇幅让你立刻能在本项目中正确工作。
> 任何细节冲突时，以 [`GDD.md`](./GDD.md) 为准；本文件提供操作层指引。
> 内容文案规范见 [`WINDOWS_DEEPSEEK_GUIDE.md`](./WINDOWS_DEEPSEEK_GUIDE.md)（你不写文案，但需要知道它在哪、长什么样）。
>
> **版本：v1.5**
> v1.5 变更摘要（2026-05-16）：§12.1 #10 师承遗物规则层 4 子项决议收口——① 传递时机:武圣飞升时自动传(GDD §7.1 原意,Demo 不实装飞升 → Phase 5+ 激活) ② 多徒弟归属:玩家进选件界面逐件分配(给主动权 + UI 包不复杂) ③ 累代叠加:只取当代不叠加(数值不爆炸,5 代不会撑红线;UI 可显传承链路但 buff 不叠) ④ 同部位冲突:自动卸下原装入背包 + 新遗物入槽(sane default,不做装备分解违反 §5.1)。numbers.yaml `inheritance.heritage_items` 加 4 规则字段(`transfer_trigger: ascend_to_wusheng` / `multi_disciple_allocation: player_pick` / `stack_across_generations: false` / `conflict_slot_resolution: auto_swap`)。**§12.1 真硬阻塞清零**,Phase 5 师徒系统升级路径无 schema 歧义。
> v1.4 变更摘要（2026-05-16）：§12.1 #7 三流派 extra_effect 数值拍板收口——刚猛震伤每招 +500 固定(穿透防御不暴击) / 阴柔内伤 N=3 守方 tick × 200/tick 固定(穿透防御 + 同源刷新覆盖) / 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `school=gangMeng` 角色触发。numbers.yaml 加 4 子段(`combat.schools.gang_meng_quake` / `combat.schools.yin_rou_internal_injury` / `retreat.time_of_day_bonus[zhengWu].target_attribute` / `applies_to_school`)。代码层 damage_calculator 震伤分支 + BattleState internalInjurySlot + battle_engine tick 衰减 + seclusion_service 正午阳刚 wire 同期落地。§12.1 #7 → §12.2 归档,剩 #10 师承遗物 1 条。
> v1.3 变更摘要（2026-05-15）：§12.1 #7 加现状备注——`SeclusionService.computeOutputs` 已接 4 维度（节气日 +30% / 子时 +20% 只乘内力 / techniqueLearnPoints / internalForcePoints），正午阳刚 +20% 因本条 #7 流派 extra_effect 未决暂未消费，加成乘到哪个维度也待 #7 决议后才能落代码。
> v1.2 变更摘要（2026-05-15）：§12 待决清单收口——13 条经 W1-W15 实装默认决议 10 条 + 本批方案 A 决议节气清单 1 条，剩 2 条进对应系统再拍板。§12 拆 §12.1（未决）/ §12.2（已消解归档）两段。
> v1.1 变更摘要：状态管理锁定 Riverpod 3.x；爬塔 Boss 数修正为 3 小 + 3 大；§6 增散功代价公式；§5.3 明确师承遗物纳入三系锁死；新增 §12 待人类决策清单；§1 末加 GDD 快速索引；§8 加 yaml 联结示例。

---

## 1. 项目一句话

Windows 单平台、买断制、写实武侠挂机游戏。Flutter Desktop，3v3 自动战斗 + 离线挂机，首个里程碑：3 个月内出可玩 Demo。

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
| 引擎 | Flutter Desktop (Windows) | 只 Windows，不出 Mac / Linux |
| 状态管理 | **Riverpod**（Phase 1 锁 2.x，与 phase1_tasks 一致；Phase 5 收尾再迁 3.x） | 不引入 BLoC 等其他方案 |
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
├── WINDOWS_DEEPSEEK_GUIDE.md  # 内容生产指引（DeepSeek 端用）
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
│   ├── narratives/            # 主线/章节剧情               [DeepSeek，禁止编辑]
│   ├── lore/                  # 装备典故                    [DeepSeek，禁止编辑]
│   └── events/                # 奇遇事件文本                [DeepSeek，禁止编辑]
├── assets/                    # 图片、字体（AI 出图）
└── test/                      # 单元测试 + golden 测试
```

**[你] = Mac + Opus 4.7 写**；**[DeepSeek] = Windows 端 DeepSeek 写**。文件类型完全隔离。

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

### 5.4 数值红线（不得突破）

| 项目 | 上限 |
|---|---|
| 普通伤害 | 8,000 |
| 大招暴击 | 几万（不许进十万） |
| 玩家血量 | 20,000 |
| Boss 血量 | 50,000+（不许进 1M） |
| 内力 | 15,000 |
| 装备攻击 | 2,000 |

**理由**：玩家一眼能读懂。突破 = 战力膨胀 = 项目失败。yaml 配置写完做一遍 schema 校验拦下越界。

### 5.5 在线 = 离线
挂机就是挂机。**不允许任何"在线 buff""挂机加速""快进券"**。关游戏 8 小时回来 = 一直挂着 8 小时。

### 5.6 不硬编码
- **Dart 代码里不写中文文案**——全部走 `data/narratives/` `data/lore/` `data/events/`。
- **Dart 代码里不写数值常量**——全部走 `data/*.yaml`。
- 唯一例外：开发期占位字符串可临时用，但合并 main 前必须迁出。

### 5.7 让玩家先感受问题，再给答案
新系统通过剧情或战斗自然出现，**不要写教程弹窗**。未解锁系统的菜单按钮直接灰掉或隐藏。

## 6. 核心公式（实现层必须遵循）

```
基础伤害 = (内力 × 0.4) + (装备攻击 × 8) + 招式倍率

最终伤害 = 基础伤害
        × 心法修炼度加成 (1.0 ~ 3.0)
        × 流派克制 (0.75 / 1.0 / 1.25)
        × 暴击系数 (1.0 / 1.5 ~ 2.5)
        × (1 - 目标防御率)
        × 境界差距修正

最大血量 = 1,000 + 内力 × 5 + 根骨 × 500 + 装备血量
出手速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成
```

**境界差距修正**（攻方/守方）：同 1.0/1.0｜差 1 阶 1.4/0.7｜差 2 阶 2.5/0.3｜差 3+ 阶 —/**0.05（近免疫）**。

**招式倍率参考**：普攻 500｜强力技能 1,000–3,000｜大招 5,000+。

**散功代价**（玩家更换主修心法时触发，v1.1 新增）：
```
新角色内力     = 当前内力 × 0.5
新主修修炼度   = 原主修修炼度 × 0.5    （原修炼度记录保留，重学时不归零）
辅修不受影响   = 不动
```
扣除非清零，鼓励多元探索；50% 的代价让"换流派"成为重决策而非随手切。

公式实现集中放 `lib/core/combat/formulas.dart`，**任何战斗结果计算都必须走这里**，禁止在 Widget 或 Notifier 里散写。散功流程封装在 `lib/features/cultivation/domain/dispel_cultivation.dart`。

## 7. 当前开发阶段

**阶段：Demo（首个 3 个月里程碑）**

Demo 必交付内容量：

| 项目 | 数量 |
|---|---|
| 主线关卡 | 15–20 |
| 章节 | 3 章（学武出山 / 武林初识 / 名扬江湖） |
| 主线剧情字数 | 3,000–5,000 |
| **爬塔** | **30 层（3 小 Boss [5 / 15 / 25 层] + 3 大 Boss [10 / 20 / 30 层]）** |
| 闭关地图 | 5 |
| 奇遇 | 20–30 |
| 装备 | 30–50（覆盖 7 阶，每阶 5–7） |
| 心法 | 20–30（覆盖 7 阶 + 3 流派） |
| 典故 | 50–80 段 |
| 武学领悟 | 30–50 招 + 20–30 触发条件 |
| 心法相生组合 | ≥ 5 |
| 师徒角色 | 祖师 + 大弟子 + 二弟子（共 3） |

**Demo 阶段不要做**（GDD §12 已留接口，碰都不碰）：
江湖恩怨 / 心魔 / 门派事件 / 婚姻后代 / 帮派 / 声望 / 轻功对决 / 群战 / PVP / 第二条主线 / 节日活动 / MOD / 跨周目元数据。

## 8. 工作流

| 端 | 工具 | 写什么 | 不写什么 |
|---|---|---|---|
| Mac | Claude Code + Opus 4.7 | `lib/`、`data/*.yaml`（根目录单文件）、`test/`、`GDD.md` | `data/narratives/` `data/lore/` `data/events/` 下任何文件 |
| Windows | Claude Code + DeepSeek | `data/narratives/` `data/lore/` `data/events/` | 任何 Dart 代码、yaml 数值 |

**汇合**：GitHub 主分支。**文件类型隔离 → 同一文件几乎不会被两端同时改**。
**冲突解决**：文案冲突以 DeepSeek 端为准，代码 / 数值冲突以 Opus 端为准。

### 8.1 数值与文案的联结约定

`data/encounters.yaml`（你写）与 `data/events/<id>.yaml`（DeepSeek 写）通过 `id` 字段联结。**`id` 必须严格相等且唯一**，加载时若任一端缺失对应 id 直接抛错而非静默跳过。

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
# data/events/bamboo_listen_rain.yaml （DeepSeek 写：纯文案）
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
❌ 修改 `data/narratives/` `data/lore/` `data/events/` 下的任何文件
❌ 引入其他状态管理库（已锁定 Riverpod 3.x）
❌ 引入第三方游戏引擎（Flame、Forge2D 等）
❌ 在 Demo 阶段动 §12 任何扩展系统
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

`#11` 祖师爷 Demo 不实装(`inheritance.founder_ancestor_buff.enabled_when_alive: false`)/ `#12` 江湖商店 Demo 不列(`§7` 内容总量表无)— 已知 Demo 不阻塞挂账,Phase 5+ 自然实装时再回头。

### §12.2 已消解归档（W1-W15 实装中默认决议）

| # | 条目 | 实质决议位置 |
|---|---|---|
| 1 | 境界 7 层 vs 修炼度 9 层名重叠 | 代码层严格不同名：境界用「启蒙/入门/熟练/精通/圆熟/化境/登峰」，修炼度用「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」，见 `lib/data/enum_localizations.dart:39,78` |
| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
| 3 | 强化 +20-49 成功率与材料 | `numbers.yaml equipment.enhancement.success_curve`：`max(0.30, 0.50 - 0.02*(level-19))`，磨剑石 18/25 颗，心血结晶保底 8 颗 |
| 4 | 暴击系数 + 防御率 | `numbers.yaml combat.critical`：base 5% + 身法 0.5%/点 + 上限 50%，倍率 1.5-2.5（灵巧固定 2.0）；防御率走 `realms.tiers.defense_rate` 按境界固定档（学徒 5%→武圣 35%） |
| 5 | 闭关产出公式 | `numbers.yaml retreat`：5 地图 base_outputs 各产出 + `realm_scale_per_tier: 1.3` + `cap_hours: 72`（2026-05-11 决议） |
| 6 | 武学领悟机缘累积规则 | W14-1 简化为「fortune 属性 1-10 静态值 + 软概率 `p = baseProbability * (1 + fortune/20)`」，不再单独累积"机缘值"，见 `encounters.yaml:13` + `encounter_hook.dart:50` |
| 8 | 心法速度加成 | `numbers.yaml techniques.tiers[*].speed_bonus`：7 阶 0/5/10/15/25/40/60，直接进 GDD §5.6 公式，无独立上限 |
| 9 | 人剑合一招式定义位置 | `numbers.yaml combat.resonance.unlocks_joint_skill: true`（默契阶段解锁）+ `skills.reference_multipliers.joint_skill.base: 4500`，**统一固定倍率，不绑流派/不绑装备类型**，由共鸣度系统统管 |
| 13 | 节气日完整清单 | v1.2 决议方案 A（2026-05-15）：12 个节气均匀覆盖四季，公历 hardcode 不引入农历库；删除原中秋（属农历节日非节气）。已落 `numbers.yaml retreat.solar_term_bonus.days_2026` |
| 7 | 三流派 extra_effect 数值 + 正午阳刚定向 | v1.4 决议（2026-05-16）：① 刚猛震伤每招 +500 固定(穿透防御不暴击,主攻击命中才触发);② 阴柔内伤 N=3 守方 tick × 200/tick 固定(穿透防御 + 同源刷新覆盖,可致死);③ 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `character.school==gangMeng` 触发;④ 灵巧 crit_rate +0.20 已在 §6 公式实装 (v1.0 起)。已落 `numbers.yaml combat.schools.gang_meng_quake / yin_rou_internal_injury / retreat.time_of_day_bonus[zhengWu].target_attribute & applies_to_school` + 代码层 damage_calculator 震伤分支 / BattleState internalInjurySlot / battle_engine tick 衰减 / seclusion_service 正午阳刚 wire |
| 10 | 师承遗物规则层(4 子项)| v1.5 决议(2026-05-16):① 传递时机:武圣飞升时自动传(GDD §7.1 原意,Demo 不实装飞升 → Phase 5+ 激活);② 多徒弟归属:玩家进选件界面逐件分配;③ 累代叠加:只取当代不叠加(数值不爆炸 + UI 可显传承链路但 buff 不叠);④ 同部位冲突:自动卸下原装入背包 + 新遗物入槽。已落 `numbers.yaml inheritance.heritage_items` 加 4 规则字段(`transfer_trigger=ascend_to_wusheng` / `multi_disciple_allocation=player_pick` / `stack_across_generations=false` / `conflict_slot_resolution=auto_swap`)。**代码层 Phase 5+ 师徒升级时按此实装,本批仅规则层锚定**。 |
| 11 | 祖师爷门派 buff(Demo 不实装)| `numbers.yaml inheritance.founder_ancestor_buff.enabled_when_alive: false` 显式 Demo 不实现,1.0 版本再设计 |
| 12 | 江湖商店折扣公式(Demo 不列)| Demo 内容总量表(§7)未列江湖商店,1.0 版需要时再补 |

---

**遇到拿不准的设计决策，优先回到 `GDD.md`，查 §12 待决项，仍不清晰则停下来与人类确认。不自作主张是这个项目最重要的纪律。**
