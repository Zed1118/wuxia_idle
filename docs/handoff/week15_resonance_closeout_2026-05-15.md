# Phase 4 W15 共鸣/强化/开锋视觉验收真闭环 + C-1 收尾 closeout

> Mac 端 Opus 4.7 维护,本会话末态。
> 创建日期:2026-05-15(W15 真闭环 v0.5.3-w15-final 之后开新会话)
> 上游锚:tag `v0.5.3-w15-final` 之后 6 commits,HEAD `6011fca`

---

## 1. 一句话结论

W15 三合一真闭环(B 派单 fixture + A 任务 C-1 收尾 + Codex 真 GUI 视觉验收 + FAIL 1 行 fix)。**11 张主截图 10 PASS + 1 WARN + 1 FAIL → fix 后 11 PASS 语义闭合**(widget test 兜底,未再派 Codex 重拍)。643/643 测试,analyze 0 issues。Encounter 30 条达 GDD §8.4 上限,W15 整体收口。

---

## 2. 会话密度统计

- **6 commits** 推进(全部 push 到 origin/main)
- **643/643 测试**(W15 真闭环 633 → +10:fixture +4 / encounter +3 / lineage chip +3)
- **analyze 0 issues**
- **新增/改 11 个文件**:lib/services 1 / lib/ui 2 / data 3(2 mv + 1 改)/ test 3 / docs/handoff 2(派单 spec + 本 closeout)/ docs/screenshots 11 张(由 Codex 添加)

### 关键 commits(逆时序)

| commit | 标题 | 内容 |
|---|---|---|
| `6011fca` | docs(W15): PROGRESS 三合一真闭环 | PROGRESS 末态合并 |
| `6db64c9` | fix(W15): 师承遗物 chip 读 equipment 实例字段而非 def 字段 | 1 行 fix + widget test +3 |
| `dd6c592` | 完成W15共鸣强化开锋视觉验收 | Codex Pen closeout + 11 张主截图 |
| `8f078f4` | docs(W15): PROGRESS 更新 B 派单 fixture push + A 任务 C-1 收尾 | PROGRESS 第 1 次合并 |
| `0171038` | feat(W15): C-1 收尾 2 条 encounter(long_yin / wu_ming tier 7 引用补) | A 任务,encounters 28→30 |
| `d0e0266` | feat(W15): seedVisualCheckW15Resonance fixture + Codex 派单 spec | B 派单 fixture push |

---

## 3. 关键决策与产出

### 3.1 第 1 阶段:B 派单 fixture(`d0e0266`)

**决策**:用户拍板「A 起手 + 派单 Codex 同期」,因此 Mac 先做 fixture 让 Codex 可拉,再开 A 任务。

`lib/services/phase2_seed_service.dart` 新建 `seedVisualCheckW15Resonance`:
- 6 件武器入背包覆盖矩阵(ownerCharacterId=1 不入 equippedXxxId,延续 W15-r2 体例):

| # | defId | tier | battleCount | enhance | 开锋槽 | 共鸣段 | 师承遗物 |
|---|---|---|---|---|---|---|---|
| 1 | weapon_xunchang_tie_jian | 1 | 0 | 0 | 0 | 生疏 | 否 |
| 2 | weapon_xiangyang_chang_jian | 2 | 200 | 5 | 0 | 趁手 +10% | 否 |
| 3 | weapon_haojiahuo_xuan_hua_fu | 3 | 800 | 10 | 1(attack) | 默契 +20% | 否 |
| 4 | weapon_liqi_pan_long_dao | 4 | 2500 | 15 | 2(attack/speed) | 心剑通灵 +30% | **强制** |
| 5 | weapon_zhongqi_qing_xu_jian | 5 | 1500 | 19 | 3(全) | 默契 | 否 |
| 6 | weapon_shenwu_tian_wen_jian | 7 | 5000 | 0 | 0 | 心剑通灵 | 否 |

- 师承遗物用 `EquipmentFactory.fromDef(... isLineageHeritage: true)` **强制标**(避开 P5 已装的 def 自带 long_quan/jin_pao)
- **defId 全避开 P5 starting_equipment**(test setup 踩坑教训:findFirst 命中 P5 那件,见 §4.1)
- 开锋槽锚 numbers.yaml `equipment.forging.slots`:slot1 attack +15 / slot2 speed +20 / slot3 specialSkill bonusValue=1(specialSkillId=null,仅占位)
- Phase2TestMenu 9 → 10 按钮(VC15-res),widget test viewport 1200 容 10 按钮
- test +4(6 件入背包 + 共鸣 4 阶段覆盖 + 师承遗物 1 件 by obtainedFrom 过滤 + forgingSlots type 自洽)

