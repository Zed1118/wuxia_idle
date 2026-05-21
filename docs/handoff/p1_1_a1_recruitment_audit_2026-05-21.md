# A1 师徒 E.1 收徒弹窗 audit + 3 方案 spec(2026-05-21)

> Mac Opus xhigh · audit 类不动代码 · Phase 0 四维 grep 完整产出 + 3 方案对比 + 设计决策点
>
> **触发**:P1.1 系统纵深起手项,closeout `session_p2_audit_closeout_2026-05-21.md` §6.1 列为候选 1
> **HEAD**:`15d4be7` · 1127 pass / 0 issues 基线不变
> **依据**:GDD §7.1(L393-405)+ `numbers.yaml inheritance`(L1066-1095)+ Phase 5 预研 `wuxia_phase5_master_disciple_prep_2026-05-17.md` + spec `phase5_master_disciple_spec_2026-05-20.md`

---

## §0 Phase 0 四维 grep 全量结果

### 维度 A — schema/字段层

| 字段/类 | 位置 | 状态 |
|---|---|---|
| `Character.lineageRole` (LineageRole enum: founder/disciple) | `lib/core/domain/character.dart:69` + `enums.dart:147` | ✅ 已落 |
| `Character.isFounder` | `character.dart` schema + `phase2_seed_service.dart:188` | ✅ 已落 |
| `MasterDef` (id/lineageRole/slotIndex/defaultRealm/attributeProfile/starting*) | `lib/data/defs/master_def.dart` + `data/masters.yaml` 3 entry | ✅ 已落 |
| `SaveData.activeCharacterIds` (List<int>) | `lib/core/domain/save_data.dart:36` | ✅ 已落,**无显式上限校验** |
| `numbers.yaml inheritance.unlock_rules.can_take_disciple_at: yiLiu` | `data/numbers.yaml:1074` | ✅ 已配 |
| `numbers.yaml inheritance.demo_max_characters: 3` | `data/numbers.yaml:1079` | ⚠️ **Demo 上限锁,1.0 扩需改** |
| `CharacterRecruitmentService` / `RecruitmentDef` / `recruitCandidates` | (全仓 grep) | ❌ **0 命中**(closeout 描述「service 已建」是错的) |
| `data/recruit_candidates.yaml` 等候选 NPC 池 yaml | (find data/) | ❌ **0 命中** |

### 维度 B — caller / 生产路径

| 钩子点 | 位置 | 现状 |
|---|---|---|
| 主线 victory 钩子 `_applyVictoryResolution` | `stage_entry_flow.dart:331` | ✅ 已建,返回 `(drops, advancements)` 可扩 recruitment trigger |
| 爬塔 victory 钩子 `_applyTowerVictoryResolution` | `tower_entry_flow.dart:263` | ✅ 已建,体例对齐主线 |
| tutorial step 6「主角境界突破到一流」hook | `tutorial_service.dart:84-92` | ✅ 已建,**直接复用作收徒触发点的最强候选** |
| 主角境界突破 hook(advance breakthrough) | `tutorial_service.dart` `recordRealmBreakthrough` | ✅ 已建,event `realmBreakthrough` + `disciplePromoted` 已分流 |
| 战胜 N 次 NPC 后触发 | (全仓 grep) | ❌ 未建(closeout §6.1 推演的「-1 阶 NPC 概率触发」无现有 caller 链)|

### 维度 C — 邻近目录

| 目录 | 已建文件 | 状态 |
|---|---|---|
| `lib/features/character_panel/` | `application/lineage_info_provider.dart` + `presentation/{character_panel_screen,lineage_panel_screen,encounter_skill_section}.dart` | ✅ 4 文件全 |
| `lib/features/tutorial/` | step 6 收徒门槛 hook | ✅ |
| `lib/features/codex/` | `codex_index.dart` `master_disciple` entry | ✅ |
| `lib/features/event/` | `disciplePromoted` GameEvent type(L20)| ✅ |
| `lib/features/lineage/` 独立 feature | — | ❌ 不存在(预研 doc §1.3 暗示 Phase 5+ 才建) |
| `lib/features/recruitment/` 独立 feature | — | ❌ 不存在 |

### 维度 D — UI widget

| widget | 位置 | 状态 |
|---|---|---|
| `LineagePanelScreen`(显祖师 + 弟子)| `lineage_panel_screen.dart` | ✅ W17 候选 E.4 已落 |
| `_LineageDisciplesRow`(显 discipleIds 列表)| `character_panel_screen.dart:958` | ✅ |
| 收徒弹窗 `RecruitmentDialog` / `DiscipleAcceptScreen` | — | ❌ **不存在** |
| codex 「师徒」百科条目 | `data/narratives/codex/master_disciple.md` | ✅ 已写满(7 段哲学叙述,**未涉及收徒流程具体描述**)|

