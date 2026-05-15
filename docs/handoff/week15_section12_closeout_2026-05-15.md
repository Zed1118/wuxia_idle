# Phase 4 W15 §12 待决清单收口 + 节气清单决议方案 A closeout

> Mac 端 Opus 4.7 维护,本会话末态。
> 创建日期:2026-05-15(W15 整批闭环之后 G 任务讨论型收口)
> 上游锚:`v0.5.3-w15-final` 之后 8 commits,HEAD `fd67eab`

---

## 1. 一句话结论

W15 整批闭环之后 G 任务讨论型收口 CLAUDE.md §12 13 条待决清单。**已消解 10 条**(W1-W15 实装中由 numbers.yaml + 代码层默认决议 8 条 + Demo 不实现 2 条)+ **本批方案 A 决议 1 条**(#13 节气清单 12 节气均衡公历 hardcode),**剩 2 条真硬阻塞**(#7 流派 extra_effect 数值 / #10 师承遗物规则层)进对应系统再拍板。643/643 测试 + analyze 0 issues。

---

## 2. 会话密度统计

- **1 commit** 推进(`fd67eab` push 到 origin/main)
- **643/643 测试**(W15 真闭环 643 → 不变,文档+yaml 改动)
- **analyze 0 issues**
- **改 3 个文件**:CLAUDE.md / PROGRESS.md / data/numbers.yaml

### 关键 commit

| commit | 标题 |
|---|---|
| `fd67eab` | docs(W15): §12 待决清单收口 + 节气清单决议方案 A |

---

## 3. §12 13 条收口分类详

### 3.1 A 类 已实质消解(8 条) — W1-W15 实装中默认决议

| # | 条目 | 决议位置 |
|---|---|---|
| 1 | 境界 7 层 vs 修炼度 9 层名重叠 | `lib/data/enum_localizations.dart:39,78` 严格不同名:境界用「启蒙/入门/熟练/精通/圆熟/化境/登峰」,修炼度用「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」 |
| 2 | 单项属性范围 | `numbers.yaml:749-755` 单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
| 3 | 强化 +20-49 成功率与材料 | `numbers.yaml:475-511` `max(0.30, 0.50-0.02*(level-19))`,磨剑石 18/25 颗,心血保底 8 颗,`never_degrade: true` |
| 4 | 暴击系数 + 防御率 | `numbers.yaml:75-87` base 5% + 身法 0.5%/点 + 上限 50%,倍率 1.5-2.5(灵巧固定 2.0);防御率走 `realms.tiers.defense_rate` 按境界固定档(学徒 5%→武圣 35%) |
| 5 | 闭关产出公式 | `numbers.yaml:809-911` 5 地图 base_outputs + `realm_scale_per_tier: 1.3` + `cap_hours: 72`(2026-05-11 决议) |
| 6 | 武学领悟机缘累积 | W14-1 简化为「fortune 属性 1-10 静态值 + 软概率 `p = baseProbability * (1 + fortune/20)`」,不再单独累积"机缘值",见 `encounters.yaml:13` + `encounter_hook.dart:50` |
| 8 | 心法速度加成 | `numbers.yaml:585-627` 7 阶 `speed_bonus` 0/5/10/15/25/40/60,直接进 GDD §5.6 公式,无独立上限 |
| 9 | 人剑合一招式定义位置 | `numbers.yaml:531` `unlocks_joint_skill: true`(默契阶段)+ `numbers.yaml:736` `joint_skill.base: 4500` **统一固定倍率,不绑流派/装备类型**,由共鸣度系统统管 |

### 3.2 B 类 Demo 不阻塞(2 条) — Demo 范围不实现 / 已显式 disabled

| # | 条目 | 状态 |
|---|---|---|
| 11 | 祖师爷门派 buff | `numbers.yaml:1006-1009` `enabled_when_alive: false`,Demo 不实现,1.0 版本再设计 |
| 12 | 江湖商店折扣公式 | Demo 内容总量表(GDD §7)未列江湖商店,1.0 版需要时再补 |

### 3.3 本批方案 A 决议(1 条)

#### #13 节气日完整清单 → 12 节气均衡公历 hardcode

**决策依据**:
- 中秋是农历节日,非二十四节气之一(PROGRESS §7 原挂账)
- 农历库依赖会引入 `chinese_lunar_calendar` 等第三方包,审查成本高
- 二十四节气年际公历偏差仅 1 天,Demo 阶段精度足够,可纯公历 hardcode

**numbers.yaml retreat.solar_term_bonus.days_2026 改动**:

```yaml
# 改前(9 节气,含中秋混入)
days_2026:
  - {name: "立春", date: "2026-02-04"}
  - {name: "清明", date: "2026-04-05"}
  - {name: "立夏", date: "2026-05-06"}
  - {name: "夏至", date: "2026-06-21"}
  - {name: "立秋", date: "2026-08-08"}
  - {name: "中秋", date: "2026-09-25"}   # 节日非节气,删
  - {name: "秋分", date: "2026-09-23"}
  - {name: "立冬", date: "2026-11-08"}
  - {name: "冬至", date: "2026-12-22"}

# 改后(12 节气均衡覆盖四季)
days_2026:
  - {name: "立春", date: "2026-02-04"}
  - {name: "雨水", date: "2026-02-19"}   # 新增
  - {name: "清明", date: "2026-04-05"}
  - {name: "谷雨", date: "2026-04-20"}   # 新增
  - {name: "立夏", date: "2026-05-06"}
  - {name: "夏至", date: "2026-06-21"}
  - {name: "立秋", date: "2026-08-08"}
  - {name: "处暑", date: "2026-08-23"}   # 新增
  - {name: "秋分", date: "2026-09-23"}
  - {name: "立冬", date: "2026-11-08"}
  - {name: "小雪", date: "2026-11-22"}   # 新增
  - {name: "冬至", date: "2026-12-22"}
```

### 3.4 C 类 剩余真硬阻塞(2 条) — 进对应系统再拍板

| # | 待决项 | 阻塞范围 | 待决细项 |
|---|---|---|---|
| 7 | **三流派克制 extra_effect 数值** | 战斗系统进阶 | `numbers.yaml techniques.schools.counter_relations` 仅字符串描述(`extra_quake_dmg` / `crit_rate_+0.20` / `internal_injury`)。① 刚猛额外震伤具体数值(固定值 / 公式 / 招式倍率%)② 阴柔内伤 debuff 持续回合(回合制 vs 时长制)③ 是否可叠加。**注**:灵巧暴击率 +0.20 已实装 `combat.critical.lingqiao_critical_bonus` |
| 10 | **师承遗物规则层** | Phase 4-5 师徒系统 | 数值层已配(每代 1-2 件 + 内力 +5% + 共鸣度保留 70%)。**仍待决**:① 传递时机(飞升自动 vs 任意时点手动)② 多徒弟时谁继承 ③ 传承 buff 是否累代叠加(2 代师承 = +10%?)④ 当前已装备同部位时如何冲突解决 |

---

## 4. 文件改动清单

### 4.1 `data/numbers.yaml`

`retreat.solar_term_bonus` 段重写:
- 注释升级注明 v1.2 决议依据(`§12 #13 决议 2026-05-15`)+ 中秋删除原因
- `days_2026` 9 节气 → 12 节气
- 删掉「实际计算用农历库」的注释(方案 A 不引入农历库)

### 4.2 `CLAUDE.md`

- 顶部版本 `v1.1` → `v1.2`,加 v1.2 变更摘要
- §12 整段重写:拆 §12.1 未决(2 条 + #11/#12 Demo 备注)/ §12.2 已消解归档(9 条,含本批 #13)

### 4.3 `PROGRESS.md`

- 「当前阶段」切到 §12 收口本批描述
- 「已完成」插入 §12 收口条目(置顶,在 W15 真闭环之上)
- 「挂账事项」:
  - #7 划掉(节气混入中秋)→ 本批方案 A 销账
  - #8 改写为「CLAUDE.md §12 收口剩 2 条」(原描述 13 条已过时)
  - #30 阻塞描述更新(节气清单方案 A 后农历库依赖消除,#30 纯代码层动手任务可入 Phase 5 早期)
- 「下一步」去掉已闭环条目(§12 待决梳理 / #1 名重叠注),保留 6 条候选
- 末段删除「§12 #1 实质消解注」(已并入 §12.2 归档)
- **98 行,卡 100 行内**

---

## 5. 测试与验证

- `flutter analyze`:**No issues found**(ran in 2.2s)
- `flutter test`:**643/643 All tests passed**(W15 真闭环 643 → 不变)
- 代码层零节气引用(`grep "立春\|清明\|...\|solar_term" lib/ test/` 0 hit),改 yaml 不破任何测试 — 反过来印证 PROGRESS #30 闭关 service 还没消费节气日

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `fd67eab`,与 origin/main 同步,工作树 clean
- tag `v0.5.3-w15-final` 保留(W15 锚点,§12 收口未另打 tag)
- 643/643 测试,analyze 0 issues
- §12 待决:13 条 → 2 条
- Encounter 30 / GDD §8.4 上限达成

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6.3 下波候选
3. `git pull --rebase --autostash` 看 drift(本会话末态已 push,正常无 drift)

### 6.3 下波候选(优先级排序)

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **A. #30 闭关 3 维度接 service** | **sonnet/opus** | **1-2h** | **节气清单方案 A 后阻塞已解,纯代码层动手任务,首推** |
| B. Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾 | xhigh + 用户拍板 | 3-5h | 可重新捡回 #28 闭关 widget e2e |
| C. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派 | 1h | 配 ≥1080 屏 + 库存页快捷入口 |
| D. Pen-only T64 test fail 排查 | sonnet | 30min | `.dart_tool/build` cache stale 推测 |
| E. 真 GUI 截图坐标 helper 封装 | sonnet | 1-2h | Codex §8 教训沉淀,短小工程类 |
| F. #37 第 3 批挂回(可选) | opus | 1-2h | 剩 8 主题不适配,纯 attributeBonus 价值低 |

**推荐起手 A(sonnet 或 opus 1-2h)**:`SeclusionService.computeOutputs` 当前只消费基础 `experience_per_hour / mojianshi_per_hour / equipment_drop_rate`,未消费 `technique_learn_rate / internal_force_growth / 节气日 +30% / 子时内力 +20% / 正午阳刚 +20%`。节气库依赖已解,代码层直接接,中等复杂度建议 opus。

### 6.4 硬约束(每次开局必读)

- 不动 GDD.md / CLAUDE.md / numbers.yaml 数值层 / IDS_REGISTRY.md / data_schema.md(本批 §12 收口属于例外用户拍板)
- 不动 data/narratives/ data/lore/ data/events/(DeepSeek 领地)
- Mac 缺 Xcode 跑不了 flutter run -d macos,实战截图派 Pen Codex
- catch 块加 debugPrint / Isar @embedded List 写前 List.of 转 growable
- 不跨 service 嵌套 writeTxn / Dart extension 不与 List.add 同名签名冲突
- preset lore 按需 LoreLoader.load 不写 Isar;Equipment.lores 留延续典故
- 红线测试写「约束语义」不写「瞬时事实」
- closeout 涉及数字必须 grep 实测,加和也要复测
- closeout 自审 grep 不只查代码,注释也要查
- 派单 spec 的「预期值」必须 grep 派单源头,不能信任中间层 PROGRESS / closeout
- UI 字段读取:实例可与 def 不一致的字段一律读 equipment 实例,def-level 不可变字段读 def
- 视觉验收 FAIL 字段类 1 行 fix → widget test 兜底,不重派 Codex;布局/动画/流程 fix → 必须重派
- Codex 双备份角色(可顶 Mac Opus 也可顶 DeepSeek 文案),默认三方隔离
- Pen GUI 长链路连续导航不稳 → 走「干净启动 → 进 fixture → 截图」

---

## 7. 教训沉淀

### 7.1 §12 收口的隐性收益

W1-W15 实装过程中,**实质决议早就在 numbers.yaml / 代码层默默落了**,只是 CLAUDE.md §12 没同步刷新。13 条里 8 条「已消解」全是这种「文档滞后」情况。讨论型 G 任务的价值就是把这种隐性决议显性化,**进 Phase 5 前清理战场**。

教训:**类似的待决清单类文档,每个 milestone 收尾前都该过一遍 grep 实测**,不要等到积累到 13 条才一次性梳理。

### 7.2 节气清单不引入农历库的决策成本

原 `numbers.yaml` 注释「实际计算用农历库(如 chinese_lunar_calendar)」是 Phase 1 配置时的"未来主义",当时图省事写上去预留接口。本次收口才意识到:
- 二十四节气年际公历偏差仅 1 天,Demo 阶段精度足够
- 农历库依赖会引入第三方包审查 / 平台兼容 / pubspec 升级风险
- 公历 hardcode + 代码读 yaml 取月日(忽略年份)比较即可,实现复杂度低
- **未来年份过期问题**:`days_2026` 字段已显式带年份,过期时按年份滚动 yaml 即可

教训:**预留接口不等于"用第三方依赖兜底"**,在 Demo 阶段「最小可行实现」优先。

### 7.3 G 任务的时长把控

讨论型 G 任务原估 30-60min,实际 ~45min(读 yaml + 读 CLAUDE.md + 分类报告 + 3 文件改 + 测试 + commit + push + closeout)。**G 任务可以兼"讨论 + 小动手收口"**,不一定要纯讨论。

---

## 8. memory 候选(本批不写,留下次评估)

- ~~§12 收口纪律~~:暂不沉淀,此类 milestone 收尾梳理是常态,无新教训
- ~~农历库不引入决策~~:不沉淀,project-specific 决策不通用
- **「文档滞后于代码默认决议」教训**:可考虑沉淀通用 feedback,但本批样本仅 1 次,留 3+ 实例再评估

---

**本 closeout 完。下次会话从 §6 开局动作起步。**
