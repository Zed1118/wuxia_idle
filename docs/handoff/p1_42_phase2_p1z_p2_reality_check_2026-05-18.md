# P1 #42 Phase 2 §10 P1.z P2 扩段 · Phase 0 reality check

> 2026-05-18,Mac + Opus 4.7 起草。**P1.z 主线**(`p1_42_phase2_p1z_codex_closeout_2026-05-18.md`)收口后 P2 扩段拍板依据。
> 起草背景:DeepSeek 端 combat_advanced.md 派单中(~30min),Mac 端同时进行 P2 reality check,为 DeepSeek 收口后用户拍板做准备。

## 0. 一句话结论

`data/narratives/codex/` 18 现成 md 中,7 篇 P1.z 已入,**11 篇 P2 候选**(A 组 4 + B 组 7);全过 ≤ 550 字红线;**架构决策点 = `CodexCategory` enum 死绑 §10.1 8 档导致 11 扩段无现成归属**,推荐方案 A(扩 enum 加 `lore` 值)。

## 1. 18 md 字数现状

| 类型 | 数量 | 字数区间 | 说明 |
|---|---|---|---|
| P1.z 已入 | 7 | 317-543 | realm / resonance / techniques_and_styles / three_styles_detail / retreat / master_disciple / encounter_system |
| P2 候选 | 11 | 329-519 | 见 §2 |
| DeepSeek 待补 | 1 (combat_advanced) | 待写 300-550 | P1.z 档 8 派单中 |

红线状态:18/18 全 ≤ 550(最大 543,P2 候选最大 519)。`CodexLoader._enforceCodexRedLines` 自动校验,P2 入库后红线 0 触发。

## 2. 11 P2 候选主题归类

### A 组 · 与 §10.1 8 档机制强相关(4 条)

可挂现有 `CodexCategory` 作"补充阅读",不需要新 enum:

| id | 字数 | 标题 | 推荐 category | 关联档 |
|---|---|---|---|---|
| equipment_tiers | 458 | 装备与品阶 | combat | 档 1(7 阶装备细节延展) |
| strengthening | 329 | 强化与磨剑石 | enhancement | 档 2(强化机制扩展) |
| weapon_forging | 466 | 兵器铸造流派 | enhancement | 档 2(铸造流派/锻法背景) |
| lost_techniques | 519 | 失传绝学考 | techniques | 档 3(7 阶心法 + 武学领悟) |

### B 组 · 江湖背景文,与机制档弱相关(7 条)

需要新 enum 值 `lore` 作"江湖背景"归属:

| id | 字数 | 标题 | 性质 |
|---|---|---|---|
| hidden_weapons | 411 | 暗器与毒 | 江湖战斗背景 |
| battle_taboos | 442 | 武斗禁忌 | 江湖规则 |
| jianghu_medicine | 342 | 江湖医药 | 治伤背景 |
| jianghu_ranks | 447 | 江湖九流 | 民间境界叫法 |
| jianghu_rules | 494 | 江湖通用规矩 | 江湖规则 |
| major_sects | 399 | 三大派概况 | 门派背景 |
| famous_battles | 478 | 名战录 | 历史背景 |

## 3. 架构决策点

**问题**:`CodexCategory` enum 现有 8 值死绑 §10.1 8 档(每值对应一档 tutorialStep 1-8),11 扩段无现成 enum 归属。

### 3.1 方案对比

| 方案 | 改动 | 工程量 | 语义 | 推荐度 |
|---|---|---|---|---|
| **A** 扩 enum 加 `lore` 值 | enum +1 值 + step nullable / 99 + UI 分组 + entries 扩 | sonnet 1-2h | 8 档机制 vs lore 背景并列清晰 | ✅ 推荐 |
| **B** 全硬挂现有 8 category | 0 schema 改动 | sonnet 30-45min | B 组 7 条违和(jianghu_ranks 挂 combat?) | ❌ 不推荐 |
| **C** 拆 MechanicCodex + LoreCodex | 架构拆分 + 二级 tab | sonnet 2-3h | 最干净但 demo 阶段过度 | △ 1.0 备选 |

### 3.2 方案 A 详细设计

**enum 改动**(`lib/features/codex/domain/codex_category.dart`):
```dart
enum CodexCategory {
  combat,        // 档 1
  enhancement,   // 档 2
  techniques,    // 档 3
  schoolCounter, // 档 4
  seclusion,     // 档 5
  lineage,       // 档 6
  encounter,     // 档 7
  advanced,      // 档 8
  lore,          // 新增:江湖背景(无 tutorialStep)
}

extension CodexCategoryStep on CodexCategory {
  int? get step {  // 改 nullable
    switch (this) {
      case CodexCategory.combat: return 1;
      // ...
      case CodexCategory.advanced: return 8;
      case CodexCategory.lore: return null;  // 江湖背景无解锁档
    }
  }

  bool get isMechanic => step != null;
  bool get isLore => this == CodexCategory.lore;
}
```

**CodexIndex.entries 扩**(取决于"入库范围"拍板,见 §4):
- 全入:8 + 4(A 组) + 7(B 组) = 19 entry
- 仅 A 组 4:8 + 4 = 12 entry,**不需要扩 enum**
- 折中 4+3:8 + 4 + 3 = 15 entry

**UI 分组**(`codex_tab.dart`):
- 上半段:8 档机制(按 tutorialStep 升序,沿用现有逻辑)
- 下半段:lore 江湖背景(排序待拍板)
- 视觉:加段分隔(SectionHeader / Divider)