### §0 维度结论

| 维度 | 结果 | 工作量含义 |
|---|---|---|
| A 字段层 | 半完成(70%):基础 schema 已落,**收徒专属 schema 未建**(无 candidate 池 / 无 recruit service / 无 invite event) | 需新增 yaml schema + service + Isar 持久化 |
| B caller | 钩子点已建(主线/爬塔 victory + tutorial step 6),**收徒概率触发未建** | trigger 接 tutorial step 6 复用代价低;接 victory 钩子需 grep 现状 NPC 概念 |
| C 邻近目录 | character_panel 已建,**recruitment 独立 feature 未建** | 新建 `lib/features/recruitment/` 目录三层 |
| D UI | 师徒展示已建,**收徒弹窗未建** | 新建 `RecruitmentDialog` widget + 路由接入 |

**判定**:E.1 收徒弹窗是 **"半完成 + 0→1 UI/service"** 模式 — schema 50% 已铺,核心 service + UI + trigger 路径 0。**closeout §6.1 描述「`character_recruitment_service` 已建」错误,应改为「相关基础 schema 已建,核心 service 未建」**。

---

## §1 现状再校:与 Phase 5 预研 / spec doc 关系

### §1.1 Phase 5 预研 doc(2026-05-17)立场

> 预研 §2.3 表格:`E.1 yiLiu 突破时收徒弹窗 / Demo 价值零(3 角色硬种)/ sonnet 2-3h / **Demo 不做**`

预研立场:**Demo 阶段不做 E.1**,因 3 角色硬种 + 无飞升流程 + 无运行时新增 character 路径。

### §1.2 Phase 5 spec doc(2026-05-20)立场

spec §3-§5 全篇覆盖「飞升 / 遗物 transfer / 祖师爷 buff」,**E.1 收徒弹窗未在 spec 范围内**(spec doc 是 Phase 5+ 升级路径文档,把 E.1 留给「Phase 5+ 真做时再起 spec」)。

### §1.3 ROADMAP_1_0.md P1.1 立场

> ROADMAP L72-73:`P1.1 A 类系统纵深 / A1 师徒系统真实化(E.1 收徒弹窗 / E.5 founder_ancestor_buff sect buff,sonnet 各 1-3h)`

ROADMAP 立场:**E.1 在 1.0 路线图 P1.1 阶段做**(Demo 后 M2-M4),工作量 sonnet 1-3h。

### §1.4 三 doc 一致性

预研 doc + spec doc + ROADMAP **三者一致**:
- Demo 阶段不做 E.1 ✅(Demo 已 100% closeout 在 M1 之前完成)
- 1.0 P1.1 阶段做 E.1(本会话进度)
- 估时 sonnet 1-3h 范围

**关键澄清**:当前进度 = 1.0 路线图 P1.1 第 1 子任务,**不是 Demo 内容**。

---

## §2 设计决策 3 维 · 27 组合中筛 3 方案

### §2.1 触发条件 3 选

| 选项 | 描述 | 接现有 caller | 设计 mood |
|---|---|---|---|
| **T1** | 主角境界突破到一流(一次性,首通)| 复用 `tutorial_service.dart:84` step 6 hook | 仪式化里程碑,GDD §7.1 直译 |
| T2 | 战胜玩家境界 -1 阶 NPC 后概率触发(机缘式)| 接 `_applyVictoryResolution` + 新 NPC 概念 | 「江湖偶遇」mood,closeout §6.1 推演 |
| T3 | 主线特殊章节节点触发(剧情驱动)| 主线 stage narrative + `recordVictory` hook | 强叙事但锁主线节奏 |

**推荐 T1**:tutorial step 6 hook 已建,复用代价 0;一次性触发 = 不需要概率公式 + NPC 池;符合 GDD §7.1 「突破到一流可收徒」直译。

### §2.2 NPC 来源 3 选

| 选项 | 描述 | schema 影响 | 运行时影响 |
|---|---|---|---|
| **N1** | 新 yaml `data/recruit_candidates.yaml` 池(N=2-3 候选 NPC,each: name/portrait/4 属性/起手心法装备)| 加 yaml + RecruitDef def + RecruitLoader | 加载期 1 次,无运行时生成 |
| N2 | 战斗后从 stage enemy 数据随机生成 | 不加 yaml,沿 stages.yaml enemy waves 复用 | 每次触发动态生成 Character |
| **N3** | 纯仪式收徒(无新 character,只触发 codex/event/UI 提示)| 0 schema | 0 运行时 character 新增 |