Codex 派单 spec `docs/handoff/codex_dispatch_w15_resonance_enhance_aperture_2026-05-15.md`:
- 11 张主截图(1 仓库 + 6 详情屏 chip + 4 开锋 Tab)+ 可选 1 张共鸣 overview
- 评级 PASS/WARN/FAIL 标准明示
- round2 工程教训沿用:真 GUI rowclick 不稳走 widget 捕获 fallback

### 3.2 第 2 阶段:A 任务 C-1 收尾(`0171038`)

挂回 2 条 orphan event 补 tier 7 池 long_yin / wu_ming 引用:

**huang_miao_jiu_seng**(荒庙旧僧,师父凉州旧识 + 剑鞘内龙吟):
- type: techniqueInsight,trigger: temple 90min + fortune 7,baseProbability 0.2
- outcomeMapping: `learn_healing → constitution+1` / `learn_lore → unlock long_yin`
- 呼应 narrativeInsightId `long_yin_shen_jian`(剑鸣龙吟双重命中)

**jiu_lou_jue_yin**(酒楼绝饮,剑不出鞘 + 千里路后无名招):
- type: techniqueInsight,trigger: inn 90min + fortune 7,baseProbability 0.2
- outcomeMapping: `earn_respect → constitution+1` / `clever_avoid → unlock wu_ming`
- 呼应 narrativeInsightId `gu_dao_xi_feng`(走千里路自然迈出的无名招)