**gating 决策**:
- 8 档机制条目:**保持现有** tutorialStep gating(未到档灰显占位,沉淀玩家"逐档解锁"体验)
- lore 江湖背景:**建议不 gate**(自由查阅,不绑教学进度,跟 GDD §10.2 "永久可查"定位一致)
- 待拍板

## 4. P2 拍板项(spec 起草前必须)

DeepSeek combat_advanced 收口前可同时拍:

### Q1 · 入库范围

| 选项 | 数量 | 优势 | 劣势 |
|---|---|---|---|
| 11 全入 | 11 (A 组 4 + B 组 7) | 百科信息密度最高,世界观最厚 | demo 阶段是否有这么多"江湖背景"消费场景? |
| 仅 A 组 4 | 4 | 聚焦机制延展,demo 体量克制 | B 组 7 篇 md 闲置(已写好的) |
| 折中 4+部分 B 组 | 7 (A 组 4 + B 组挑 2-3) | 兼顾机制 + 部分世界观底 | 挑哪几篇要二次拍板 |

### Q2 · UI 排序(lore 段)

8 档机制段已按 tutorialStep 升序排,lore 段如何排:
- 按字数升序 / 降序
- 按 md 文件名字母序
- 按主题密度(战斗 hidden_weapons/battle_taboos → 规则 jianghu_rules → 背景 major_sects/famous_battles)
- 按 CodexIndex 登记顺序(简单)

### Q3 · lore 段 gating

- 不 gate(推荐):自由查阅,跟 GDD §10.2 "永久可查"一致
- gate 到 tutorialStep ≥ N:与机制段一致体验,但跟"江湖背景文"语义违和

## 5. 风险 / 注意点

- **`CodexLoader` 红线**:`_enforceCodexRedLines` 校验 ≤ 550 字,11 候选最大 519 全过 ✅
- **graceful 加载**:loader 缺 md 跳过 + warn,P2 入库后若用户删某 md 不会爆 test
- **`step` 改 nullable 波及面**:`CodexIndexEntry.step` getter / CodexTab 排序逻辑 / test 中所有 step 断言 — sonnet 起 spec 时全 grep 一次
- **`isar widget test deadlock`**:CodexTab 测试若涉 Isar writeTxn 用 `test()` 不 `testWidgets()`(memory feedback_isar_widget_test_deadlock)
- **`ListView widget test viewport`**:扩到 19 条后 CodexTab widget test 默认 800x600 viewport 装不下,必须 `tester.binding.setSurfaceSize(Size(800, 2000))` + `addTearDown`(memory feedback_listview_widget_test_viewport · 本会话 P1.z 沉淀)

## 6. Phase 0 维度 C 复用现成内容印证

本批反向印证 `feedback_phase0_grep_two_axes` 维度 C:**11 条 md 早在 2026-05-10 已落**(W18-A3 lore 时期 DeepSeek 批量写入),是典型"邻近目录已存内容"。P2 入库**不需要 DeepSeek 重新写文案**(0 文案工程量),仅 Mac 端 enum + entries + UI + 测试,sonnet 1-2h 即可收口。

若 Phase 0 漏看维度 C → 误以为 P2 要 DeepSeek 重新生产 11 篇 ~3-5h + Mac 端 1-2h,总 4-7h;实际 Mac 端 1-2h 即可。**省 3-5h 工程量**。

## 7. 工程量估算

| 方案 | 范围 | 模型 | 时长 | 说明 |
|---|---|---|---|---|
| A · 11 全入 | 11 entry | Mac sonnet | 1-2h | enum + step nullable + UI 分组 + 11 entry + 测试更新(含 viewport 扩) |
| A · 仅 A 组 4 | 4 entry | Mac sonnet | 30-45min | 不需 enum 改(全挂现有 category) + 4 entry + 测试 |
| A · 折中 4+3 | 7 entry | Mac sonnet | 1-1.5h | enum + UI 分组 + 7 entry + 测试 |
| C · 全拆 | 全 18 entry | Mac sonnet | 2-3h | 1.0 备选,demo 阶段不推荐 |

## 8. 下一步

1. **DeepSeek combat_advanced 收口**(同时进行,~30min)
2. **用户拍板 Q1/Q2/Q3**(本文 §4)
3. **Mac 端 git pull --rebase --autostash** 同步 DeepSeek 端
4. **Mac 端起 P2 spec**(sonnet 30-45min):基于 Q1-Q3 决议起 `p1_42_phase2_p1z_p2_spec.md`,含 Phase 1(enum + entries)/ Phase 2(UI 分组 + 排序)/ Phase 3(测试更新)/ 红线复用清单 / 自审清单
5. **Mac 端落实装**(sonnet 1-2h,按 Q1 范围):接 spec 落代码 + 测试 + closeout
6. **接 P1.z 主 closeout 挂账**:P2 收口段落更新到 `p1_42_phase2_p1z_codex_closeout_2026-05-18.md` 末段

## 9. 沿用硬约束

- GDD §5.4 数值红线 / §5.6 不硬编码(本批纯 enum + UI,不涉数值/文案)
- `feedback_red_line_test_semantics` 测试断言不写具体数字(写约束语义)
- `feedback_listview_widget_test_viewport` ListView ≥ 7-8 行扩 viewport(P2 入 11 条必沉淀)
- `feedback_avoid_over_engineer_abstraction` 抽 widget 不预提 shared(SectionHeader 若仅 CodexTab 用,inline 即可,不抽 shared/)
- `feedback_phase0_grep_two_axes` 维度 C 复用现成内容(本批已印证)
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md / data/narratives/ 文案(DeepSeek 领地)
