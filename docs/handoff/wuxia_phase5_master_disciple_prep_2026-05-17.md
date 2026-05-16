# 师徒系统 Phase 5+ 实装路径预研(2026-05-17)

> 作者:Mac Opus(预研非派单,不动代码)
> 触发:W17 候选 E 师徒系统起步,需评估实际工作量与价值
> 结论:**Demo 阶段无阻塞,师徒系统已 95% 完整,Phase 5+ 实际可落子任务只剩 UI 可视化(E.4)**

---

## 0. 一句话结论

**师徒系统在 Demo 阶段已落地 95%**,GDD §7.1 列出的 3 角色 / 三系锁死 / 师承遗物 +5% IF max buff / chip 显示 / 共鸣保留 70% 等**全部已实装**。Phase 5+ 实际可落子任务仅剩:① **E.4 师徒名单 UI panel**(可视化已有数据,低风险高产出 ~1-2h);② **1.0 版本预备**(收徒流程 / 武圣飞升 / 多徒弟选件 UI,Demo 阶段不必做)。

W17 候选 E「师徒系统 Phase 5+ 起步」**不推荐升档 xhigh 跨模块大动作**(原 PROGRESS 候选 E 预估 4h+),实际只值 1-2h sonnet 完成 E.4。

---

## 1. 现状盘点(以代码为准)

### 1.1 已落子项(11 个)

| # | 子项 | 实装位置 | 状态 |
|---|---|---|---|
| 1 | Demo 3 固定角色(祖师 + 大弟子 + 二弟子) | `data/masters.yaml` 3 entry + `MasterDef.fromYaml` | ✅ 完整 |
| 2 | LineageRole enum(founder / disciple) | `lib/core/domain/enums.dart:147` | ✅ |
| 3 | Character.isFounder | `Character` schema + Isar | ✅ |
| 4 | SaveData.founderCharacterId | `save_data.dart:33` | ✅ |
| 5 | T54 `seedMasterDisciple` 流程 | `phase2_seed_service.dart:187` | ✅ |
| 6 | T53 红线校验(总和 ≤24 / 三系锁死 / starting 装备-tier / 祖师必含 lineage 装备) | `game_repository.dart` startup + T53 系列 test | ✅ |
| 7 | isLineageHeritage Boolean | `Equipment.isLineageHeritage` def + instance 双源 | ✅ |
| 8 | 师承遗物 +5% IF max buff | `derived_stats.dart:212` | ✅ |
| 9 | 师承 chip UI | `equipment_detail_screen.dart:149` `equipment.isLineageHeritage` 实例优先 | ✅(W15 FAIL fix 后正确读 instance) |
| 10 | Equipment factory propagate isLineageHeritage | `equipment_factory.dart:54` | ✅ |
| 11 | 师承共鸣保留 70%(resonance_retention) | `numbers.yaml inheritance.heritage_items.resonance_retention: 0.7` + DispelService 等链路已落 | ✅ |

### 1.2 numbers.yaml v1.5 师徒规则层(4+1 字段,全已落 yaml)

```yaml
inheritance.heritage_items:
  pieces_per_generation_min: 1
  pieces_per_generation_max: 2
  auto_buff_internal_force_max: 0.05       # ✅ 代码层已消费
  resonance_retention: 0.7                 # ✅ 代码层已消费
  transfer_trigger: "ascend_to_wusheng"    # ⚠️ Demo 不激活(GDD §7.1 飞升 1.0)
  multi_disciple_allocation: "player_pick" # ⚠️ Demo 不激活(无 multi disciple 自动分配流程)
  stack_across_generations: false          # ⚠️ Demo 不需要(只有 1 代)
  conflict_slot_resolution: "auto_swap"    # ⚠️ Demo 不需要(无 inheritance 触发)

inheritance.founder_ancestor_buff:
  enabled_when_alive: false                # ⚠️ Demo 不实装
  sect_wide_buff: null                     # ⚠️ 1.0 设计
```

**关键发现**:v1.5 4 子项决议规则**已落 yaml**,但**实装 trigger 路径 Demo 不需要**(没有飞升流程 → 没有 inheritance 流程 → 没有 multi disciple 分配 / slot swap / 叠加规则可触发)。

### 1.3 GDD §7.1 解锁节奏 vs Demo 范围