**推荐 N1**:N=2-3 候选 NPC 数据驱动 + 玩家可选其中 1 个 + 拒绝可后续机会重触;比 N3 纯仪式有 gameplay 实感,比 N2 动态生成更可控(避免战斗结算 race condition)。

### §2.3 收徒后影响 3 选

| 选项 | 描述 | active 上限 | 红线影响 |
|---|---|---|---|
| **I1** | active 上限 3 → 4,新弟子进 active 池(slotIndex=3)| 上限改 | **改 `numbers.yaml demo_max_characters: 3 → 4` + 红线 test + masters.yaml 注释 + UI battle squad 上限**|
| I2 | active 3 不变,新弟子进 inactive 池(character_panel 可切换出场)| 上限不变 | 0 红线 |
| **I3** | 纯仪式收徒(无新 character,只触发 codex/event/UI 提示)| 上限不变 | 0 红线 |

**推荐 I2**:active 上限不动 → 红线 test 不破 + 用户可在 character_panel 操作切换出场弟子;新弟子作为「储备」存在,符合 GDD §7.1 「Demo 简化:祖师 + 大弟子 + 二弟子 3 个角色」精神(本批 active 仍 3,扩 inactive 池);1.0 后续可升级 active 上限。

---

## §3 三方案对比

### 方案 1 · 完整扩容收徒(T1 + N1 + I1)

**改动范围**:
1. 新 `data/recruit_candidates.yaml`(2-3 NPC 候选)
2. 新 `lib/features/recruitment/`(domain/application/presentation)+ `RecruitmentService` + `RecruitmentDialog`
3. 改 `numbers.yaml demo_max_characters: 3 → 4`(red line)
4. 改 `masters.yaml` 注释 + 红线 test 期望值
5. 接 tutorial step 6 hook 触发 dialog
6. dialog 提交 → 新 Character 入 active 池 slotIndex=3
7. SaveData.activeCharacterIds 加 ID
8. `LineagePanelScreen` 适配 4 弟子显示
9. `character_panel_screen._LineageDisciplesRow` 适配
10. battle squad 配置 UI 适配 active=4
11. widget test +6 (dialog 触发 / 选择 / 取消 / active 入池 / panel 显 4 弟子 / red line not break)

**估时**:**opus xhigh 4-6h**(closeout 估 1-2h 严重低估)
**模型**:opus xhigh(改 active 上限触三系锁死红线 + 跨 9 模块)
**Demo §8.4 红线影响**:`demo_max_characters: 3` 拍板硬上限,**1.0 P1.1 阶段是否允许破?需另起决策**
**风险**:高(active 上限是 fundamental 锚点,P0 至 P1 多处依赖)

### 方案 2 · 纯仪式收徒(T1 + N3 + I3)

**改动范围**:
1. 接 tutorial step 6 hook 触发 dialog
2. 新 `RecruitmentDialog`(显示「您已开派,正式收徒成功」叙述文 + 「确认」按钮)
3. 写入 `GameEvent` 新 type `discipleRecruited`(仪式记录)
4. 触发 codex 「师徒传承」百科 unlock(若未读)
5. 弹窗后,玩家 UI 仍 3 active 不变
6. widget test +3 (dialog 触发 / 确认 / event 写入)

**估时**:**sonnet 1-2h**(closeout 估时锚)
**模型**:sonnet
**Demo §8.4 红线影响**:零
**风险**:低
**gameplay 价值**:中(仪式补全 GDD §7.1 节奏感,但无新弟子)

### 方案 3 · inactive 池收徒(T1 + N1 + I2)

**改动范围**:
1. 新 `data/recruit_candidates.yaml`(2-3 NPC 候选)
2. 新 `lib/features/recruitment/`(domain/application/presentation)+ `RecruitmentService` + `RecruitmentDialog`
3. 接 tutorial step 6 hook 触发 dialog
4. dialog 提交 → 新 Character 入 Isar,**`activeCharacterIds` 不变**,通过 `lineageRole=disciple + isActive=false` 区分(扩 Character.isActive 字段?或沿 active 列表 outside 即 inactive)
5. 玩家可在 `character_panel` Tab 看到 3 active + N inactive 弟子,**点击切换** active(swap 2 弟子之一)
6. `LineagePanelScreen` 适配显示 inactive 弟子段
7. widget test +5 (dialog 触发 / 选择 / 入 inactive 池 / character_panel 显 / active swap)
8. `numbers.yaml demo_max_characters: 3` 不动(本批仍 active 上限 3)