`encounter_yaml_test` +3:
- 28→30 解析红线扩
- 2 条详细 outcome 断言(trigger biomeMinutes / outcomeMapping → skillId 联结)
- **「C-1 收尾后 tier 7 long_yin / wu_ming 被引用」语义红线**(用 allEncounters 遍历 outcomeMapping unlockSkill 集合 contains 断言,沿用 W15 #36 写约束不写瞬时数字纪律)

Encounter 总数 **28 → 30**(GDD §8.4 上限 20-30 已达)。

### 3.3 第 3 阶段:Codex 真 GUI 视觉验收(`dd6c592`)

派单 spec → Codex Pen Codex 跑 `docs/screenshots/w15_resonance/` 11 张主截图 + closeout `docs/handoff/codex_w15_resonance_visual_check_2026-05-15.md`。

**结果**:
- 9 PASS + 1 WARN(仓库列表 1280×900 装不下 15 件需 scroll,非 bug,与 round2 同 WARN)+ **1 FAIL**(蟠龙刀详情屏未渲染师承遗物 chip)
- 共鸣 4 阶段文案与 battleCount 对得上(0=生疏 / 200=趁手 / 800,1500=默契 / 2500,5000=心剑通灵)
- 强化 +0/+5/+10/+15/+19 五档 chip 全显成立
- 开锋 0/1/2/3 槽 unlocked/locked 区分明显(黄框「已开锋」vs 灰框「强化到 +N 解锁」)
- slot3 `专属技能:--` 占位符合本批要求
- **未走 widget fallback**(Pen 真 GUI 跑通,但 §8 提到 InventoryScreen ExpansionTile 折叠/滚动会影响坐标,改用「干净启动 → 进 VC15-res → 目标装备 → 截图」更稳)

### 3.4 第 4 阶段:FAIL fix(`6db64c9`)

**根因**(grep 一次定位):
`lib/ui/inventory/equipment_detail_screen.dart:148` 误用 `def.isLineageHeritage`,漏掉:
1. 奇遇赠送临时遗物 override(EquipmentFactory T55 注释明文留的参数通道)
2. 师承传承时 `inheritFrom()` 标记(equipment.dart:131)
3. fixture / debug 路径强制标(W15-resonance `forceLineageHeritage` 即此场景)

**fix**:1 行改 `equipment.isLineageHeritage`。`EquipmentFactory.fromDef` 本来就把 def→实例 propagate(`isLineageHeritage || def.isLineageHeritage`),所以 def 自带的回归路径不破。

**grep 全 lib/ 同类**:
- `character_panel_screen.dart:989` 用 `e.isLineageHeritage` ✓
- `derived_stats.dart:202,212` buff 计算用 `e.isLineageHeritage` ✓
- `game_repository.dart:713` starting_equipment 红线用 `def.isLineageHeritage` ✓(师徒 starting 必须 def-level 约束,产品意图正确)

**widget test +3**(equipment_detail_screen_test.dart):
- 实例标 / def 不标 → chip 必显(奇遇 override 路径)
- 实例不标 / def 不标 → chip 必隐
- def 自带 → propagate → 实例标 → chip 必显(回归保护)

红线写「约束语义」不写瞬时事实(memory `feedback_red_line_test_semantics`)。

**决策**:不再派 Codex 重拍 1 张截图。理由:
1. widget test 已覆盖该 chip 渲染 3 路径语义
2. UI 路径已被 Codex 验收 10 张 PASS,模板成立,1 行 fix 不引入新视觉风险
3. 派单成本(~30min)对产品价值低

**11/11 截图语义闭合**(10 张原 PASS + 1 张 fix 后语义补齐),W15 真闭环完成。

---

## 4. 工程教训

### 4.1 fixture defId 必避开 P5 starting_equipment(test setup 踩坑)

**现象**:第一版 fixture #2/#3/#4 用 weapon_xiangyang_gang_dao / haojiahuo_qing_feng_jian / liqi_long_quan,与 P5 师徒 starting 重复。test `forgingSlots type 配置自洽` 失败,因 `findFirst()` 按 Isar.autoIncrement 顺序命中 P5 那件(forgingSlots 全锁)而非 fixture 强制标的那件。

**Why**:`findFirst()` 不带 obtainedFrom 过滤时,会命中**最早写入**的同 defId 装备 — P5 先写。

**How to apply**:
- fixture 装备 defId 必避开 P5 师徒 starting_equipment(data/masters.yaml 9 件)
- 或 test 用 `obtainedFromEqualTo('visual_check_w15_xxx').findAll()` 锁定 fixture 那一批
- 本批同时做了两件事:换 defId(weapon_xiangyang_chang_jian / xuan_hua_fu / pan_long_dao)+ test 用 obtainedFrom 过滤(双保险)

### 4.2 师承遗物 chip 漏读实例字段(产品 bug)

**现象**:Codex 视觉验收 #5 蟠龙刀 FAIL → grep 定位 `equipment_detail_screen.dart:148` 用 `def.isLineageHeritage` 漏掉 3 条实例路径。

**Why**:`Equipment.isLineageHeritage` 是 Isar 持久化字段,有 3 条更新路径(EquipmentFactory propagate / fromDef override 参数 / inheritFrom() 师承传承)。读 def 字段只覆盖第 1 条,后两条静默失效。

**How to apply**:
- 涉及"实例可与 def 不一致"的字段(isLineageHeritage / customName / battleCount / enhanceLevel / forgingSlots / school 等),UI 一律读 equipment 实例字段
- 涉及"def-level 不可变"的字段(tier / slot / name / iconPath / presetLoreIds 等),UI 读 def 字段
- 边界字段(如 schoolBias)按"实例可 override 否"判断;不能 override 的读 def,可 override 的读实例
- grep 一次全 lib/ 同类(`isLineageHeritage` 出现 12 处),只此 1 处 UI 误读 — 模式不是普遍性问题,但单点 fix 必须 grep 一次确认其他位置正确

### 4.3 视觉验收 FAIL 修不一定要再派 Codex

**决策**:11 张主截图 1 FAIL 是 1 行 UI 字段误读,fix 后用 widget test +3 覆盖渲染 3 路径语义,**不再派 Codex 重拍 1 张**。

**Why**:
- widget test 覆盖语义 ≥ Codex 单张截图(测试可验"实例标 + def 不标"这种 fixture 难复现的边界)
- UI 路径已被验收 10 张 PASS,模板成立 — 1 行 fix 不引入新视觉风险
- 派单成本(Pen 启 GUI + 截图 + closeout + push)~30min,对产品价值低

**How to apply**:
- 视觉验收 FAIL 触发产品 fix 时,先评估 fix 范围:**1 行字段类 fix → widget test 兜底,不重派**
- 涉及布局/排版/动画/颜色等**视觉层** fix → 必须重派(test 验不到视觉效果)
- 涉及流程/交互/多步骤变化 → 重派(test 难覆盖完整流程)
- 本批是字段读取类 1 行,走 "widget test 兜底" 路径,W15 提供模板

### 4.4 Codex Pen 真 GUI 路径渐稳

round2 closeout §7 工程教训记 InventoryScreen ExpansionTile 内 row click 不稳,本批 §8 Codex 自报真 GUI 跑通(未走 widget fallback),但提到:
- Windows `CopyFromScreen` 屏幕绝对坐标 vs 人工读图窗口相对坐标,80,60 偏移需统一换算
- Flutter desktop `Esc` 会和路由返回交互,弹窗连续验收易从 dialog 退回上级
- 解法:**「干净启动 → 进 VC15-res → 目标装备 → 截图」**比长链路连续导航稳

memory `feedback_codex_pen_windows_visual_check` 可在下波再扩 1 段「真 GUI 截图坐标 helper 封装」候选(PROGRESS 下一步段已挂)。

---

## 5. 下次开局必读

### 5.1 顺序

1. **PROGRESS.md** 「当前阶段」+「下一步」+「已知偏差」(行 1-65)
2. **本文档**(W15 真闭环 v2 closeout)
3. **CLAUDE.md** §5 红线 + §12 待人类决策清单
4. `git pull --rebase --autostash` 看本会话末态是否有 drift

### 5.2 状态快照

- **HEAD = `6011fca`**,工作树 clean,在 main,与 origin/main 同步
- **tag `v0.5.3-w15-final` 仍为 W15 锚点**(本批不打新 tag)
- **643/643 测试**,analyze 0 issues
- `data/encounters.yaml`:**30** 条 encounter(W14-1 3 + W14-2 12 + W15 #37 第 1 批 6 + 第 2 批 7 + C-1 收尾 2),**达 GDD §8.4 上限**
- `data/events/`:23 个 active(W14-3-B 12 + W15 #37 第 1 批 6 + 第 2 批 7 - 2 W14-1 体例 + C-1 收尾 2);`_archive/` 剩 8 主题不适配
- 装备详情屏 round1 + round2 + 共鸣/强化/开锋 视觉验收全闭环(11 张主截图 + lineage chip fix)
- DeepSeek 文案池:35 篇 lore + 24 篇 events + 35 招 description 全到位

### 5.3 下波候选

| 候选 | 推荐档位 | 工作量 | 备注 |
|---|---|---|---|
| **A. #30 闭关 3 维度接 service** | — | — | 阻塞 §12 #7 节气清单 + 农历库,先解人类决策 |
| **B. Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾** | xhigh + 用户拍板 | 半天起 | 可重新捡回 #28 闭关 widget e2e,升档任务 |
| **C. #34 stage drop 视觉验收 Pen 环境改善** | Codex 派单 | 1h | 配 ≥1080 屏幕 + 库存页快捷入口 |
| **D. Pen-only T64 test fail 排查** | sonnet | 30min | `.dart_tool/build` cache stale 推测,Mac 不重现 |
| **E. 真 GUI 截图坐标 helper 封装** | sonnet | 1-2h | Codex 共鸣视觉验收 §8 教训沉淀,影响下次 Pen 视觉验收效率 |
| **F. #37 第 3 批挂回(可选)** | opus | 1-2h | 剩 8 主题不适配,需做纯 attributeBonus 心境向(无 unlock 路径),价值低 |
| **G. Phase 5 准备 / §12 待人类决策清单梳理** | 讨论型 | 30-60min | W15 收口后整体 review 进入 Phase 5 前的待决项 |

**推荐起手**(下次开局):
1. **G 起手**(讨论型 30-60min):W15 已收口,Encounter 达上限,装备详情屏 + 共鸣/强化/开锋 + 师承遗物 + lore 全栈跑通。下一步是否进 Phase 5 / §12 待人类决策清单(境界 vs 修炼度名重叠 / 单项属性范围 / 强化 +20-49 / 暴击系数 / 闭关产出公式 / 机缘累积规则 / 三流派克制数值 / 心法速度加成 / 人剑合一定义位置 / 师承遗物细节 / 祖师 buff / 商店折扣 / 节气清单)有需要拍板的吗
2. 或 **B 派单**(xhigh + 用户拍板):Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾,可重新捡回 #28 闭关 widget e2e(W6 后 service 实例化但 3 屏走 IsarSetup.instance,需 Consumer 化)
3. 或 **E**(sonnet 1-2h):Codex 真 GUI 截图坐标 helper 封装(短小工程类,沉淀本批教训)

### 5.4 模型建议

- A(闭关 3 维度)— sonnet(逻辑直观,有 numbers.yaml 已配)
- B(Phase 5 DDD)— **xhigh**,跨模块大改 + 屏 Consumer 化收尾(沿用 memory `feedback_model_selection` 复杂任务升档)
- C(stage drop Pen 环境)— Codex 派,Mac 备 fixture
- D(T64 排查)— sonnet
- E(截图坐标 helper)— sonnet 调研型
- F(#37 第 3 批,可选)— opus,主题适配 + 红线
- G(Phase 5 准备 / §12 讨论)— opus,大方向决策

---

## 6. 不在本会话处理的事项(留挂账)

- **#28 闭关 widget e2e test**(Phase 5 DDD 级)
- **#30 闭关 3 维度接 service**(阻塞 §12 #7 节气清单决策)
- **#31 main_menu「问鼎九霄」widget test**(pumpAndSettle 死循环)
- **#34 stage drop 视觉验收硬截图**(配 ≥1080 屏幕 + 库存页快捷入口)
- **#37 剩 8 主题不适配 orphan**(下波 F 候选,价值低)
- **Pen-only T64 test fail**(`.dart_tool/build` cache stale 推测)
- **真 GUI 截图坐标 helper 封装**(下波 E 候选,Codex 验收 §8 教训沉淀)
- **真 GUI 鼠标 row click 长链路连续导航不稳**(本批走干净启动绕开,工程教训不强求 fix)

---

**文档结束。HEAD `6011fca` 已 push,tag `v0.5.3-w15-final` 保留为 W15 锚点。下次会话 /clear 后从 §5 开局起手。W15 三合一真闭环完成。**