| 突破到 | 解锁内容 | Demo 状态 |
|---|---|---|
| 一流(结丹) | 收徒 | 🚫 Demo 不实装运行时收徒(3 角色硬种 = "祖师一流 + 已有 2 徒") |
| 绝顶(化神) | 徒弟可以收徒孙 | 🚫 Demo 不实装 |
| 飞升渡劫后 | 传位 + 祖师爷 sect buff | 🚫 Demo 不实装(GDD §7.1 明示 Demo 不做飞升) |

**GDD §12 Demo 不做清单**第 8 行 = 不做飞升渡劫扩展。所以 GDD 设计原意 = Demo 师徒固定 3 角色,**不需要收徒/飞升 UI**。

---

## 2. Phase 5+ 可落子任务清单

### 2.1 E.4 师徒名单 UI panel(推荐 Demo 内做,sonnet 1-2h)

**目标**:让玩家在 GUI 看到师徒关系 + 师承遗物链路(可视化已有数据,无新数据模型)。

**已有信息**:
- `Character.isFounder` / `MasterDef.lineageRole` / `MasterDef.slotIndex` 已穿透
- `Equipment.isLineageHeritage` 已显在装备详情屏

**新增**:
- 新 screen:`lib/features/character_panel/presentation/lineage_panel.dart`
  - 顶部:祖师 chip(显当前境界 + 头像占位)
  - 中部:大弟子 chip(slotIndex=1)+ 二弟子 chip(slotIndex=2)
  - 底部:「师承遗物」段(列出所有 equipped + 背包 isLineageHeritage=true 装备)
- 路由:主菜单加 1 按钮「师徒名单」/ 或 CharacterPanelScreen 加 Tab
- widget test +3:祖师显 / 弟子显 / 遗物列表非空

**风险**:低(纯 UI 拼接已有 provider 数据,0 新 service,0 新 schema,0 build_runner regen)

**价值**:中(玩家看到 isLineageHeritage chip 但不知道是「师承」语义,panel 把语义补上;Demo 演示价值高)

### 2.2 E.5 founder_ancestor_buff sect_wide buff yaml 占位扩展(可选,~30 min)

**目标**:为 1.0 版本预留 yaml schema 但 Demo 仍 disabled。

**目前**:`founder_ancestor_buff.sect_wide_buff: null` 占位。

**预研**:加 4 字段框架(但 enabled_when_alive: false 不消费):
```yaml
founder_ancestor_buff:
  enabled_when_alive: false
  sect_wide_buff:
    attribute_all_bonus: 0.05      # 全属性 +5%(待 1.0 拍板)
    equipment_attack_bonus: 0.03   # 装备攻击 +3%
    technique_cultivation_bonus: 0.10  # 修炼度 +10%
    apply_to_disciples_only: true
```

**风险**:零(只加 yaml 占位 + 配套 NumbersConfig nullable 字段)

**价值**:低(纯 1.0 预备,Demo 玩家完全看不到)

**判断**:**不做**(Demo 价值零,真做 1.0 时再加,YAGNI)

### 2.3 E.1/E.2/E.3 收徒 / 飞升 / 多徒弟选件 UI(全部 1.0 版本)

| 子项 | Demo 价值 | 工作量 | 推荐 |
|---|---|---|---|
| E.1 yiLiu 突破时收徒弹窗 | 零(3 角色硬种) | sonnet 2-3h | ❌ Demo 不做 |
| E.2 武圣飞升 + 遗物 transfer | 零(Demo 无 wuSheng 角色) | opus xhigh 4h+ | ❌ Demo 不做 |
| E.3 multi_disciple_allocation player_pick UI | 零(E.2 触发后才有) | sonnet 2h | ❌ Demo 不做 |

---

## 3. 推荐 W17 候选 E 范围

### 3.1 建议:E = 只做 E.4(sonnet 1-2h)

**理由**:
- Demo 阶段师徒系统已 95% 完整,真硬阻塞 0 个
- E.4 师徒名单 UI panel 是 Demo 演示价值的临门一脚(让玩家「看见」师承关系)
- 风险低 + 工作量小 + 0 新 schema/service

**子任务拆分**:

| Step | 内容 | 时长 |
|---|---|---|
| 1 | 建 `LineageInfo` 数据类(纯 view model,组合 Character + Equipment 已有 provider) | 15 min |
| 2 | 建 `lineage_info_provider.dart`(@riverpod,从 `charactersProvider` + `allEquipmentsProvider` 派生) | 20 min |
| 3 | 建 `LineagePanelScreen`(纯 ConsumerWidget,3 chip + 遗物列表) | 30 min |
| 4 | 主菜单加按钮「师徒名单」(或 CharacterPanelScreen Tab) | 15 min |
| 5 | widget test +3 + analyze + commit | 30 min |