**估时**:**opus xhigh 3-4h**(中间路径)
**模型**:opus xhigh(跨模块 + character lifecycle 改 + UI 适配)
**Demo §8.4 红线影响**:零(active 上限不动)
**风险**:中(active/inactive 区分需明确 — Character.isActive 字段加 vs activeCharacterIds 列表 outside 判定;后者 race-free 但 UI 切换语义复杂)
**gameplay 价值**:高(收徒有实感 + 玩家可后续切换 + 1.0 后续扩 active 上限时无回退)

---

## §4 推荐路径

### §4.1 三方案排序

| 方案 | 估时 | 模型 | 红线影响 | gameplay 价值 | 推荐度 |
|---|---|---|---|---|---|
| 1 完整扩容 | 4-6h | opus xhigh | **改 demo_max_characters** | 满 | ⭐⭐(过度) |
| 2 纯仪式 | 1-2h | sonnet | 零 | 弱 | ⭐⭐⭐ |
| **3 inactive 池**(推荐)| 3-4h | opus xhigh | 零 | 高 | ⭐⭐⭐⭐ |

### §4.2 推荐方案 3 理由

1. **不破红线**:`demo_max_characters: 3` 不动 → 红线 test 0 改动 → 与 GDD §7.1 「Demo 简化:3 角色」精神一致(本 P1.1 阶段是 1.0 路线图,但 demo_max 是 Demo 内容量锚点,不应在 P1.1 首项就破)
2. **gameplay 实感**:玩家收到新弟子 + 可在 character_panel 切换 active,比纯仪式有反馈
3. **可扩展**:1.0 后续若决定扩 active 上限(P2/P3 阶段),已有 inactive 池基础,直接升级即可
4. **复用 tutorial step 6 hook**:trigger 接 hook 0 改 + 跨模块小

### §4.3 方案 3 4 个待拍板设计细节

D1. **Character active/inactive 区分**:
- D1.a `Character.isActive` bool 新字段(schema bump + Isar migration)
- D1.b 沿 `SaveData.activeCharacterIds` 列表 outside 即 inactive(无 schema bump)
**推荐 D1.b**(无 schema bump,race-free)

D2. **recruit_candidates.yaml 候选 NPC 数量**:
- D2.a 2 NPC(精简)
- D2.b 3 NPC(完整,玩家可在 3 中选 1)
- D2.c 5 NPC(更多选择)
**推荐 D2.b**(3 NPC = 1 NPC 流派 1 NPC 装备倾向 1 NPC 平衡型,提供 build 实感)

D3. **拒绝收徒行为**:
- D3.a 一次性 only(拒绝即永久关闭)
- D3.b 拒绝后下次主角境界突破(到绝顶时)再次弹
- D3.c 拒绝后 cooldown 30 天再弹
**推荐 D3.a**(一次性 = 不需 cooldown 字段 + 仪式感强;后续可在 1.0 进阶时扩 cooldown)

D4. **弹窗 UI 显示要素**:
- D4.a 仅 NPC name + 4 属性 + 一句简介(精简)
- D4.b NPC name + 4 属性 + portrait + 起手心法/装备 chips + 一段 lore(完整)
**推荐 D4.b**(完整显示让玩家有「拜师选择」实感,沿 character_panel 展示体例)

---

## §5 工作量拆分(方案 3 推荐)

| Step | 内容 | 时长 | 模型 |
|---|---|---|---|
| 1 | 新 `data/recruit_candidates.yaml`(3 NPC,name/portrait/4 属性/起手心法/装备/简介 lore)| 30 min | opus xhigh |
| 2 | 新 `RecruitDef` def + `RecruitLoader`(yaml fromYaml)| 20 min | sonnet |
| 3 | 新 `lib/features/recruitment/domain/` + `application/recruitment_service.dart`(triggerRecruitment / acceptRecruitment / declineRecruitment)| 45 min | opus xhigh |
| 4 | 接 tutorial step 6 hook(在 `tutorial_service.dart:84` `advanceToStepSix` 后调 recruitment trigger,gate by `SaveData.recruitmentOffered: false`)| 20 min | opus xhigh |
| 5 | SaveData 加 `recruitmentOffered: bool` + `recruitedDiscipleIds: List<int>` 字段(schema bump + Isar regen)| 30 min | opus xhigh |
| 6 | 新 `RecruitmentDialog` widget(显 3 候选 NPC + 选择 + 拒绝)+ navigator 接入 | 45 min | opus xhigh |
| 7 | `LineagePanelScreen` 适配 inactive 弟子显示(已 active 3 段 + 已收 inactive N 段 + 切换按钮)| 30 min | opus xhigh |
| 8 | widget test +5(dialog 触发 / 选择 / 拒绝 / inactive 入池 / panel 显)| 30 min | opus xhigh |
| 9 | analyze + 全测 + closeout doc | 20 min | sonnet |
| **合计** | | **~4h opus xhigh + 30min sonnet** | |