**总计**:~ 1h45min(sonnet,符合 PROGRESS 候选 E 重新评估为 sonnet 1-2h)。

### 3.2 不建议:E = 走原 candidate 4h+ xhigh 大动作

原 PROGRESS 估时(opus xhigh 4h+)假设包含 E.1/E.2/E.3 飞升 + 收徒 + 多徒弟选件 UI。但 GDD §7.1 + §12 明示 Demo 不做飞升。如硬做:
- E.1 收徒弹窗:Demo 无运行时新增 character 路径,需新建 `DiscipleRecruitmentService` + UI flow + Phase2 调试场景 + Isar 持久化
- E.2 武圣飞升:全部跨 cultivation / inheritance / character / equipment / save_data 模块,需写 transfer 流程 + ascendToWusheng trigger + 遗物逐件分配 UI
- E.3 multi_disciple_allocation:依赖 E.2 触发后才有意义

**判断**:E.1/E.2/E.3 全部进 1.0 版本路线图,Demo 不投。

---

## 4. 关键代码定位参考(后续派单/接单不用再 grep)

| 关注点 | 文件 | 位置 |
|---|---|---|
| MasterDef 定义 | `lib/data/defs/master_def.dart` | 全文件 |
| MasterDef yaml | `data/masters.yaml` | 全文件 3 角色 |
| 师徒红线校验 | `game_repository.dart` | T53 系列 startup 抛 StateError |
| 师徒种子流程 | `phase2_seed_service.dart` | `seedMasterDisciple` line 187+ |
| isLineageHeritage 数据流 | `equipment.dart:41` def → `equipment_factory.dart:54` propagate → `equipment.dart:131` setLineageHeritage instance → `derived_stats.dart:212` +5% IF max → `equipment_detail_screen.dart:149` chip 显示 | 5 处 |
| Character.isFounder | `lib/core/domain/character.dart` + `phase2_seed_service.dart:188` 注释说明 | 2 处 |
| numbers.yaml 师徒段 | `data/numbers.yaml` | line 1053-1087 |
| GDD §7.1 | `GDD.md` | line 393-405 |
| numbers.yaml inheritance v1.5 决议 | `CLAUDE.md` v1.5 变更摘要 + numbers.yaml line 1069-1083 注释 | — |

---

## 5. 与其他系统的潜在交互(Phase 5+ 真做 E.4 时注意)

- **CharacterPanelScreen**:已有,加 Tab 比新独立 screen 更内聚,推荐 Tab 方案
- **InventoryScreen Material Tab**:W15 #30 P3 后续 A 已建 TabBar 体例,E.4 可对齐
- **AdvancementSummary widget**(W15 #30 P3 抽出):已支持多角色 banner,但 E.4 不涉及升层,不复用
- **CharacterCard** widget(若已有):若有 reusable card,E.4 直接 3 × CharacterCard;若无,新建 LineageCard 简化版

---

## 6. 与 W17 候选 B 关系

W17 候选 B(Festival enum 扩 chuXi/qingMingJie)与 E 完全独立。B 已 framework 落地 + DeepSeek 派单已发 + Codex 派单已发,本会话结束后 E 才可能起。

---

## 7. 结论与下一步

### 7.1 结论

**师徒系统 Demo 阶段已实质完成**(11/14 子项 + v1.5 规则层全落 yaml)。Phase 5+ 真值得做的只有 E.4 师徒名单 UI panel(sonnet 1-2h)。原 PROGRESS 候选 E「opus xhigh 4h+」估时过高,实际工作量缩减到 1-2h sonnet。

### 7.2 推荐 W17 候选 E 派单格式

若用户决定起 E:
- **范围**:仅 E.4 师徒名单 UI panel
- **模型**:sonnet(不需要升档 xhigh)
- **预估**:1-2h
- **0 schema bump / 0 build_runner regen / 0 service 新增**
- **deliverable**:1 新 screen + 1 新 view model + 1 主菜单按钮(或 CharacterPanelScreen Tab)+ 3 widget test + 全测 0 regress + analyze 0

### 7.3 后续 1.0 路线图(本预研之外)

E.1 收徒 / E.2 飞升 / E.3 多徒弟选件 UI / E.5 founder_ancestor_buff sect buff 全部进 1.0 版本路线图(Demo §12 不做清单已暗示)。

---

**预研文档结束。本文档不动代码,不动 PROGRESS,仅作 W17 候选 E 决策依据。**