---

## §6 风险与回退

### §6.1 主要风险

1. **`SaveData` schema bump**:加 `recruitmentOffered` + `recruitedDiscipleIds` 字段需 Isar saveVersion 0.9.x → 0.10.0(saveDataMigrations 表加迁移记录)
2. **tutorial step 6 与 recruitment trigger 顺序**:tutorial 在主角突破到一流后推 step 6,recruitment 也接同一 hook → 谁先弹?**推荐 tutorial step 6 弹收徒提示 banner → 玩家点 banner 触发 recruitment dialog**(两段流程,不抢夺 UI focus)
3. **inactive 弟子的属性 progression**:active 弟子打挂机会涨修炼度/经验,**inactive 弟子是否同步?**(GDD §7.3 闭关地图体例:挂机产 retreat outputs 给 active 弟子;inactive 怎么算?)→ **本批先锁 inactive 不挂机不产出**,1.0 后续扩

### §6.2 回退路径

若方案 3 实装中遇红线破坏(schema bump 失败 / tutorial step 6 抢 UI focus 不可调和)→ 降级方案 2(纯仪式)收口,保持 P1.1 候选 1 推进不停。

---

## §7 与候选 2/3/4 的协同

| 协同关注点 | 候选 1 → 候选 N |
|---|---|
| 候选 2 E.5 founder_ancestor_buff | 候选 1 收徒后,sect_wide_buff 作用域 = `lineageRole ∈ {founder, disciple, grandDisciple}` 全 active + inactive,候选 1 落 inactive 池为候选 2 buff 计算提供数据 |
| 候选 3 A3 共鸣度满级体验 | 候选 1 收徒新弟子若装备 isLineageHeritage → 共鸣度 retention 0.7 启动,候选 3 关注的是 joint_skill 表现层不直接受影响 |
| 候选 4 A4 开锋 3 槽 build | 候选 1 弟子 starting 装备 enhanceLevel < 10 → 不直接触发开锋,但弟子上场后 forge 行为同 founder |

**结论**:候选 1-4 独立性强 + 候选 1 为候选 2 提供数据基础,**串行推进顺序 1 → 2 → 3 → 4 合理**。

---

## §8 closeout

- audit 维度 A schema 已落 70%(基础)+ 维度 B caller hook 已建(tutorial step 6 + victory)+ 维度 C 邻近目录 character_panel 已建 + 维度 D UI 收徒 dialog 未建
- 3 方案对比 + 推荐方案 3(inactive 池)+ 4 个设计决策点(D1-D4)待拍板
- 估时:opus xhigh ~4h(对齐 closeout 1-3h sonnet 上限 + 0.5h buffer)
- 与候选 2-4 独立性强,可串行推进
- **本 audit 不动代码 + 不动 numbers.yaml + 不动 PROGRESS**,等用户拍板 D1-D4 后起实装 spec

### §8.1 待拍板项汇总

| # | 决策点 | 推荐 | 备选 |
|---|---|---|---|
| M | **方案选择**(1 完整扩容 / 2 纯仪式 / **3 inactive 池**)| 方案 3 | 1, 2 |
| D1 | active/inactive 区分机制 | **D1.b** `activeCharacterIds` 列表 outside | D1.a `Character.isActive` 新字段 |
| D2 | recruit_candidates 数量 | **D2.b** 3 NPC | D2.a 2 / D2.c 5 |
| D3 | 拒绝收徒行为 | **D3.a** 一次性 only | D3.b 突破时再弹 / D3.c cooldown |
| D4 | 弹窗 UI 显示要素 | **D4.b** 完整(name+属性+portrait+心法装备+lore)| D4.a 精简 |

**用户拍板后**:起实装 spec `p1_1_a1_recruitment_spec_2026-05-XX.md`,Step 1-9 推进实装。

---

**audit 文档结束。Phase 0 四维 grep 完整产出,3 方案对比 + 推荐路径 + 5 决策点待拍板。下一步等用户决策方案 M + D1-D4。**
